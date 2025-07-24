package com.openlist.mobile.utils

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import androidx.annotation.RequiresApi

/**
 * 电池优化管理工具类
 * 帮助应用获得电池优化白名单，提高后台服务存活率
 */
object BatteryOptimizationUtils {
    private const val TAG = "BatteryOptimization"

    /**
     * 检查是否在电池优化白名单中
     */
    @RequiresApi(Build.VERSION_CODES.M)
    fun isIgnoringBatteryOptimizations(context: Context): Boolean {
        return try {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            powerManager.isIgnoringBatteryOptimizations(context.packageName)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to check battery optimization status", e)
            false
        }
    }

    /**
     * 请求忽略电池优化
     */
    @SuppressLint("BatteryLife")
    @RequiresApi(Build.VERSION_CODES.M)
    fun requestIgnoreBatteryOptimizations(context: Context): Boolean {
        return try {
            if (isIgnoringBatteryOptimizations(context)) {
                Log.d(TAG, "Already ignoring battery optimizations")
                return true
            }

            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:${context.packageName}")
            }
            
            if (intent.resolveActivity(context.packageManager) != null) {
                context.startActivity(intent)
                Log.d(TAG, "Battery optimization request sent")
                true
            } else {
                Log.w(TAG, "No activity found to handle battery optimization request")
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to request battery optimization exemption", e)
            false
        }
    }

    /**
     * 打开电池优化设置页面
     */
    fun openBatteryOptimizationSettings(context: Context): Boolean {
        return try {
            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
            } else {
                Intent(Settings.ACTION_APPLICATION_SETTINGS)
            }
            
            if (intent.resolveActivity(context.packageManager) != null) {
                context.startActivity(intent)
                Log.d(TAG, "Battery optimization settings opened")
                true
            } else {
                Log.w(TAG, "No activity found to handle battery optimization settings")
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open battery optimization settings", e)
            false
        }
    }

    /**
     * 打开应用详情页面
     */
    fun openAppDetailsSettings(context: Context): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:${context.packageName}")
            }
            
            if (intent.resolveActivity(context.packageManager) != null) {
                context.startActivity(intent)
                Log.d(TAG, "App details settings opened")
                true
            } else {
                Log.w(TAG, "No activity found to handle app details settings")
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open app details settings", e)
            false
        }
    }

    /**
     * 尝试打开自启动管理页面（针对不同厂商）
     */
    fun openAutoStartSettings(context: Context): Boolean {
        return try {
            val autoStartIntents = listOf(
                // 华为
                Intent().setClassName(
                    "com.huawei.systemmanager",
                    "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"
                ),
                Intent().setClassName(
                    "com.huawei.systemmanager",
                    "com.huawei.systemmanager.optimize.process.ProtectActivity"
                ),
                // 小米
                Intent().setClassName(
                    "com.miui.securitycenter",
                    "com.miui.permcenter.autostart.AutoStartManagementActivity"
                ),
                Intent().setClassName(
                    "com.xiaomi.mipicks",
                    "com.xiaomi.mipicks.ui.AppPicksTabActivity"
                ),
                // OPPO
                Intent().setClassName(
                    "com.coloros.safecenter",
                    "com.coloros.safecenter.permission.startup.FakeActivity"
                ),
                Intent().setClassName(
                    "com.oppo.safe",
                    "com.oppo.safe.permission.startup.StartupAppListActivity"
                ),
                // Vivo
                Intent().setClassName(
                    "com.iqoo.secure",
                    "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity"
                ),
                Intent().setClassName(
                    "com.vivo.permissionmanager",
                    "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"
                ),
                // 魅族
                Intent().setClassName(
                    "com.meizu.safe",
                    "com.meizu.safe.security.SHOW_APPSEC"
                ).apply {
                    addCategory(Intent.CATEGORY_DEFAULT)
                    putExtra("packageName", context.packageName)
                },
                // 三星
                Intent().setClassName(
                    "com.samsung.android.lool",
                    "com.samsung.android.sm.ui.battery.BatteryActivity"
                ),
                // 一加
                Intent().setClassName(
                    "com.oneplus.security",
                    "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity"
                )
            )

            for (intent in autoStartIntents) {
                try {
                    if (intent.resolveActivity(context.packageManager) != null) {
                        context.startActivity(intent)
                        Log.d(TAG, "Auto start settings opened: ${intent.component}")
                        return true
                    }
                } catch (e: Exception) {
                    Log.d(TAG, "Failed to open auto start settings: ${intent.component}", e)
                }
            }

            Log.w(TAG, "No auto start settings activity found")
            false
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open auto start settings", e)
            false
        }
    }

    /**
     * 获取电池优化状态描述
     */
    fun getBatteryOptimizationStatus(context: Context): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (isIgnoringBatteryOptimizations(context)) {
                "已加入电池优化白名单"
            } else {
                "未加入电池优化白名单"
            }
        } else {
            "系统版本过低，无需设置"
        }
    }

    /**
     * 检查是否需要设置电池优化
     */
    fun needsBatteryOptimizationSetup(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            !isIgnoringBatteryOptimizations(context)
        } else {
            false
        }
    }
}