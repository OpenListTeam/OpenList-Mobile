package com.openlist.mobile.bridge

import android.content.Context
import android.content.Intent
import android.os.Build
import com.openlist.mobile.OpenListService
import com.openlist.mobile.BuildConfig
import com.openlist.mobile.R
import com.openlist.mobile.SwitchServerActivity
import com.openlist.mobile.model.openlist.OpenList
import com.openlist.mobile.utils.MyTools
import com.openlist.mobile.utils.ToastUtils.longToast
import com.openlist.mobile.utils.ToastUtils.toast
import com.openlist.pigeon.GeneratedApi

class AndroidBridge(private val context: Context) : GeneratedApi.Android {
    override fun addShortcut() {
        MyTools.addShortcut(
            context,
            context.getString(R.string.app_switch),
            "openlist_flutter_switch",
            R.drawable.openlist_switch,
            Intent(context, SwitchServerActivity::class.java)
        )
    }

    override fun startService() {
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