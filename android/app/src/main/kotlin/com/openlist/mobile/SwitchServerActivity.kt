package com.openlist.mobile

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.Log
import com.openlist.mobile.config.AppConfig
import com.openlist.mobile.utils.ToastUtils.toast

class SwitchServerActivity : Activity() {
    companion object {
        private const val TAG = "SwitchServerActivity"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (OpenListService.isRunning) {
            Log.d(TAG, "Service is running, stopping it")
            // 设置手动停止标志
            AppConfig.isManuallyStoppedByUser = true
            startService(Intent(this, OpenListService::class.java).apply {
                action = OpenListService.ACTION_SHUTDOWN
            })
        } else {
            // 检查是否被手动停止
            if (AppConfig.isManuallyStoppedByUser) {
                Log.d(TAG, "Service was manually stopped, clearing flag and starting")
                // 清除手动停止标志
                AppConfig.isManuallyStoppedByUser = false
            }
            Log.d(TAG, "Starting service")
            startService(Intent(this, OpenListService::class.java))
        }

        finish()
    }
}