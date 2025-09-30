package com.openlist.mobile.model.openlist

import openlistlib.Openlistlib
import openlistlib.Event
import openlistlib.LogCallback
import android.annotation.SuppressLint
import android.util.Log
import com.openlist.mobile.R
import com.openlist.mobile.app
import com.openlist.mobile.config.AppConfig
import com.openlist.mobile.constant.LogLevel
import com.openlist.mobile.utils.ToastUtils.longToast
import java.io.File
import java.text.SimpleDateFormat
import java.util.Locale

object OpenList : Event, LogCallback {
    const val TAG = "OpenList"

    val context = app

    val dataDir: String
        get() = AppConfig.dataDir

    val configPath: String
        get() = "$dataDir${File.separator}config.json"


    fun init() {
        runCatching {
            Openlistlib.setConfigData(dataDir)
            Openlistlib.setConfigLogStd(true)
            Openlistlib.init(this, this)
        }.onFailure {
            Log.e(TAG, "init:", it)
        }
    }

    interface Listener {
        fun onShutdown(type: String)
    }

    private val mListeners = mutableListOf<Listener>()

    fun addListener(listener: Listener) {
        mListeners.add(listener)
    }

    fun removeListener(listener: Listener) {
        mListeners.remove(listener)
    }

    override fun onShutdown(p0: String) {
        Log.d(TAG, "onShutdown: $p0")
        mListeners.forEach { it.onShutdown(p0) }
    }

    override fun onStartError(type: String, msg: String) {
        Log.e(TAG, "onStartError: $type, $msg")
        Logger.log(LogLevel.FATAL, type, msg)
    }

    private val mDateFormatter by lazy  { SimpleDateFormat("MM-dd HH:mm:ss", Locale.getDefault())}

    override fun onLog(level: Short, time: Long, log: String) {
        Log.d(TAG, "onLog: $level, $time, $log")
        Logger.log(level.toInt(), mDateFormatter.format(time), log)
    }

    override fun onProcessExit(code: Long) {

    }

    fun isRunning(): Boolean {
        return Openlistlib.isRunning("")
    }

    fun setAdminPassword(pwd: String) {
        if (!isRunning()) init()

        Log.d(TAG, "setAdminPassword: $dataDir")
        Openlistlib.setConfigData(dataDir)
        Openlistlib.setAdminPassword(pwd)
    }


    fun shutdown() {
        Log.d(TAG, "shutdown")
        runCatching {
            Openlistlib.shutdown(5000)
        }.onFailure {
            context.longToast(R.string.shutdown_failed)
        }
    }

    /**
     * Force database synchronization (WAL checkpoint)
     * This ensures SQLite WAL files are merged into the main database file
     */
    fun forceDatabaseSync() {
        Log.d(TAG, "forceDatabaseSync")
        runCatching {
            Openlistlib.forceDBSync()
            Log.d(TAG, "Database sync completed successfully")
        }.onFailure { e ->
            Log.e(TAG, "Failed to sync database", e)
        }
    }

    @SuppressLint("SdCardPath")
    @Synchronized
    fun startup() {
        Log.d(TAG, "startup: $dataDir")
        try {
            // 确保数据目录存在
            val dataDirFile = File(dataDir)
            if (!dataDirFile.exists()) {
                dataDirFile.mkdirs()
                Log.d(TAG, "Created data directory: $dataDir")
            }
            
            // 重新初始化以确保配置正确
            init()
            
            // 多重检查是否已经在运行，防止重复启动
            if (isRunning()) {
                Log.w(TAG, "OpenList is already running, skipping startup")
                return
            }
            
            // 再次检查以确保安全
            Thread.sleep(100) // 短暂等待以避免竞态条件
            if (isRunning()) {
                Log.w(TAG, "OpenList started by another thread, skipping startup")
                return
            }
            
            Log.d(TAG, "Starting OpenList...")
            Openlistlib.start()
            
            // 验证启动是否成功
            Thread.sleep(1000) // 等待1秒让服务完全启动
            if (isRunning()) {
                Log.d(TAG, "OpenList started successfully and confirmed running")
            } else {
                Log.w(TAG, "OpenList startup command sent but status check failed")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start OpenList", e)
            throw e
        } catch (t: Throwable) {
            Log.e(TAG, "Fatal error starting OpenList", t)
            throw RuntimeException("Fatal error starting OpenList", t)
        }
    }

    fun getHttpPort(): Int {
        return OpenListConfigManager.config().scheme.httpPort
    }
}