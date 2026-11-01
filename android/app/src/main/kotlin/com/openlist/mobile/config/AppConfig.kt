package com.openlist.mobile.config

import com.cioccarellia.ksprefs.KsPrefs
import com.cioccarellia.ksprefs.dynamic
import com.openlist.mobile.app
import com.openlist.mobile.server.ServerSettings

object AppConfig {
    val prefs by lazy { KsPrefs(app, "app") }

    // UI-only preferences, read by the main process.
    var isSilentJumpAppEnabled by prefs.dynamic("isSilentJumpAppEnabled", fallback = false)
    var isAutoCheckUpdateEnabled: Boolean by prefs.dynamic(
        "isAutoCheckUpdateEnabled",
        fallback = false
    )
    var isAutoOpenWebPageEnabled: Boolean by prefs.dynamic(
        "isAutoOpenWebPageEnabled",
        fallback = false
    )

    // Legacy per-process values, only read once to migrate into ServerSettings.
    private var legacyWakeLock: Boolean by prefs.dynamic("isWakeLockEnabled", fallback = false)
    private var legacyStartAtBoot: Boolean by prefs.dynamic("isStartAtBootEnabled", fallback = false)
    private var legacyManuallyStopped: Boolean by prefs.dynamic("isManuallyStoppedByUser", fallback = false)
    private var legacyDataDir: String by prefs.dynamic("dataDir", fallback = "")

    /** Must not touch [ServerSettings]; it is called while its file lock is held. */
    internal fun legacyServerValues() = ServerSettings.Values(
        wakeLock = legacyWakeLock,
        startAtBoot = legacyStartAtBoot,
        manuallyStopped = legacyManuallyStopped,
        dataDir = legacyDataDir,
    )

    // Server settings shared with the :server process.
    var isWakeLockEnabled: Boolean
        get() = ServerSettings.get().wakeLock
        set(value) {
            ServerSettings.update { it.copy(wakeLock = value) }
        }

    var isStartAtBootEnabled: Boolean
        get() = ServerSettings.get().startAtBoot
        set(value) {
            ServerSettings.update { it.copy(startAtBoot = value) }
        }

    var isManuallyStoppedByUser: Boolean
        get() = ServerSettings.get().manuallyStopped
        set(value) {
            ServerSettings.update { it.copy(manuallyStopped = value) }
        }

    val defaultDataDir: String get() = ServerSettings.defaultDataDir

    var dataDir: String
        get() = ServerSettings.dataDir
        set(value) {
            ServerSettings.update { it.copy(dataDir = value.trim()) }
        }
}
