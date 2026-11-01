package com.openlist.mobile.server

import android.util.Log
import com.openlist.mobile.app
import com.openlist.mobile.config.AppConfig
import org.json.JSONObject
import java.io.File
import java.io.RandomAccessFile

/**
 * Server settings shared between the UI process and the `:server` process.
 *
 * SharedPreferences caches values per process, so settings that the server
 * process must observe are kept in a small JSON file that is re-read on every
 * access and written atomically under a cross-process file lock.
 */
object ServerSettings {
    private const val TAG = "ServerSettings"
    const val MODE_LOCAL = "local"
    const val MODE_LAN = "lan"
    const val MODE_PUBLIC = "public"

    data class Values(
        val mode: String = MODE_LOCAL,
        val wakeLock: Boolean = false,
        val startAtBoot: Boolean = false,
        val manuallyStopped: Boolean = false,
        val wasRunning: Boolean = false,
        val dataDir: String = "",
    )

    private val file get() = File(app.filesDir, "server_settings.json")
    private val lockFile get() = File(app.filesDir, "server_settings.lock")

    val defaultDataDir: String by lazy {
        (app.getExternalFilesDir("data") ?: File(app.filesDir, "data")).absolutePath
    }

    fun get(): Values = locked { read() }

    fun update(block: (Values) -> Values): Values = locked {
        val next = block(read())
        write(next)
        next
    }

    fun normalizeMode(mode: String?) = when (mode) {
        MODE_LAN, MODE_PUBLIC -> mode
        else -> MODE_LOCAL
    }

    val dataDir: String
        get() = get().dataDir.ifBlank { defaultDataDir }

    private fun <T> locked(block: () -> T): T = synchronized(this) {
        RandomAccessFile(lockFile, "rw").use { raf ->
            raf.channel.lock().use { block() }
        }
    }

    private fun read(): Values {
        val f = file
        if (!f.exists()) return migrate().also { write(it) }
        return try {
            val o = JSONObject(f.readText())
            Values(
                mode = normalizeMode(o.optString("mode")),
                wakeLock = o.optBoolean("wakeLock"),
                startAtBoot = o.optBoolean("startAtBoot"),
                manuallyStopped = o.optBoolean("manuallyStopped"),
                wasRunning = o.optBoolean("wasRunning"),
                dataDir = o.optString("dataDir"),
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to read settings, using defaults", e)
            Values()
        }
    }

    private fun write(v: Values) {
        val o = JSONObject()
            .put("mode", v.mode)
            .put("wakeLock", v.wakeLock)
            .put("startAtBoot", v.startAtBoot)
            .put("manuallyStopped", v.manuallyStopped)
            .put("wasRunning", v.wasRunning)
            .put("dataDir", v.dataDir)
        val tmp = File(file.parentFile, "${file.name}.tmp")
        tmp.writeText(o.toString())
        if (!tmp.renameTo(file)) {
            file.writeText(o.toString())
            tmp.delete()
        }
    }

    /**
     * First run after upgrade: carry over the legacy per-process preferences.
     * Installs that already have a config.json keep LAN exposure so an update
     * does not silently cut off existing clients; fresh installs bind loopback.
     */
    private fun migrate(): Values {
        val legacy = runCatching { AppConfig.legacyServerValues() }
            .onFailure { Log.e(TAG, "Failed to read legacy preferences", it) }
            .getOrDefault(Values())
        val dir = legacy.dataDir.ifBlank { defaultDataDir }
        val existingInstall = File(dir, "config.json").exists()
        Log.i(TAG, "Migrating legacy settings, existing install: $existingInstall")
        return legacy.copy(mode = if (existingInstall) MODE_LAN else MODE_LOCAL)
    }
}
