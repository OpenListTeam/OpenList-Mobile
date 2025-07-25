package com.openlist.mobile.bridge

import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.openlist.mobile.OpenListService
import com.openlist.mobile.BuildConfig
import com.openlist.mobile.R
import com.openlist.mobile.SwitchServerActivity
import com.openlist.mobile.config.AppConfig
import com.openlist.mobile.model.openlist.OpenList
import com.openlist.mobile.utils.MyTools
import com.openlist.mobile.utils.ToastUtils.longToast
import com.openlist.mobile.utils.ToastUtils.toast
import com.openlist.pigeon.GeneratedApi

class AndroidBridge(private val context: Context) : GeneratedApi.Android {
    companion object {
        private const val TAG = "AndroidBridge"
    }

    override fun addShortcut() {
        MyTools.addShortcut(
            context,
            context.getString(R.string.app_switch),
            "openlist_mobile_switch",
            R.drawable.openlist_switch,
            Intent(context, SwitchServerActivity::class.java)
        )
    }

    override fun startService() {
        // 清除手动停止标志，表示用户手动启动了服务
        AppConfig.isManuallyStoppedByUser = false
        Log.d(TAG, "Starting service via AndroidBridge, manual stop flag cleared")
        context.startService(Intent(context, OpenListService::class.java))
    }

    override fun setAdminPwd(pwd: String) {
        OpenList.setAdminPassword(pwd)
    }

    override fun getOpenListHttpPort(): Long {
        return OpenList.getHttpPort().toLong()
    }

    override fun isRunning() = OpenListService.isRunning


    override fun getOpenListVersion() = BuildConfig.OPENLIST_VERSION
}