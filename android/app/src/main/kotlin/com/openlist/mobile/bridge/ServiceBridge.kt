package com.openlist.mobile.bridge

import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.openlist.mobile.OpenListService
import com.openlist.mobile.config.AppConfig
import com.openlist.mobile.utils.BatteryOptimizationUtils
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import openlistlib.Openlistlib

/**
 * 服务桥接类 - 连接Flutter和Android服务
 */
class ServiceBridge(private val context: Context, private val channel: MethodChannel) : MethodCallHandler {
    companion object {
        private const val TAG = "ServiceBridge"
        private const val CHANNEL_NAME = "com.openlist.mobile/service"
    }

    init {
        channel.setMethodCallHandler(this)
        Log.d(TAG, "ServiceBridge initialized")
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "startService" -> {
                    val success = startOpenListService()
                    result.success(success)
                }
                
                "stopService" -> {
                    val success = stopOpenListService()
                    result.success(success)
                }
                
                "isServiceRunning" -> {
                    val isRunning = isOpenListServiceRunning()
                    result.success(isRunning)
                }
                
                "isBatteryOptimizationIgnored" -> {
                    val isIgnored = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        BatteryOptimizationUtils.isIgnoringBatteryOptimizations(context)
                    } else {
                        true
                    }
                    result.success(isIgnored)
                }
                
                "requestIgnoreBatteryOptimization" -> {
                    val success = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        BatteryOptimizationUtils.requestIgnoreBatteryOptimizations(context)
                    } else {
                        true
                    }
                    result.success(success)
                }
                
                "openBatteryOptimizationSettings" -> {
                    val success = BatteryOptimizationUtils.openBatteryOptimizationSettings(context)
                    result.success(success)
                }
                
                "openAutoStartSettings" -> {
                    val success = BatteryOptimizationUtils.openAutoStartSettings(context)
                    result.success(success)
                }
                
                "getServiceAddress" -> {
                    val address = getServiceAddress()
                    result.success(address)
                }
                
                else -> {
                    Log.w(TAG, "Unknown method: ${call.method}")
                    result.notImplemented()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling method call: ${call.method}", e)
            result.error("ERROR", e.message, e.toString())
        }
    }

    /**
     * 启动OpenList服务
     */
    private fun startOpenListService(): Boolean {
        return try {
            // 清除手动停止标志，表示用户手动启动了服务
            AppConfig.isManuallyStoppedByUser = false
            
            val intent = Intent(context, OpenListService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
            
            Log.d(TAG, "OpenList service start command sent, manual stop flag cleared")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start OpenList service", e)
            false
        }
    }

    /**
     * 停止OpenList服务
     */
    private fun stopOpenListService(): Boolean {
        return try {
            // 设置手动停止标志，阻止保活机制重启服务
            AppConfig.isManuallyStoppedByUser = true
            
            // 首先尝试通过服务实例直接停止OpenList
            val serviceInstance = OpenListService.serviceInstance
            if (serviceInstance != null && OpenListService.isRunning) {
                Log.d(TAG, "Calling service stopOpenListService method directly")
                // 直接调用服务的停止方法
                serviceInstance.stopOpenListService()
            } else {
                Log.w(TAG, "Service instance not available or not running, using stopService")
                // 如果服务实例不可用，直接停止服务
                val intent = Intent(context, OpenListService::class.java)
                context.stopService(intent)
            }
            
            Log.d(TAG, "OpenList service stop command sent, manual stop flag set")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop OpenList service", e)
            false
        }
    }

    /**
     * 检查OpenList服务是否运行
     */
    private fun isOpenListServiceRunning(): Boolean {
        return try {
            OpenListService.isRunning
        } catch (e: Exception) {
            Log.e(TAG, "Failed to check service status", e)
            false
        }
    }

    /**
     * 获取服务地址
     */
    private fun getServiceAddress(): String {
        return try {
            if (OpenListService.isRunning) {
                Openlistlib.getOutboundIPString()
            } else {
                ""
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get service address", e)
            ""
        }
    }

    /**
     * 通知Flutter服务状态变化
     */
    fun notifyServiceStatusChanged(isRunning: Boolean) {
        try {
            val arguments = mapOf("isRunning" to isRunning)
            channel.invokeMethod("onServiceStatusChanged", arguments)
            Log.d(TAG, "Service status change notified: $isRunning")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to notify service status change", e)
        }
    }
}