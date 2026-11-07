package com.openlist.mobile.bridge

import android.content.Context
import android.os.Build
import com.openlist.mobile.utils.BatteryOptimizationUtils
import com.openlist.pigeon.GeneratedApi

/** Background-running diagnostics and system settings shortcuts. */
class BackgroundBridge(private val context: Context) : GeneratedApi.BackgroundApi {
    override fun getDiagnostics(): GeneratedApi.BackgroundDiagnostics =
        BatteryOptimizationUtils.diagnostics(context)

    override fun requestIgnoreBatteryOptimizations(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            BatteryOptimizationUtils.requestIgnoreBatteryOptimizations(context)

    override fun openBatteryOptimizationSettings(): Boolean =
        BatteryOptimizationUtils.openBatteryOptimizationSettings(context)

    override fun openAutoStartSettings(): Boolean =
        BatteryOptimizationUtils.openAutoStartSettings(context)

    override fun openAppDetailsSettings(): Boolean =
        BatteryOptimizationUtils.openAppDetailsSettings(context)
}
