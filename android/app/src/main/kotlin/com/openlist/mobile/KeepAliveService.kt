package com.openlist.mobile

import android.app.AlarmManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.SystemClock
import android.util.Log
import com.openlist.mobile.config.AppConfig
import kotlinx.coroutines.*

/**
 * 保活服务 - 运行在独立进程中，用于监控主服务状态并进行保活
 */
class KeepAliveService : Service() {
    companion object {
        private const val TAG = "KeepAliveService"
        private const val KEEP_ALIVE_INTERVAL = 30 * 1000L // 30秒检查一次
        private const val ALARM_ACTION = "com.openlist.mobile.KEEP_ALIVE_ALARM"
    }

    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private var alarmManager: AlarmManager? = null
    private var keepAlivePendingIntent: PendingIntent? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "KeepAliveService created")
        
        alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        setupKeepAliveAlarm()
        startKeepAliveMonitoring()
        
        // 启动进程守护
        com.openlist.mobile.utils.ProcessGuardian.startGuarding(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "KeepAliveService started")
        
        when (intent?.action) {
            ALARM_ACTION -> {
                // 定时器触发，检查主服务状态
                checkAndRestartMainService()
                // 重新设置下一次定时器
                setupKeepAliveAlarm()
            }
            else -> {
                // 正常启动
                setupKeepAliveAlarm()
            }
        }
        
        // 返回 START_STICKY 确保服务被杀死后会重启
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "KeepAliveService destroyed")
        
        // 停止进程守护
        com.openlist.mobile.utils.ProcessGuardian.stopGuarding()
        
        // 取消定时器
        val pendingIntent = keepAlivePendingIntent
        if (pendingIntent != null) {
            alarmManager?.cancel(pendingIntent)
        }
        
        // 取消协程
        serviceScope.cancel()
        
        // 尝试重启自己
        restartKeepAliveService()
    }

    /**
     * 设置保活定时器
     */
    private fun setupKeepAliveAlarm() {
        try {
            val intent = Intent(this, KeepAliveReceiver::class.java).apply {
                action = ALARM_ACTION
            }
            
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            
            val pendingIntent = PendingIntent.getBroadcast(this, 0, intent, flags)
            keepAlivePendingIntent = pendingIntent
            
            val triggerTime = SystemClock.elapsedRealtime() + KEEP_ALIVE_INTERVAL
            
            // 使用精确定时器确保及时触发
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager?.setExactAndAllowWhileIdle(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP,
                    triggerTime,
                    pendingIntent
                )
            } else {
                alarmManager?.setExact(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP,
                    triggerTime,
                    pendingIntent
                )
            }
            
            Log.d(TAG, "Keep alive alarm set for ${KEEP_ALIVE_INTERVAL}ms")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to setup keep alive alarm", e)
        }
    }

    /**
     * 启动保活监控
     */
    private fun startKeepAliveMonitoring() {
        serviceScope.launch {
            while (isActive) {
                try {
                    checkAndRestartMainService()
                    delay(KEEP_ALIVE_INTERVAL)
                } catch (e: Exception) {
                    Log.e(TAG, "Error in keep alive monitoring", e)
                    delay(5000) // 出错时等待5秒再重试
                }
            }
        }
    }

    /**
     * 检查并重启主服务
     */
    private fun checkAndRestartMainService() {
        try {
            // 检查是否被用户手动停止
            if (AppConfig.isManuallyStoppedByUser) {
                Log.d(TAG, "Service was manually stopped by user, skipping restart")
                return
            }
            
            // 检查是否启用了开机启动（保活功能）
            if (!AppConfig.isStartAtBootEnabled) {
                Log.d(TAG, "Auto start disabled, skipping service check")
                return
            }
            
            if (!isMainServiceRunning()) {
                Log.w(TAG, "Main service not running, attempting to restart")
                startMainService()
            } else {
                Log.d(TAG, "Main service is running normally")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking main service status", e)
        }
    }

    /**
     * 检查主服务是否运行
     */
    private fun isMainServiceRunning(): Boolean {
        return try {
            // 通过静态变量检查服务状态
            OpenListService.isRunning
        } catch (e: Exception) {
            Log.e(TAG, "Error checking service status", e)
            false
        }
    }

    /**
     * 启动主服务
     */
    private fun startMainService() {
        try {
            val intent = Intent(this, OpenListService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            Log.d(TAG, "Main service start command sent")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start main service", e)
        }
    }

    /**
     * 重启保活服务自己
     */
    private fun restartKeepAliveService() {
        try {
            // 检查是否被用户手动停止
            if (AppConfig.isManuallyStoppedByUser) {
                Log.d(TAG, "Service was manually stopped by user, skipping keep alive restart")
                return
            }
            
            // 检查是否启用了开机启动（保活功能）
            if (!AppConfig.isStartAtBootEnabled) {
                Log.d(TAG, "Auto start disabled, skipping keep alive restart")
                return
            }
            
            val intent = Intent(this, KeepAliveService::class.java)
            startService(intent)
            Log.d(TAG, "Keep alive service restart command sent")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to restart keep alive service", e)
        }
    }
}