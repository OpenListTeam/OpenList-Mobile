package com.openlist.mobile.config

import com.cioccarellia.ksprefs.KsPrefs
import com.cioccarellia.ksprefs.dynamic
import com.openlist.mobile.app

object AppConfig {
    val prefs by lazy { KsPrefs(app, "app") }

    var isSilentJumpAppEnabled by prefs.dynamic("isSilentJumpAppEnabled", fallback = false)

    var isWakeLockEnabled: Boolean by prefs.dynamic("isWakeLockEnabled", fallback = false)
    var isStartAtBootEnabled: Boolean by prefs.dynamic("isStartAtBootEnabled", fallback = false)
    var isAutoCheckUpdateEnabled: Boolean by prefs.dynamic(
        "isAutoCheckUpdateEnabled",
        fallback = false
    )

    var isAutoOpenWebPageEnabled: Boolean by prefs.dynamic(
        "isAutoOpenWebPageEnabled",
        fallback = false
    )

    // 用户手动停止服务的标志，当为true时，保活机制不会重启服务
    var isManuallyStoppedByUser: Boolean by prefs.dynamic("isManuallyStoppedByUser", fallback = false)

    val defaultDataDir by lazy { app.getExternalFilesDir("data")?.absolutePath!! }

    private var mDataDir: String by prefs.dynamic("dataDir", fallback = defaultDataDir)


    var dataDir: String
        get() {
            if (mDataDir.isBlank()) mDataDir = defaultDataDir
            return mDataDir
        }
        set(value) {
            if (value.isBlank()) {
                mDataDir = defaultDataDir
                return
            }

            mDataDir = value
        }

}