package com.openlist.mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.drawable.Icon
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.openlist.mobile.config.AppConfig


@RequiresApi(Build.VERSION_CODES.N)
class OpenListTileService : TileService() {
    companion object {
        private const val TAG = "OpenListTileService"
        private const val CLICK_DEBOUNCE_TIME = 2000L // 2秒防重复点击
    }

    private var lastClickTime = 0L

    private val statusReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                OpenListService.ACTION_STATUS_CHANGED -> {
                    Log.d(TAG, "Service status changed, updating tile")
                    // 添加小延迟确保状态稳定
                    qsTile?.let {
                        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                            updateTileState()
                        }, 100)
                    }
                }
            }
        }
    }

    override fun onStartListening() {
        super.onStartListening()
        Log.d(TAG, "Tile started listening")
        LocalBroadcastManager.getInstance(this)
            .registerReceiver(statusReceiver, IntentFilter(OpenListService.ACTION_STATUS_CHANGED))

        updateTileState()
    }

    override fun onStopListening() {
        super.onStopListening()
        Log.d(TAG, "Tile stopped listening")
        try {
            LocalBroadcastManager.getInstance(this).unregisterReceiver(statusReceiver)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to unregister receiver", e)
        }
    }

    override fun onClick() {
        super.onClick()
        
        // 防重复点击
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastClickTime < CLICK_DEBOUNCE_TIME) {
            Log.d(TAG, "Click ignored due to debounce")
            return
        }
        lastClickTime = currentTime
        
        val isRunning = OpenListService.isRunning
        Log.d(TAG, "Tile clicked, service running: $isRunning")
        
        // 设置瓦片为过渡状态，显示操作进行中
        setTileTransitionState(!isRunning)
        
        if (isRunning) {
            stopOpenListService()
        } else {
            startOpenListService()
        }
        // 移除立即状态更新，依赖广播接收器异步更新
        // updateTileState() - 现在由广播接收器处理
    }

    private fun startOpenListService() {
        try {
            AppConfig.isManuallyStoppedByUser = false
            val intent = Intent(this, OpenListService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }

            Log.d(TAG, "Service start command sent from tile")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start service from tile", e)
        }
    }

    private fun stopOpenListService() {
        try {
            AppConfig.isManuallyStoppedByUser = true
            val serviceInstance = OpenListService.serviceInstance
            if (serviceInstance != null && OpenListService.isRunning) {
                serviceInstance.stopOpenListService()
            }
            // 移除else分支的冗余stopService调用
            Log.d(TAG, "Service stop command sent from tile")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop service from tile", e)
            // 出错时恢复瓦片状态
            updateTileState()
        }
    }

    /**
     * 设置瓦片过渡状态，显示操作正在进行中
     */
    private fun setTileTransitionState(targetActiveState: Boolean) {
        val tile = qsTile ?: return
        
        // 设置过渡状态
        tile.state = if (targetActiveState) Tile.STATE_UNAVAILABLE else Tile.STATE_UNAVAILABLE
        tile.label = if (targetActiveState) "启动中..." else "停止中..."
        tile.contentDescription = if (targetActiveState) "OpenList Starting" else "OpenList Stopping"
        
        try {
            val icon = Icon.createWithResource(this, R.mipmap.ic_launcher)
            tile.icon = icon
        } catch (e: Exception) {
            Log.w(TAG, "Failed to set tile icon during transition", e)
        }
        
        tile.updateTile()
        Log.d(TAG, "Tile set to transition state: ${if (targetActiveState) "starting" else "stopping"}")
    }

    private fun updateTileState() {
        val tile = qsTile ?: return
        val isRunning = OpenListService.isRunning
        Log.d(TAG, "Updating tile state, service running: $isRunning")

        if (isRunning) {
            tile.state = Tile.STATE_ACTIVE
            tile.label = "OpenList"
            tile.contentDescription = "OpenList Running"
        } else {
            tile.state = Tile.STATE_INACTIVE
            tile.label = "OpenList"
            tile.contentDescription = "OpenList Stopped"
        }
        try {
            val icon = Icon.createWithResource(this, R.mipmap.ic_launcher)
            tile.icon = icon
        } catch (e: Exception) {
            Log.w(TAG, "Failed to set tile icon", e)
        }

        tile.updateTile()
    }
}