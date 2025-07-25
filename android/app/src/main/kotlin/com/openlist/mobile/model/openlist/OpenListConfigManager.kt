package com.openlist.mobile.model.openlist

import android.os.FileObserver
import android.util.Log
import com.openlist.mobile.app
import com.openlist.mobile.constant.AppConst
import com.openlist.mobile.utils.ToastUtils.longToast
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.channelFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.json.decodeFromStream
import kotlinx.serialization.json.encodeToStream
import java.io.File

@Suppress("DEPRECATION")
object OpenListConfigManager {
    const val TAG = "OpenListConfigManager"

    val context
        get() = app

    suspend fun flowConfig(): Flow<OpenListConfig> = channelFlow {
        val obs = object : FileObserver(OpenList.configPath) {
            override fun onEvent(event: Int, p1: String?) {
                if (listOf(CLOSE_NOWRITE, CLOSE_WRITE).contains(event))
                    runBlocking {
                        Log.d(TAG, "config.json changed: $event")
                        send((config()))
                    }
            }
        }
        coroutineScope {
            val waitJob = launch {
                obs.startWatching()
                try {
                    awaitCancellation()
                } catch (_: CancellationException) {
                }

                obs.stopWatching()
            }
            waitJob.join()
        }
    }

    @OptIn(ExperimentalSerializationApi::class)
    fun config(): OpenListConfig {
        try {
            File(OpenList.configPath).inputStream().use {
                return AppConst.json.decodeFromStream<OpenListConfig>(it)
            }
        } catch (e: Exception) {
            OpenList.context.longToast("读取 config.json 失败：\n$e")
            return OpenListConfig()
        }
    }

    @OptIn(ExperimentalSerializationApi::class)
    fun update(cfg: OpenListConfig) {
        try {
            File(OpenList.configPath).outputStream().use {
                AppConst.json.encodeToStream(cfg, it)
            }
        } catch (e: Exception) {
            OpenList.context.longToast("更新 config.json 失败：\n$e")
        }
    }

}