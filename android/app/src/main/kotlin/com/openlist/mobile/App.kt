package com.openlist.mobile

import android.app.Application
import com.openlist.mobile.utils.ToastUtils.longToast
import io.flutter.app.FlutterApplication

val app by lazy { App.app }

class App : FlutterApplication() {
    companion object {
        lateinit var app: Application
    }


    override fun onCreate() {
        super.onCreate()

        app = this
        
        // 设置全局异常处理器来捕获未处理的异常
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            android.util.Log.e("App", "Uncaught exception in thread ${thread.name}", throwable)
            
            // 如果是 JNI 相关的错误，记录详细信息
            if (throwable.message?.contains("JNI") == true || 
                throwable.message?.contains("native") == true ||
                throwable is UnsatisfiedLinkError) {
                android.util.Log.e("App", "Native/JNI related crash detected")
            }
            
            // 尝试重启服务（保活机制）
            try {
                // 检查是否被用户手动停止
                if (com.openlist.mobile.config.AppConfig.isManuallyStoppedByUser) {
                    android.util.Log.d("App", "Service was manually stopped by user, skipping restart after crash")
                } else if (com.openlist.mobile.config.AppConfig.isStartAtBootEnabled) {
                    val intent = android.content.Intent(this, OpenListService::class.java)
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    android.util.Log.d("App", "Service restart attempted after crash")
                }
            } catch (e: Exception) {
                android.util.Log.e("App", "Failed to restart service after crash", e)
            }
            
            // 调用默认的异常处理器
            val defaultHandler = Thread.getDefaultUncaughtExceptionHandler()
            defaultHandler?.uncaughtException(thread, throwable)
        }
        
        // 初始化保活机制
        initKeepAlive()
    }

    /**
     * 初始化保活机制
     */
    private fun initKeepAlive() {
        try {
            // 初始化WorkManager任务
            com.openlist.mobile.utils.WorkManagerHelper.initialize(this)
            
            // 检查是否被用户手动停止
            if (com.openlist.mobile.config.AppConfig.isManuallyStoppedByUser) {
                android.util.Log.d("App", "Service was manually stopped by user, skipping keep alive initialization")
                return
            }
            
            // 如果启用了开机启动，则启动保活服务
            if (com.openlist.mobile.config.AppConfig.isStartAtBootEnabled) {
                val keepAliveIntent = android.content.Intent(this, KeepAliveService::class.java)
                startService(keepAliveIntent)
                android.util.Log.d("App", "Keep alive service started")
            }
        } catch (e: Exception) {
            android.util.Log.e("App", "Failed to initialize keep alive", e)
        }
    }
}