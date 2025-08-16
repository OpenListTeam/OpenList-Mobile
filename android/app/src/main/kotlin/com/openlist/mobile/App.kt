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
            
            // 调用默认的异常处理器
            val defaultHandler = Thread.getDefaultUncaughtExceptionHandler()
            defaultHandler?.uncaughtException(thread, throwable)
        }
    }
}