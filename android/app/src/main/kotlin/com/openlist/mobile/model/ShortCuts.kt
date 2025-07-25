package com.openlist.mobile.model

import android.content.Context
import android.content.Intent
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import com.openlist.mobile.R
import com.openlist.mobile.SwitchServerActivity


object ShortCuts {
    private inline fun <reified T> buildIntent(context: Context): Intent {
        val intent = Intent(context, T::class.java)
        intent.action = Intent.ACTION_VIEW
        return intent
    }


    private fun buildOpenListSwitchShortCutInfo(context: Context): ShortcutInfoCompat {
        val msSwitchIntent = buildIntent<SwitchServerActivity>(context)
        return ShortcutInfoCompat.Builder(context, "openlist_switch")
            .setShortLabel(context.getString(R.string.app_switch))
            .setLongLabel(context.getString(R.string.app_switch))
            .setIcon(IconCompat.createWithResource(context, R.drawable.openlist_switch))
            .setIntent(msSwitchIntent)
            .build()
    }


    fun buildShortCuts(context: Context) {
        ShortcutManagerCompat.setDynamicShortcuts(
            context, listOf(
                buildOpenListSwitchShortCutInfo(context),
            )
        )
    }


}