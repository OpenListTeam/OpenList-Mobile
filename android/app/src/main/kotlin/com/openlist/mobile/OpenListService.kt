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
        Log.d(TAG, "notifyStatusChanged: isRunning=$isRunning")
        
        LocalBroadcastManager.getInstance(this)
            .sendBroadcast(Intent(ACTION_STATUS_CHANGED))

        // Notify ServiceBridge of status change
        try {
            MainActivity.serviceBridge?.notifyServiceStatusChanged(isRunning)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to notify ServiceBridge", e)
        }

        if (!isRunning) {
            // Stop foreground service and remove notification
            stopForeground(true)
            cancelNotification()
            stopSelf()
        } else {
            // Update notification with current status
            Log.d(TAG, "Updating notification after status change")
            updateNotification()
        }
    }

    @SuppressLint("WakelockTimeout")
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "OpenListService created")

        serviceInstance = this

        // Android 8.0+ must start foreground notification immediately
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            initOrUpdateNotification()
        }

        // Register broadcast receivers
        try {
            LocalBroadcastManager.getInstance(this)
                .registerReceiver(mReceiver, IntentFilter(ACTION_STATUS_CHANGED))
            registerReceiverCompat(mNotificationReceiver, ACTION_SHUTDOWN, ACTION_COPY_ADDRESS)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register receivers", e)
        }

        // Add OpenList listener
        OpenList.addListener(this)

        // Acquire wake lock if enabled
        if (AppConfig.isWakeLockEnabled) {
            try {
                mWakeLock = powerManager.newWakeLock(
                    PowerManager.PARTIAL_WAKE_LOCK,
                    "openlist::service"
                )
                mWakeLock?.acquire()
            } catch (e: Exception) {
                Log.e(TAG, "Failed to acquire wake lock", e)
            }
        }

        Log.d(TAG, "Service onCreate completed")
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
     * Public method: Stop OpenList service manually
     */
    fun stopOpenListService() {
        if (isRunning) {
            Log.d(TAG, "User manually stopping service")
            // Set flag to indicate user manually stopped the service
            AppConfig.isManuallyStoppedByUser = true
            startOrShutdown()
        }
    }

    /**
     * Start or shutdown OpenList service
     */
    private fun startOrShutdown() {
        if (isRunning) {
            Log.d(TAG, "Shutting down OpenList")
            mScope.launch(Dispatchers.IO) {
                try {
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
            Log.d(TAG, "Starting OpenList from user action")
            AppConfig.isManuallyStoppedByUser = false
            toast(getString(R.string.starting))
            startOpenListBackend()
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand called")

        // Check manual stop flag
        if (AppConfig.isManuallyStoppedByUser) {
            Log.d(TAG, "Service was manually stopped by user, not starting")
            stopSelf()
            return START_NOT_STICKY
        }

        // Start OpenList if not running
        if (!isRunning) {
            Log.d(TAG, "Starting OpenList backend")
            startOpenListBackend()
        }

        return START_STICKY
    }

    /**
     * Start OpenList backend service
     */
    private fun startOpenListBackend() {
        if (isRunning) {
            Log.d(TAG, "OpenList already running")
            return
        }
        
        Log.d(TAG, "Initializing and starting OpenList")
        isRunning = true
        
        mScope.launch(Dispatchers.IO) {
            try {
                // Initialize OpenList
                OpenList.init()
                delay(100)
                
                // Start OpenList
                OpenList.startup()
                
                // Clear cached address to force refresh
                mLocalAddress = ""
                
                // Update UI on success
                launch(Dispatchers.Main) {
                    notifyStatusChanged()
                    startDatabaseSyncTask()
                }
                
                Log.d(TAG, "OpenList started successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start OpenList", e)
                isRunning = false
                launch(Dispatchers.Main) {
                    toast("启动失败: ${e.message}")
                    notifyStatusChanged()
                }
            }
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
     * Get local address safely
     */
    private fun localAddress(): String {
        return try {
            if (mLocalAddress.isEmpty()) {
                Log.d(TAG, "Fetching local address...")
                mLocalAddress = Openlistlib.getOutboundIPString()
                Log.d(TAG, "Local address: $mLocalAddress")
            }
            mLocalAddress
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get local address", e)
            "Initializing..."
        }
    }

    /**
     * Initialize or update notification
     */
    @Suppress("DEPRECATION")
    private fun initOrUpdateNotification() {
        try {
            Log.d(TAG, "Creating/updating notification with address: ${localAddress()}")
            
            val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_IMMUTABLE
            } else {
                0
            }

            val pendingIntent = PendingIntent.getActivity(
                this, 0, Intent(this, MainActivity::class.java), pendingIntentFlags
            )

            val shutdownAction = PendingIntent.getBroadcast(
                this, 0, Intent(ACTION_SHUTDOWN), pendingIntentFlags
            )

            val copyAddressPendingIntent = PendingIntent.getBroadcast(
                this, 0, Intent(ACTION_COPY_ADDRESS), pendingIntentFlags
            )

            val builder = Notification.Builder(applicationContext)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val chan = NotificationChannel(
                    NOTIFICATION_CHAN_ID,
                    getString(R.string.openlist_server),
                    NotificationManager.IMPORTANCE_LOW
                )
                chan.lockscreenVisibility = Notification.VISIBILITY_PRIVATE
                chan.setShowBadge(false)
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    chan.setBlockable(false)
                }
                
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.createNotificationChannel(chan)
                
                builder.setChannelId(NOTIFICATION_CHAN_ID)
            }

            val smallIconRes = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                R.drawable.server
            } else {
                R.mipmap.ic_launcher_round
            }

            val notification = builder
                .setContentTitle(getString(R.string.openlist_server_running))
                .setContentText("地址: ${localAddress()}")
                .setSmallIcon(smallIconRes)
                .setContentIntent(pendingIntent)
                .addAction(0, getString(R.string.shutdown), shutdownAction)
                .addAction(0, getString(R.string.copy_address), copyAddressPendingIntent)
                .setOngoing(true)
                .setAutoCancel(false)
                .build()

            notification.flags = notification.flags or 
                Notification.FLAG_NO_CLEAR or
                Notification.FLAG_ONGOING_EVENT

            startForeground(FOREGROUND_ID, notification)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create notification", e)
            // Minimal fallback
            try {
                val minimal = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    Notification.Builder(applicationContext, NOTIFICATION_CHAN_ID)
                } else {
                    Notification.Builder(applicationContext)
                }.setContentTitle("OpenList")
                    .setContentText("Starting...")
                    .setSmallIcon(R.mipmap.ic_launcher_round)
                    .build()
                startForeground(FOREGROUND_ID, minimal)
            } catch (fallbackError: Exception) {
                Log.e(TAG, "Failed to create minimal notification", fallbackError)
            }
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