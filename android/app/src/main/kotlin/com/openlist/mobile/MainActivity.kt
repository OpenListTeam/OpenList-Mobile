package com.openlist.mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Configuration
import android.os.Bundle
import android.util.Log
import android.view.WindowManager
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.openlist.mobile.bridge.AndroidBridge
import com.openlist.mobile.bridge.AppConfigBridge
import com.openlist.mobile.bridge.CommonBridge
import com.openlist.mobile.bridge.ServiceBridge
import com.openlist.mobile.model.ShortCuts
import com.openlist.mobile.model.openlist.Logger
import com.openlist.pigeon.GeneratedApi
import com.openlist.pigeon.GeneratedApi.VoidResult
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
        
        // 静态引用，供其他组件访问
        @Volatile
        var serviceBridge: ServiceBridge? = null
            private set
    }

    private val receiver by lazy { MyReceiver() }
    private var mEvent: GeneratedApi.Event? = null

    @OptIn(DelicateCoroutinesApi::class)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 处理小窗模式和边缘到边缘显示
        setupWindowFlags()

        ShortCuts.buildShortCuts(this)
        LocalBroadcastManager.getInstance(this)
            .registerReceiver(receiver, IntentFilter(OpenListService.ACTION_STATUS_CHANGED))

        GeneratedPluginRegistrant.registerWith(this.flutterEngine!!)

        val binaryMessage = flutterEngine!!.dartExecutor.binaryMessenger
        GeneratedApi.AppConfig.setUp(binaryMessage, AppConfigBridge)
        GeneratedApi.Android.setUp(binaryMessage, AndroidBridge(this))
        GeneratedApi.NativeCommon.setUp(binaryMessage, CommonBridge(this))
        mEvent = GeneratedApi.Event(binaryMessage)

        // 设置服务桥接
        val serviceChannel = MethodChannel(binaryMessage, "com.openlist.mobile/service")
        serviceBridge = ServiceBridge(this, serviceChannel)

        Logger.addListener(object : Logger.Listener {
            override fun onLog(level: Int, time: String, msg: String) {
                GlobalScope.launch(Dispatchers.Main) {
                    mEvent?.onServerLog(level.toLong(), time, msg, object : VoidResult {
                        override fun success() {

                        }

                        override fun error(error: Throwable) {
                        }

                    })
                }
            }

        })
    }

    private fun setupWindowFlags() {
        try {
            // 对于Android 15及以上版本，启用边缘到边缘显示
            if (android.os.Build.VERSION.SDK_INT >= 35) { // Android 15 API level
                window.setFlags(
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
                )
            }
            
            // 确保在小窗模式下正确处理布局
            window.statusBarColor = android.graphics.Color.TRANSPARENT
            window.navigationBarColor = android.graphics.Color.TRANSPARENT
        } catch (e: Exception) {
            Log.w(TAG, "Failed to setup window flags: ${e.message}")
        }
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        Log.d(TAG, "Configuration changed - screenWidthDp: ${newConfig.screenWidthDp}, screenHeightDp: ${newConfig.screenHeightDp}")
        
        // 重新设置窗口标志以处理小窗模式变化
        setupWindowFlags()
    }

    override fun onDestroy() {
        super.onDestroy()

        LocalBroadcastManager.getInstance(this).unregisterReceiver(receiver)
    }


    inner class MyReceiver : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                OpenListService.ACTION_STATUS_CHANGED -> {
                    Log.d(TAG, "onReceive: ACTION_STATUS_CHANGED")

                    mEvent?.onServiceStatusChanged(OpenListService.isRunning, object : VoidResult {
                        override fun success() {}
                        override fun error(error: Throwable) {
                        }
                    })
                }



            }

        }
    }

}
