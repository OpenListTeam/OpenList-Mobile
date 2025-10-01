package com.openlist.mobile

import android.app.Application
import android.util.Log
import com.openlist.mobile.model.openlist.OpenList
import com.openlist.mobile.utils.ToastUtils.longToast
import io.flutter.app.FlutterApplication

val app by lazy { App.app }

class App : FlutterApplication() {
    companion object {
        private const val TAG = "App"
        lateinit var app: Application
    }


    override fun onCreate() {
        super.onCreate()

        app = this
        
        // Early initialization of OpenList to prepare for boot startup
        try {
            Log.d(TAG, "Performing early OpenList initialization")
            OpenList.init()
            Log.d(TAG, "OpenList early initialization completed")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize OpenList early", e)
        }
        
        // Set global exception handler to catch uncaught exceptions
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            Log.e(TAG, "Uncaught exception in thread ${thread.name}", throwable)
            
            // Log detailed info for JNI related errors
            if (throwable.message?.contains("JNI") == true || 
                throwable.message?.contains("native") == true ||
                throwable is UnsatisfiedLinkError) {
                Log.e(TAG, "Native/JNI related crash detected")
            }
            
            // Call default exception handler
            val defaultHandler = Thread.getDefaultUncaughtExceptionHandler()
            defaultHandler?.uncaughtException(thread, throwable)
        }
    }
}