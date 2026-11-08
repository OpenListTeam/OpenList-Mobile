package com.openlist.mobile

import android.app.Application
import android.util.Log

val app by lazy { App.app }

/**
 * Shared by the UI process and the `:server` process. The Go core is loaded
 * lazily by [OpenListService] only, so no core initialization happens here.
 */
class App : Application() {
    companion object {
        private const val TAG = "App"
        lateinit var app: Application
    }

    override fun onCreate() {
        super.onCreate()
        app = this

        // Capture the previous handler first; chaining to itself would recurse.
        val defaultHandler = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            Log.e(TAG, "Uncaught exception in thread ${thread.name}", throwable)
            if (throwable is UnsatisfiedLinkError ||
                throwable.message?.contains("JNI") == true ||
                throwable.message?.contains("native") == true
            ) {
                Log.e(TAG, "Native/JNI related crash detected")
            }
            defaultHandler?.uncaughtException(thread, throwable)
        }
    }
}
