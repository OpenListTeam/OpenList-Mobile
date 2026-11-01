package com.openlist.mobile

import android.os.Bundle
import android.util.Log
import com.openlist.mobile.bridge.AndroidBridge
import com.openlist.mobile.bridge.AppConfigBridge
import com.openlist.mobile.bridge.BackgroundBridge
import com.openlist.mobile.bridge.CommonBridge
import com.openlist.mobile.bridge.ServerBridge
import com.openlist.mobile.model.ShortCuts
import com.openlist.mobile.server.ServerClient
import com.openlist.pigeon.GeneratedApi
import com.openlist.pigeon.GeneratedApi.VoidResult
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant
import com.openlist.mobile.server.ServerProtocol as P

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
    }

    private var mEvent: GeneratedApi.Event? = null

    private val ignoreResult = object : VoidResult {
        override fun success() {}
        override fun error(error: Throwable) {}
    }

    // Forwards server process events to Dart; callbacks arrive on the main thread.
    private val serverListener = object : ServerClient.Listener {
        override fun onStatus(status: Bundle) {
            val event = mEvent ?: return
            event.onServiceStatusChanged(status.getBoolean(P.KEY_RUNNING), ignoreResult)
            event.onServerStatus(ServerBridge.toServerStatus(status), ignoreResult)
        }

        override fun onLog(level: Int, time: String, message: String) {
            mEvent?.onServerLog(level.toLong(), time, message, ignoreResult)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        ShortCuts.buildShortCuts(this)
        GeneratedPluginRegistrant.registerWith(this.flutterEngine!!)

        val binaryMessage = flutterEngine!!.dartExecutor.binaryMessenger
        GeneratedApi.AppConfig.setUp(binaryMessage, AppConfigBridge)
        GeneratedApi.Android.setUp(binaryMessage, AndroidBridge(this))
        GeneratedApi.NativeCommon.setUp(binaryMessage, CommonBridge(this))
        GeneratedApi.ServerApi.setUp(binaryMessage, ServerBridge(applicationContext))
        GeneratedApi.BackgroundApi.setUp(binaryMessage, BackgroundBridge(this))
        mEvent = GeneratedApi.Event(binaryMessage)

        ServerClient.addListener(serverListener)
        ServerClient.bind(this)
    }

    override fun onStop() {
        super.onStop()
        // Flush SQLite WAL while the UI is hidden; the server keeps running.
        triggerDatabaseSync("onStop")
    }

    override fun onDestroy() {
        triggerDatabaseSync("onDestroy")
        ServerClient.removeListener(serverListener)
        mEvent = null
        // Unbinding does not stop a started server; it only drops the UI link.
        if (isFinishing) ServerClient.unbind()
        super.onDestroy()
    }

    private fun triggerDatabaseSync(reason: String) {
        if (ServerClient.lastStatus.getBoolean(P.KEY_RUNNING)) {
            Log.d(TAG, "Requesting database sync: $reason")
            ServerClient.notify(P.MSG_SYNC_DB)
        }
    }
}
