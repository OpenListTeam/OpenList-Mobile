package com.openlist.mobile.utils

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Process
import android.util.Log
import com.openlist.mobile.KeepAliveService
import com.openlist.mobile.OpenListService
import com.openlist.mobile.config.AppConfig
import kotlinx.coroutines.*

/**
 * 进程守护者 - 实现双进程保活机制
 */
object ProcessGuardian {
    private const val TAG = "ProcessGuardian"
    private const val CHECK_INTERVAL = 10000L // 10秒检查一次
    
    private var guardianScope: CoroutineScope? = null
    private var isGuarding = false
    
    /**
     * 开始进程守护
     */
    fun startGuarding(context: Context) {
        if (isGuarding) {
            Log.d(TAG, "Guardian already running")
            return
        }
        
        isGuarding = true
        guardianScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
        
        guardianScope?.launch {
            Log.d(TAG, "Process guardian started")
            
            while (isActive && isGuarding) {
                try {
                    // 检查主服务进程
                    checkMainServiceProcess(context)
                    
                    // 检查保活服务进程
                    checkKeepAliveServiceProcess(context)
                    
                    // 等待下次检查
                    delay(CHECK_INTERVAL)
                } catch (e: Exception) {
                    Log.e(TAG, "Error in process guardian", e)
                    delay(5000) // 出错时等待5秒再重试
                }
            }
            
            Log.d(TAG, "Process guardian stopped")
        }
    }
    
    /**
     * 停止进程守护
     */
    fun stopGuarding() {
        isGuarding = false
        guardianScope?.cancel()
        guardianScope = null
        Log.d(TAG, "Process guardian stop requested")
    }
    
    /**
     * 检查主服务进程
     */
    private fun checkMainServiceProcess(context: Context) {
        try {
            val isMainProcessAlive = isProcessAlive(context, context.packageName)
            val isServiceRunning = OpenListService.isRunning
            
            if (!isMainProcessAlive || !isServiceRunning) {
                Log.w(TAG, "Main service process issue detected - Process alive: $isMainProcessAlive, Service running: $isServiceRunning")
                restartMainService(context)
            } else {
                Log.d(TAG, "Main service process is healthy")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to check main service process", e)
        }
    }
    
    /**
     * 检查保活服务进程
     */
    private fun checkKeepAliveServiceProcess(context: Context) {
        try {
            val keepAliveProcessName = "${context.packageName}:keep_alive"
            val isKeepAliveProcessAlive = isProcessAlive(context, keepAliveProcessName)
            
            if (!isKeepAliveProcessAlive) {
                Log.w(TAG, "Keep alive service process not found, restarting...")
                restartKeepAliveService(context)
            } else {
                Log.d(TAG, "Keep alive service process is healthy")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to check keep alive service process", e)
        }
    }
    
    /**
     * 检查进程是否存活
     */
    private fun isProcessAlive(context: Context, processName: String): Boolean {
        return try {
            val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val runningProcesses = activityManager.runningAppProcesses
            
            runningProcesses?.any { processInfo ->
                processInfo.processName == processName
            } ?: false
        } catch (e: Exception) {
            Log.e(TAG, "Failed to check if process is alive: $processName", e)
            false
        }
    }
    
    /**
     * 重启主服务
     */
    private fun restartMainService(context: Context) {
        try {
            // 检查是否被用户手动停止
            if (AppConfig.isManuallyStoppedByUser) {
                Log.d(TAG, "Service was manually stopped by user, skipping main service restart")
                return
            }
            
            // 检查是否启用���开机启动（保活功能）
            if (!AppConfig.isStartAtBootEnabled) {
                Log.d(TAG, "Auto start disabled, skipping main service restart")
                return
            }
            
            val intent = Intent(context, OpenListService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
            Log.d(TAG, "Main service restart command sent")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to restart main service", e)
        }
    }
    
    /**
     * 重启保活服务
     */
    private fun restartKeepAliveService(context: Context) {
        try {
            // 检查是否被用户手动停止
            if (AppConfig.isManuallyStoppedByUser) {
                Log.d(TAG, "Service was manually stopped by user, skipping keep alive service restart")
                return
            }
            
            // 检查是否启用了开机启动（保活功能）
            if (!AppConfig.isStartAtBootEnabled) {
                Log.d(TAG, "Auto start disabled, skipping keep alive service restart")
                return
            }
            
            val intent = Intent(context, KeepAliveService::class.java)
            context.startService(intent)
            Log.d(TAG, "Keep alive service restart command sent")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to restart keep alive service", e)
        }
    }
    
    /**
     * 获取当前进程信息
     */
    fun getCurrentProcessInfo(context: Context): ProcessInfo {
        return try {
            val pid = Process.myPid()
            val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val runningProcesses = activityManager.runningAppProcesses
            
            val currentProcess = runningProcesses?.find { it.pid == pid }
            
            ProcessInfo(
                pid = pid,
                processName = currentProcess?.processName ?: "unknown",
                importance = currentProcess?.importance ?: ActivityManager.RunningAppProcessInfo.IMPORTANCE_GONE,
                isMainProcess = currentProcess?.processName == context.packageName
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get current process info", e)
            ProcessInfo(
                pid = Process.myPid(),
                processName = "unknown",
                importance = ActivityManager.RunningAppProcessInfo.IMPORTANCE_GONE,
                isMainProcess = false
            )
        }
    }
    
    /**
     * 获取所有相关进程信息
     */
    fun getAllRelatedProcesses(context: Context): List<ProcessInfo> {
        return try {
            val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val runningProcesses = activityManager.runningAppProcesses
            
            runningProcesses?.filter { processInfo ->
                processInfo.processName.startsWith(context.packageName)
            }?.map { processInfo ->
                ProcessInfo(
                    pid = processInfo.pid,
                    processName = processInfo.processName,
                    importance = processInfo.importance,
                    isMainProcess = processInfo.processName == context.packageName
                )
            } ?: emptyList()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get all related processes", e)
            emptyList()
        }
    }
    
    /**
     * 进程信息数据类
     */
    data class ProcessInfo(
        val pid: Int,
        val processName: String,
        val importance: Int,
        val isMainProcess: Boolean
    ) {
        fun getImportanceDescription(): String {
            return when (importance) {
                ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND -> "前台"
                ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND_SERVICE -> "前台服务"
                ActivityManager.RunningAppProcessInfo.IMPORTANCE_TOP_SLEEPING -> "顶层休眠"
                ActivityManager.RunningAppProcessInfo.IMPORTANCE_VISIBLE -> "可见"
                ActivityManager.RunningAppProcessInfo.IMPORTANCE_PERCEPTIBLE -> "可感知"
                ActivityManager.RunningAppProcessInfo.IMPORTANCE_CANT_SAVE_STATE -> "无法保存状态"
                ActivityManager.RunningAppProcessInfo.IMPORTANCE_SERVICE -> "服务"
                ActivityManager.RunningAppProcessInfo.IMPORTANCE_CACHED -> "缓存"
                ActivityManager.RunningAppProcessInfo.IMPORTANCE_GONE -> "已消失"
                else -> "未知($importance)"
            }
        }
    }
}