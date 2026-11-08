package com.openlist.mobile

import android.annotation.SuppressLint
import android.app.PendingIntent
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

/** Quick settings tile; runs in the `:server` process next to the service. */
@RequiresApi(Build.VERSION_CODES.N)
class OpenListTileService : TileService() {
    companion object {
        private const val TAG = "OpenListTileService"
        private const val CLICK_DEBOUNCE_TIME = 2000L
    }

    private var lastClickTime = 0L

    private val statusReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == OpenListService.ACTION_STATUS_CHANGED) updateTileState()
        }
    }

    override fun onStartListening() {
        super.onStartListening()
        LocalBroadcastManager.getInstance(this)
            .registerReceiver(statusReceiver, IntentFilter(OpenListService.ACTION_STATUS_CHANGED))
        updateTileState()
    }

    override fun onStopListening() {
        super.onStopListening()
        runCatching { LocalBroadcastManager.getInstance(this).unregisterReceiver(statusReceiver) }
    }

    override fun onClick() {
        super.onClick()
        val now = System.currentTimeMillis()
        if (now - lastClickTime < CLICK_DEBOUNCE_TIME) return
        lastClickTime = now

        val running = OpenListService.isRunning
        Log.d(TAG, "Tile clicked, running: $running")
        setTileTransitionState(!running)
        try {
            OpenListService.sendAction(
                this,
                if (running) OpenListService.ACTION_STOP else OpenListService.ACTION_START
            )
        } catch (e: Exception) {
            // Some systems deny FGS starts from a tile; let the user start it in the app.
            Log.e(TAG, "Failed to send action from tile", e)
            openApp()
            updateTileState()
        }
    }

    @SuppressLint("StartActivityAndCollapseDeprecated")
    @Suppress("DEPRECATION")
    private fun openApp() {
        val intent = Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(
                PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_IMMUTABLE)
            )
        } else {
            startActivityAndCollapse(intent)
        }
    }

    private fun setTileTransitionState(targetActive: Boolean) {
        val tile = qsTile ?: return
        tile.state = Tile.STATE_UNAVAILABLE
        tile.label = getString(if (targetActive) R.string.openlist_starting else R.string.openlist_shut_downing)
        tile.icon = Icon.createWithResource(this, R.mipmap.ic_launcher)
        tile.updateTile()
    }

    private fun updateTileState() {
        val tile = qsTile ?: return
        val running = OpenListService.isRunning
        tile.state = if (running) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        tile.label = "OpenList"
        tile.contentDescription = if (running) "OpenList Running" else "OpenList Stopped"
        tile.icon = Icon.createWithResource(this, R.mipmap.ic_launcher)
        tile.updateTile()
    }
}
