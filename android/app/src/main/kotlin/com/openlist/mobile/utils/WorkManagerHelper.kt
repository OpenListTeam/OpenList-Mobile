package com.openlist.mobile.utils

import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.work.*
import com.openlist.mobile.KeepAliveService
import com.openlist.mobile.OpenListService
import com.openlist.mobile.config.AppConfig
import java.util.concurrent.TimeUnit

/**
 * WorkManager助手类 - 使用WorkManager实现更可靠的后台任务调度
 */
object WorkManagerHelper {
    private const val TAG = "WorkManagerHelper"
    private const val KEEP_ALIVE_WORK_NAME = "openlist_keep_alive"
    private const val SERVICE_CHECK_WORK_NAME = "openlist_service_check"

    /**
     * 初始化WorkManager任务
     */
    fun initialize(context: Context) {
        try {
            if (!AppConfig.isStartAtBootEnabled) {
                Log.d(TAG, "Auto start disabled, skipping WorkManager setup")
                return
            }

            // 设置保��任务
            setupKeepAliveWork(context)
            
            // 设置服务检查任务
            setupServiceCheckWork(context)
            
            Log.d(TAG, "WorkManager tasks initialized")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize WorkManager", e)
        }
    }

    /**
     * 设置保活任务
     */
    private fun setupKeepAliveWork(context: Context) {
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.NOT_REQUIRED)
            .setRequiresBatteryNotLow(false)
            .setRequiresCharging(false)
            .setRequiresDeviceIdle(false)
            .setRequiresStorageNotLow(false)
            .build()

        val keepAliveRequest = PeriodicWorkRequestBuilder<KeepAliveWorker>(
            15, TimeUnit.MINUTES, // 每15分钟执行一次
            5, TimeUnit.MINUTES   // 允许5分钟的弹性时间
        )
            .setConstraints(constraints)
            .setBackoffCriteria(
                BackoffPolicy.LINEAR,
                WorkRequest.MIN_BACKOFF_MILLIS,
                TimeUnit.MILLISECONDS
            )
            .build()

        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            KEEP_ALIVE_WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            keepAliveRequest
        )

        Log.d(TAG, "Keep alive work scheduled")
    }

    /**
     * 设置服务检查任务
     */
    private fun setupServiceCheckWork(context: Context) {
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.NOT_REQUIRED)
            .build()

        val serviceCheckRequest = PeriodicWorkRequestBuilder<ServiceCheckWorker>(
            30, TimeUnit.MINUTES, // 每30分钟检查一次
            10, TimeUnit.MINUTES  // 允许10分钟的弹性时间
        )
            .setConstraints(constraints)
            .build()

        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            SERVICE_CHECK_WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            serviceCheckRequest
        )

        Log.d(TAG, "Service check work scheduled")
    }

    /**
     * 取消所有任务
     */
    fun cancelAllWork(context: Context) {
        try {
            WorkManager.getInstance(context).cancelUniqueWork(KEEP_ALIVE_WORK_NAME)
            WorkManager.getInstance(context).cancelUniqueWork(SERVICE_CHECK_WORK_NAME)
            Log.d(TAG, "All work cancelled")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to cancel work", e)
        }
    }

    /**
     * 保活Worker
     */
    class KeepAliveWorker(
        context: Context,
        params: WorkerParameters
    ) : Worker(context, params) {

        override fun doWork(): Result {
            return try {
                Log.d(TAG, "KeepAliveWorker executing")

                // 检查是否被用户手动停止
                if (AppConfig.isManuallyStoppedByUser) {
                    Log.d(TAG, "Service was manually stopped by user, skipping keep alive")
                    return Result.success()
                }

                if (!AppConfig.isStartAtBootEnabled) {
                    Log.d(TAG, "Auto start disabled, skipping keep alive")
                    return Result.success()
                }

                // 启动保活服务
                val keepAliveIntent = Intent(applicationContext, KeepAliveService::class.java)
                applicationContext.startService(keepAliveIntent)

                // 检查主服务状态
                if (!OpenListService.isRunning) {
                    Log.w(TAG, "Main service not running, attempting to start")
                    val mainServiceIntent = Intent(applicationContext, OpenListService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        applicationContext.startForegroundService(mainServiceIntent)
                    } else {
                        applicationContext.startService(mainServiceIntent)
                    }
                }

                Log.d(TAG, "KeepAliveWorker completed successfully")
                Result.success()
            } catch (e: Exception) {
                Log.e(TAG, "KeepAliveWorker failed", e)
                Result.retry()
            }
        }
    }

    /**
     * 服务检查Worker
     */
    class ServiceCheckWorker(
        context: Context,
        params: WorkerParameters
    ) : Worker(context, params) {

        override fun doWork(): Result {
            return try {
                Log.d(TAG, "ServiceCheckWorker executing")

                // 检查是否被用户手动停止
                if (AppConfig.isManuallyStoppedByUser) {
                    Log.d(TAG, "Service was manually stopped by user, skipping service check")
                    return Result.success()
                }

                if (!AppConfig.isStartAtBootEnabled) {
                    Log.d(TAG, "Auto start disabled, skipping service check")
                    return Result.success()
                }

                // 检查服务状态并尝试恢复
                checkAndRecoverServices()

                Log.d(TAG, "ServiceCheckWorker completed successfully")
                Result.success()
            } catch (e: Exception) {
                Log.e(TAG, "ServiceCheckWorker failed", e)
                Result.retry()
            }
        }

        private fun checkAndRecoverServices() {
            try {
                // 检查主服务
                if (!OpenListService.isRunning) {
                    Log.w(TAG, "Main service not running, restarting...")
                    val intent = Intent(applicationContext, OpenListService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        applicationContext.startForegroundService(intent)
                    } else {
                        applicationContext.startService(intent)
                    }
                }

                // 确保保活服务运行
                val keepAliveIntent = Intent(applicationContext, KeepAliveService::class.java)
                applicationContext.startService(keepAliveIntent)

            } catch (e: Exception) {
                Log.e(TAG, "Failed to recover services", e)
            }
        }
    }
}