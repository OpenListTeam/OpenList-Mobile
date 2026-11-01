package com.openlist.mobile.bridge

import android.content.Context
import android.content.Intent
import android.util.Log
import com.openlist.mobile.BuildConfig
import com.openlist.mobile.OpenListService
import com.openlist.mobile.R
import com.openlist.mobile.SwitchServerActivity
import com.openlist.mobile.model.openlist.OpenListConfigManager
import com.openlist.mobile.server.ServerClient
import com.openlist.mobile.utils.MyTools
import com.openlist.pigeon.GeneratedApi
import com.openlist.mobile.server.ServerProtocol as P

/** Legacy Android API kept for existing Dart callers; runs in the UI process. */
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
        try {
            OpenListService.sendAction(context, OpenListService.ACTION_START)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start service", e)
        }
    }

    // Reads config.json directly so the UI process never loads the Go core.
    override fun getOpenListHttpPort(): Long =
        (OpenListConfigManager.configOrNull()?.scheme?.httpPort ?: 5244).toLong()

    override fun isRunning() = ServerClient.lastStatus.getBoolean(P.KEY_RUNNING)

    override fun getOpenListVersion() = BuildConfig.OPENLIST_VERSION
}
