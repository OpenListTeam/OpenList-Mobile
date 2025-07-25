package com.openlist.mobile

import openlistlib.Openlistlib
import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.openlist.mobile.config.AppConfig
import com.openlist.mobile.model.openlist.OpenList
import com.openlist.mobile.utils.AndroidUtils.registerReceiverCompat
import com.openlist.mobile.utils.ClipboardUtils
import com.openlist.mobile.utils.ToastUtils.toast
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import splitties.systemservices.powerManager

/**
 * OpenList后台服务 - 提供OpenList核心功能并实现保活机制
 */
class OpenListService : Service(), OpenList.Listener {
    companion object {
        const val TAG = "OpenListService"
        const val ACTION_SHUTDOWN =
            "com.openlist.openlistandroid.service.OpenListService.ACTION_SHUTDOWN"

        const val ACTION_COPY_ADDRESS =
            "com.openlist.openlistandroid.service.OpenListService.ACTION_COPY_ADDRESS"

        const val ACTION_STATUS_CHANGED =
            "com.openlist.openlistandroid.service.OpenListService.ACTION_STATUS_CHANGED"

        const val NOTIFICATION_CHAN_ID = "openlist_server"
        const val FOREGROUND_ID = 5224

        @Volatile
        var isRunning: Boolean = false
            private set

        @Volatile
        var serviceInstance: OpenListService? = null
            private set
    }

    private val mScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val mNotificationReceiver = NotificationActionReceiver()
    private val mReceiver = MyReceiver()
    private var mWakeLock: PowerManager.WakeLock? = null
    private var mLocalAddress: String = ""
    private var networkMonitor: com.openlist.mobile.utils.NetworkMonitor? = null

    override fun onBind(p0: Intent?): IBinder? = null

    @Suppress("DEPRECATION")
    private fun notifyStatusChanged() {
        LocalBroadcastManager.getInstance(this)
            .sendBroadcast(Intent(ACTION_STATUS_CHANGED))

        // 通知ServiceBridge状态变化
        try {
            MainActivity.serviceBridge?.notifyServiceStatusChanged(isRunning)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to notify ServiceBridge", e)
        }

        if (!isRunning) {
            // 如果服务停止，则停止前台服务并移除通知
            stopForeground(true)
            // 确保通知被完全移除
            cancelNotification()
            stopSelf()
        } else {
            // 如果服务运行，更新通知
            updateNotification()
        }
    }

