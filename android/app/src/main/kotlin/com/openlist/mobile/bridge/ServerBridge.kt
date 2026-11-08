package com.openlist.mobile.bridge

import android.content.Context
import android.os.Bundle
import com.openlist.mobile.OpenListService
import com.openlist.mobile.server.ServerClient
import com.openlist.mobile.server.ServerSettings
import com.openlist.pigeon.GeneratedApi
import com.openlist.mobile.server.ServerProtocol as P

/**
 * UI-process implementation of the Pigeon [GeneratedApi.ServerApi]. Lifecycle
 * commands go to the `:server` process as service intents; queries go through
 * [ServerClient] over the Messenger protocol.
 */
class ServerBridge(private val context: Context) : GeneratedApi.ServerApi {
    companion object {
        fun toServerStatus(b: Bundle): GeneratedApi.ServerStatus = GeneratedApi.ServerStatus.Builder()
            .setRunning(b.getBoolean(P.KEY_RUNNING))
            .setMode(b.getString(P.KEY_MODE) ?: ServerSettings.get().mode)
            .setHttpPort(b.getInt(P.KEY_HTTP_PORT, 5244).toLong())
            .setHttpsPort(b.getInt(P.KEY_HTTPS_PORT, -1).toLong())
            .setForceHttps(b.getBoolean(P.KEY_FORCE_HTTPS))
            .setAddresses(b.getStringArrayList(P.KEY_ADDRESSES) ?: emptyList())
            .setManuallyStopped(b.getBoolean(P.KEY_MANUALLY_STOPPED))
            .setLastError(b.getString(P.KEY_LAST_ERROR))
            .build()
    }

    private fun action(action: String, result: GeneratedApi.VoidResult) {
        try {
            OpenListService.sendAction(context, action)
            result.success()
        } catch (e: Exception) {
            result.error(e)
        }
    }

    override fun start(result: GeneratedApi.VoidResult) = action(OpenListService.ACTION_START, result)

    override fun stop(result: GeneratedApi.VoidResult) = action(OpenListService.ACTION_STOP, result)

    override fun restart(result: GeneratedApi.VoidResult) = action(OpenListService.ACTION_RESTART, result)

    override fun getStatus(result: GeneratedApi.Result<GeneratedApi.ServerStatus>) {
        ServerClient.request(P.MSG_GET_STATUS) { b ->
            val err = b.getString(P.KEY_ERROR)
            if (err != null && !b.containsKey(P.KEY_RUNNING)) {
                // Server process unavailable: report a stopped server.
                result.success(toServerStatus(Bundle().apply { putString(P.KEY_LAST_ERROR, err) }))
            } else {
                result.success(toServerStatus(b))
            }
        }
    }

    override fun getMode(): String = ServerSettings.get().mode

    override fun setMode(mode: String) {
        ServerSettings.update { it.copy(mode = ServerSettings.normalizeMode(mode)) }
        ServerClient.notify(P.MSG_REFRESH_SETTINGS)
    }

    override fun setAdminPassword(pwd: String, result: GeneratedApi.VoidResult) {
        val data = Bundle().apply { putString(P.KEY_PASSWORD, pwd) }
        ServerClient.request(P.MSG_SET_ADMIN_PASSWORD, data) { b ->
            b.getString(P.KEY_ERROR)?.let { result.error(GeneratedApi.FlutterError("server", it, null)) }
                ?: result.success()
        }
    }

    private fun stringRequest(what: Int, data: Bundle, result: GeneratedApi.Result<String>) {
        ServerClient.request(what, data) { b ->
            val err = b.getString(P.KEY_ERROR)
            if (err != null) {
                result.error(GeneratedApi.FlutterError("server", err, null))
            } else {
                result.success(b.getString(P.KEY_RESULT).orEmpty())
            }
        }
    }

    override fun getLocalToken(result: GeneratedApi.Result<String>) =
        stringRequest(P.MSG_GET_TOKEN, Bundle(), result)

    override fun getRuntimeStatus(result: GeneratedApi.Result<String>) =
        stringRequest(P.MSG_GET_RUNTIME, Bundle(), result)

    override fun getSecurityReport(mode: String, result: GeneratedApi.Result<String>) =
        stringRequest(P.MSG_GET_SECURITY, Bundle().apply { putString(P.KEY_MODE, mode) }, result)

    override fun getRecentLogs(result: GeneratedApi.Result<List<GeneratedApi.LogEntry>>) {
        ServerClient.request(P.MSG_GET_LOGS) { b ->
            val levels = b.getIntArray(P.KEY_LEVELS) ?: IntArray(0)
            val times = b.getStringArrayList(P.KEY_TIMES).orEmpty()
            val messages = b.getStringArrayList(P.KEY_MESSAGES).orEmpty()
            val n = minOf(levels.size, times.size, messages.size)
            result.success((0 until n).map {
                GeneratedApi.LogEntry.Builder()
                    .setLevel(levels[it].toLong())
                    .setTime(times[it])
                    .setMessage(messages[it])
                    .build()
            })
        }
    }
}
