package com.openlist.mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.openlist.mobile.config.AppConfig

/**
 * 保活广播接收器 - 监听系统事件并确保服务保活
 */
class KeepAliveReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "KeepAliveReceiver"
        private const val KEEP_ALIVE_ACTION = "com.openlist.mobile.KEEP_ALIVE"
        private const val ALARM_ACTION = "com.openlist.mobile.KEEP_ALIVE_ALARM"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d(TAG, "Received broadcast: $action")

        try {
            when (action) {
                // 屏幕开启
                Intent.ACTION_SCREEN_ON -> {
                    Log.d(TAG, "Screen turned on")
                    ensureServicesRunning(context)
                }
                
                // 屏幕关闭
                Intent.ACTION_SCREEN_OFF -> {
                    Log.d(TAG, "Screen turned off")
                    ensureServicesRunning(context)
                }
                
                // 用户解锁
                Intent.ACTION_USER_PRESENT -> {
                    Log.d(TAG, "User present")
                    ensureServicesRunning(context)
                }
                
                // 网络连接变化
                "android.net.conn.CONNECTIVITY_CHANGE" -> {
                    Log.d(TAG, "Network connectivity changed")
                    ensureServicesRunning(context)
                }
                
                // 包重启
                Intent.ACTION_PACKAGE_RESTARTED -> {
                    Log.d(TAG, "Package restarted")
                    ensureServicesRunning(context)
                }
                
                // 自定义保活动作
                KEEP_ALIVE_ACTION, ALARM_ACTION -> {
                    Log.d(TAG, "Keep alive action triggered")
                    ensureServicesRunning(context)
                }
                
                else -> {
                    Log.d(TAG, "Unknown action: $action")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling broadcast", e)
        }
    }

    /**
     * 确保服务正在运行
     */
    private fun ensureServicesRunning(context: Context) {
        try {
            // 检查是否被用户手动停止
            if (AppConfig.isManuallyStoppedByUser) {
                Log.d(TAG, "Service was manually stopped by user, skipping service start")
                return
            }
            
            // 检查是否启用了开机启动
            if (!AppConfig.isStartAtBootEnabled) {
                Log.d(TAG, "Auto start is disabled, skipping service start")
                return
            }

            // 启动主服务
            startMainService(context)
            
            // 启动保活服务
            startKeepAliveService(context)
            
            Log.d(TAG, "Services start commands sent")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to ensure services running", e)
        }
    }

    /**
     * 启动主服务
     */
    private fun startMainService(context: Context) {
        try {
            val intent = Intent(context, OpenListService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
            Log.d(TAG, "Main service start command sent")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start main service", e)
        }
    }

    /**
     * 启动保活服务
     */
    private fun startKeepAliveService(context: Context) {
        try {
            val intent = Intent(context, KeepAliveService::class.java)
            context.startService(intent)
            Log.d(TAG, "Keep alive service start command sent")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start keep alive service", e)
        }
    }
}