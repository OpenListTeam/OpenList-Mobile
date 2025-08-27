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
    }

    private val statusReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                OpenListService.ACTION_STATUS_CHANGED -> {
                    Log.d(TAG, "Service status changed, updating tile")
                    updateTileState()
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
        val isRunning = OpenListService.isRunning
        Log.d(TAG, "Tile clicked, service running: $isRunning")
        if (isRunning) {
            stopOpenListService()
        } else {
            startOpenListService()
        }
        updateTileState()
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
            } else {
                val intent = Intent(this, OpenListService::class.java)
                stopService(intent)
            }

            Log.d(TAG, "Service stop command sent from tile")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop service from tile", e)
        }
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