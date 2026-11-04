package com.openlist.mobile.bridge

import com.openlist.mobile.config.AppConfig
import com.openlist.mobile.server.ServerClient
import com.openlist.mobile.server.ServerProtocol
import com.openlist.pigeon.GeneratedApi


object AppConfigBridge : GeneratedApi.AppConfig {
    override fun isWakeLockEnabled() = AppConfig.isWakeLockEnabled

    override fun isStartAtBootEnabled() = AppConfig.isStartAtBootEnabled

    override fun isAutoCheckUpdateEnabled() = AppConfig.isAutoCheckUpdateEnabled
    override fun isAutoOpenWebPageEnabled() = AppConfig.isAutoOpenWebPageEnabled
    override fun getDataDir() = AppConfig.dataDir

    override fun setDataDir(dir: String) {
        val selected = dir.trim()
        val rawPath = if (selected.startsWith("file://")) {
            android.net.Uri.parse(selected).path ?: selected
        } else {
            selected
        }
        if (rawPath.isNotEmpty()) {
            val directory = java.io.File(rawPath)
            if (!directory.exists() && !directory.mkdirs()) {
                throw IllegalArgumentException("Cannot create data directory")
            }
            if (!directory.isDirectory || !directory.canWrite()) {
                throw IllegalArgumentException("Data directory is not writable")
            }
            val probe = java.io.File.createTempFile(".openlist-data-", ".tmp", directory)
            if (!probe.delete()) {
                throw IllegalArgumentException("Cannot verify data directory access")
            }
        }
        AppConfig.dataDir = rawPath
    }

    override fun isSilentJumpAppEnabled(): Boolean = AppConfig.isSilentJumpAppEnabled

    override fun setSilentJumpAppEnabled(enabled: Boolean) {
        AppConfig.isSilentJumpAppEnabled = enabled
    }

    override fun setAutoOpenWebPageEnabled(enabled: Boolean) {
        AppConfig.isAutoOpenWebPageEnabled = enabled
    }

    override fun setAutoCheckUpdateEnabled(enabled: Boolean) {
        AppConfig.isAutoCheckUpdateEnabled = enabled
    }

    override fun setStartAtBootEnabled(enabled: Boolean) {
        AppConfig.isStartAtBootEnabled = enabled
    }

    override fun setWakeLockEnabled(enabled: Boolean) {
        AppConfig.isWakeLockEnabled = enabled
        ServerClient.notify(ServerProtocol.MSG_REFRESH_SETTINGS)
    }
}