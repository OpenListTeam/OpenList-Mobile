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
    private var mDbSyncJob: Job? = null

    // Database sync interval in milliseconds (5 minutes)
    private val DB_SYNC_INTERVAL = 5 * 60 * 1000L

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

        // 移除OpenList监听器
        OpenList.removeListener(this)
        
        // Stop database sync task
        stopDatabaseSyncTask()
    }

    override fun onShutdown(type: String) {
        Log.d(TAG, "OpenList shutdown: $type")
        if (!OpenList.isRunning()) {
            isRunning = false
            // Stop database sync task when service shuts down
            stopDatabaseSyncTask()
            notifyStatusChanged()
        }
    }

    /**
     * Start periodic database synchronization task
     */
    private fun startDatabaseSyncTask() {
        stopDatabaseSyncTask() // Stop any existing task first
        
        mDbSyncJob = mScope.launch(Dispatchers.IO) {
            while (isActive && isRunning) {
                try {
                    delay(DB_SYNC_INTERVAL)
                    if (isRunning && OpenList.isRunning()) {
                        Log.d(TAG, "Performing periodic database sync")
                        OpenList.forceDatabaseSync()
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error during periodic database sync", e)
                }
            }
        }
        Log.d(TAG, "Database sync task started")
    }

    /**
     * Stop database synchronization task
     */
    private fun stopDatabaseSyncTask() {
        mDbSyncJob?.cancel()
        mDbSyncJob = null
        Log.d(TAG, "Database sync task stopped")
    }

    /**
     * Force immediate database synchronization
     */
    fun forceImmediateDbSync() {
        mScope.launch(Dispatchers.IO) {
            try {
                if (isRunning && OpenList.isRunning()) {
                    Log.d(TAG, "Performing immediate database sync")
                    OpenList.forceDatabaseSync()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error during immediate database sync", e)
            }
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
                    // Force database sync before shutdown
                    if (OpenList.isRunning()) {
                        Log.d(TAG, "Forcing database sync before shutdown")
                        OpenList.forceDatabaseSync()
                    }
                    
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
                    Log.d(TAG, "Manual starting OpenList...")
                    OpenList.startup()
                    
                    // 启动完成后在主线程中更新状态
                    launch(Dispatchers.Main) {
                        notifyStatusChanged()
                        toast("OpenList 启动成功")
                        // Start periodic database sync after successful startup
                        startDatabaseSyncTask()
                    }
                    Log.d(TAG, "Manual start completed successfully")
                } catch (e: Exception) {
                    Log.e(TAG, "Manual startup error", e)
                    // 启动失败时重置状态
                    isRunning = false
                    launch(Dispatchers.Main) {
                        toast("启动失败: ${e.message}")
                        notifyStatusChanged()
                    }
                } catch (t: Throwable) {
                    Log.e(TAG, "Manual startup fatal error", t)
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

        // 如果OpenList后端未运行，则启动它
        if (!isRunning && !OpenList.isRunning()) {
            Log.d(TAG, "Starting OpenList backend from onStartCommand")
            startOrShutdown()
        }

        // 返回 START_STICKY 确保服务被杀死后会重启（仅保持前台服务）
        return START_STICKY
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