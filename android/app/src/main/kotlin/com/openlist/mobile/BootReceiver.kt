package com.openlist.mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.openlist.mobile.config.AppConfig

/**
 * 开机启动接收器 - 处理开机启动和包更新事件
 */
class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d(TAG, "Received broadcast: $action")

        try {
            when (action) {
                Intent.ACTION_BOOT_COMPLETED,
                "android.intent.action.QUICKBOOT_POWERON",
                "com.htc.intent.action.QUICKBOOT_POWERON" -> {
                    Log.d(TAG, "Boot completed")
                    handleBootCompleted(context)
                }
                
                Intent.ACTION_MY_PACKAGE_REPLACED,
                Intent.ACTION_PACKAGE_REPLACED -> {
                    Log.d(TAG, "Package replaced")
                    handlePackageReplaced(context, intent)
                }
                
                else -> {
                    Log.d(TAG, "Unknown action: $action")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling boot broadcast", e)
        }
    }

    /**
     * 处理开机完成事件
     */
    private fun handleBootCompleted(context: Context) {
        if (!AppConfig.isStartAtBootEnabled) {
            Log.d(TAG, "Auto start is disabled")
            return
        }

        // 开机时清除手动停止标志，因为设备重启了
        AppConfig.isManuallyStoppedByUser = false
        Log.d(TAG, "Manual stop flag cleared on boot")

        Log.d(TAG, "Starting services after boot")
        startServices(context)
    }

    /**
     * 处理包更新事件
     */
    private fun handlePackageReplaced(context: Context, intent: Intent) {
        val packageName = intent.dataString
        if (packageName?.contains(context.packageName) == true) {
            Log.d(TAG, "Our package was replaced, restarting services")
            if (AppConfig.isStartAtBootEnabled) {
                startServices(context)
            }
        }
    }

    /**
     * 启动所有必要的服务
     */
    private fun startServices(context: Context) {
        try {
            // 启动主服务
            val mainServiceIntent = Intent(context, OpenListService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(mainServiceIntent)
            } else {
                context.startService(mainServiceIntent)
            }
            Log.d(TAG, "Main service start command sent")

        } catch (e: Exception) {
            Log.e(TAG, "Failed to start services", e)
        }
    }
}