    @SuppressLint("WakelockTimeout")
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "OpenListService created")

        serviceInstance = this

        // Android 8.0+ 必须启动前台服务
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            initOrUpdateNotification()
        }

        // 启用唤醒锁保持CPU运行
        if (AppConfig.isWakeLockEnabled) {
            try {
                mWakeLock = powerManager.newWakeLock(
                    PowerManager.PARTIAL_WAKE_LOCK,
                    "openlist::service"
                )
                mWakeLock?.acquire()
                Log.d(TAG, "Wake lock acquired")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to acquire wake lock", e)
            }
        }

        // 注册广播接收器
        try {
            LocalBroadcastManager.getInstance(this)
                .registerReceiver(
                    mReceiver,
                    IntentFilter(ACTION_STATUS_CHANGED)
                )
            registerReceiverCompat(
                mNotificationReceiver,
                ACTION_SHUTDOWN,
                ACTION_COPY_ADDRESS
            )
            Log.d(TAG, "Broadcast receivers registered")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register receivers", e)
        }

        // 添加OpenList监听器
        OpenList.addListener(this)

        // 启动保活服务
        startKeepAliveService()

        // 启动网络监听
        startNetworkMonitoring()

        // 启动心跳检测
        startHeartbeat()
    }

    @Suppress("DEPRECATION")
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "OpenListService destroyed")

        serviceInstance = null

        // 取消所有协程作业
        mScope.coroutineContext[Job]?.cancel()

        // 释放唤醒锁
        try {
            mWakeLock?.release()
            mWakeLock = null
            Log.d(TAG, "Wake lock released")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to release wake lock", e)
        }

        // 停止前台服务并取消通知
        stopForeground(true)
        cancelNotification()

        // 注销广播接收器
        try {
            LocalBroadcastManager.getInstance(this).unregisterReceiver(mReceiver)
            unregisterReceiver(mNotificationReceiver)
            Log.d(TAG, "Broadcast receivers unregistered")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to unregister receivers", e)
        }

        // 停止网络监听
        stopNetworkMonitoring()

        // 移除OpenList监听器
        OpenList.removeListener(this)

        // 尝试重启服务（保活机制）
        if (isRunning && AppConfig.isStartAtBootEnabled && !AppConfig.isManuallyStoppedByUser) {
            restartService()
        }
    }

    override fun onShutdown(type: String) {
        Log.d(TAG, "OpenList shutdown: $type")
        if (!OpenList.isRunning()) {
            isRunning = false
            notifyStatusChanged()
        }
    }

    /**
     * 公共方法：停止OpenList服务
     */
    fun stopOpenListService() {
        if (isRunning) {
            startOrShutdown()
        }
    }

    /**
     * 启动或关闭OpenList服务
     */
    private fun startOrShutdown() {
        if (isRunning) {
            Log.d(TAG, "Shutting down OpenList")
            // 关闭操作在子线程中执行，避免阻塞主线程
            mScope.launch(Dispatchers.IO) {
                try {
                    OpenList.shutdown()
                    isRunning = false
                    launch(Dispatchers.Main) {
                        notifyStatusChanged()
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Shutdown error", e)
                    launch(Dispatchers.Main) {
                        toast("关闭失败: ${e.message}")
                    }
                }
            }
        } else {
            Log.d(TAG, "Starting OpenList")
            toast(getString(R.string.starting))
            isRunning = true
            
            // 在子线程中启动OpenList服务，避免阻塞主线程
            mScope.launch(Dispatchers.IO) {
                try {
                    // 确保在启动前进行初始化
                    OpenList.init()
                    // 添加延迟确保初始化完成
                    delay(100)
                    OpenList.startup()
                    
                    // 启动完成后在主线程中更新状态
                    launch(Dispatchers.Main) {
                        notifyStatusChanged()
                        toast("OpenList 启动成功")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Startup error", e)
                    // 启动失败时重置状态
                    isRunning = false
                    launch(Dispatchers.Main) {
                        toast("启动失败: ${e.message}")
                        notifyStatusChanged()
                    }
                } catch (t: Throwable) {
                    Log.e(TAG, "Startup fatal error", t)
                    // 处理更严重的错误（如 JNI 崩溃）
                    isRunning = false
                    launch(Dispatchers.Main) {
                        toast("启动严重错误: ${t.message}")
                        notifyStatusChanged()
                    }
                }
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand called")
        
        // 如果还没有启动，则启动OpenList
        if (!isRunning) {
            startOrShutdown()
        }

        // 返回 START_STICKY 确保服务被杀死后会重启
        return START_STICKY
    }

    /**
     * 启动保活服务
     */
    private fun startKeepAliveService() {
        try {
            val intent = Intent(this, KeepAliveService::class.java)
            startService(intent)
            Log.d(TAG, "Keep alive service started")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start keep alive service", e)
        }
    }

    /**
     * 启动网络监听
     */
    private fun startNetworkMonitoring() {
        try {
            networkMonitor = com.openlist.mobile.utils.NetworkMonitor(this)
            networkMonitor?.startMonitoring()
            Log.d(TAG, "Network monitoring started")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start network monitoring", e)
        }
    }

    /**
     * 停止网络监听
     */
    private fun stopNetworkMonitoring() {
        try {
            networkMonitor?.stopMonitoring()
            networkMonitor = null
            Log.d(TAG, "Network monitoring stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop network monitoring", e)
        }
    }

    /**
     * 启动心跳检测
     */
    private fun startHeartbeat() {
        mScope.launch {
            while (isActive) {
                try {
                    // 每30秒检查一次服务状态
                    delay(30000)
                    
                    // 检查是否被用户手动停止
                    if (AppConfig.isManuallyStoppedByUser) {
                        Log.d(TAG, "Service was manually stopped by user, skipping heartbeat restart")
                        continue
                    }
                    
                    if (isRunning && !OpenList.isRunning()) {
                        Log.w(TAG, "OpenList stopped unexpectedly, restarting...")
                        // 重新启动OpenList
                        launch(Dispatchers.IO) {
                            try {
                                OpenList.startup()
                            } catch (e: Exception) {
                                Log.e(TAG, "Failed to restart OpenList", e)
                                isRunning = false
                                launch(Dispatchers.Main) {
                                    notifyStatusChanged()
                                }
                            }
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Heartbeat error", e)
                }
            }
        }
    }

    /**
     * 重启服务
     */
    private fun restartService() {
        try {
            val intent = Intent(this, OpenListService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            Log.d(TAG, "Service restart command sent")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to restart service", e)
        }
    }

    inner class MyReceiver : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent) {
            when (intent.action) {
                ACTION_STATUS_CHANGED -> {
                    Log.d(TAG, "Status changed broadcast received")
                }
            }
        }
    }

    /**
     * 获取本地地址
     */
    private fun localAddress(): String {
        return try {
            if (mLocalAddress.isEmpty()) {
                mLocalAddress = Openlistlib.getOutboundIPString()
            }
            mLocalAddress
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get local address", e)
            "Unknown"
        }
    }

    /**
     * 初始化或更新通知
     */
    @Suppress("DEPRECATION")
    private fun initOrUpdateNotification() {
        try {
            // Android 12(S)+ 必须指定PendingIntent.FLAG_IMMUTABLE
            val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
                PendingIntent.FLAG_IMMUTABLE
            else
                0

            // 点击通知跳转到主界面
            val pendingIntent = PendingIntent.getActivity(
                this, 0, Intent(this, MainActivity::class.java),
                pendingIntentFlags
            )

            // 关闭按钮
            val shutdownAction = PendingIntent.getBroadcast(
                this, 0, Intent(ACTION_SHUTDOWN), pendingIntentFlags
            )

            // 复制地址按钮
            val copyAddressPendingIntent = PendingIntent.getBroadcast(
                this, 0, Intent(ACTION_COPY_ADDRESS), pendingIntentFlags
            )

            val smallIconRes: Int
            val builder = Notification.Builder(applicationContext)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // Android 8.0+ 要求必须设置通知信道
                val chan = NotificationChannel(
                    NOTIFICATION_CHAN_ID,
                    getString(R.string.openlist_server),
                    NotificationManager.IMPORTANCE_LOW // 使用低重要性避免打扰用户
                )
                chan.lockscreenVisibility = Notification.VISIBILITY_PRIVATE
                chan.setShowBadge(false) // 不显示角标
                
                // 设置通知渠道为不可清除（常驻通知）
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    chan.setBlockable(false) // Android 10+ 设置为不可屏蔽
                }
                
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.createNotificationChannel(chan)
                
                smallIconRes = when ((0..1).random()) {
                    0 -> R.drawable.server
                    1 -> R.drawable.server2
                    else -> R.drawable.server2
                }

                builder.setChannelId(NOTIFICATION_CHAN_ID)
            } else {
                smallIconRes = R.mipmap.ic_launcher_round
            }

            val notification = builder
                .setContentTitle(getString(R.string.openlist_server_running))
                .setContentText("地址: ${localAddress()}")
                .setSmallIcon(smallIconRes)
                .setContentIntent(pendingIntent)
                .addAction(0, getString(R.string.shutdown), shutdownAction)
                .addAction(0, getString(R.string.copy_address), copyAddressPendingIntent)
                .setOngoing(true) // 设置为持续通知，不能被滑动删除
                .setAutoCancel(false) // 点击后不自动取消
                .build()

            // 设置通知标志，确保通知常驻
            notification.flags = notification.flags or 
                Notification.FLAG_NO_CLEAR or // 不能被清除按钮清除
                Notification.FLAG_ONGOING_EVENT // 标记为持续事���

            startForeground(FOREGROUND_ID, notification)
            Log.d(TAG, "Foreground notification started with persistent flags")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create notification", e)
        }
    }

    /**
     * 更新通知
     */
    private fun updateNotification() {
        initOrUpdateNotification()
    }

    /**
     * 取消通知
     */
    private fun cancelNotification() {
        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.cancel(FOREGROUND_ID)
            Log.d(TAG, "Notification cancelled")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to cancel notification", e)
        }
    }

    inner class NotificationActionReceiver : BroadcastReceiver() {
        override fun onReceive(ctx: Context?, intent: Intent?) {
            when (intent?.action) {
                ACTION_SHUTDOWN -> {
                    Log.d(TAG, "Shutdown action received from notification")
                    startOrShutdown()
                }

                ACTION_COPY_ADDRESS -> {
                    Log.d(TAG, "Copy address action received from notification")
                    ClipboardUtils.copyText("OpenList", localAddress())
                    toast(R.string.address_copied)
                }
            }
        }
    }
}