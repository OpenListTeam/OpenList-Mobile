package com.openlist.mobile.utils

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Build
import android.util.Log
import com.openlist.mobile.OpenListService
import com.openlist.mobile.config.AppConfig
import kotlinx.coroutines.*

/**
 * 网络监听器 - 监听网络状态变化，在网络恢复时确保服务正常运行
 */
class NetworkMonitor(private val context: Context) {
    companion object {
        private const val TAG = "NetworkMonitor"
    }

    private var connectivityManager: ConnectivityManager? = null
    private var networkCallback: ConnectivityManager.NetworkCallback? = null
    private var monitorScope: CoroutineScope? = null
    private var isMonitoring = false

    /**
     * 开始网络监听
     */
    fun startMonitoring() {
        if (isMonitoring) {
            Log.d(TAG, "Network monitoring already started")
            return
        }

        try {
            connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            monitorScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                // Android 7.0+ 使用 NetworkCallback
                setupNetworkCallback()
            } else {
                // 低版本使用轮询方式
                setupPollingMonitor()
            }

            isMonitoring = true
            Log.d(TAG, "Network monitoring started")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start network monitoring", e)
        }
    }

    /**
     * 停止网络监听
     */
    fun stopMonitoring() {
        if (!isMonitoring) {
            return
        }

        try {
            // 取消网络回调
            networkCallback?.let { callback ->
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    connectivityManager?.unregisterNetworkCallback(callback)
                }
            }

            // 取消协程
            monitorScope?.cancel()

            isMonitoring = false
            Log.d(TAG, "Network monitoring stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop network monitoring", e)
        }
    }

    /**
     * 设置网络回调 (Android 7.0+)
     */
    private fun setupNetworkCallback() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return

        try {
            networkCallback = object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: Network) {
                    super.onAvailable(network)
                    Log.d(TAG, "Network available: $network")
                    onNetworkConnected()
                }

                override fun onLost(network: Network) {
                    super.onLost(network)
                    Log.d(TAG, "Network lost: $network")
                    onNetworkDisconnected()
                }

                override fun onCapabilitiesChanged(
                    network: Network,
                    networkCapabilities: NetworkCapabilities
                ) {
                    super.onCapabilitiesChanged(network, networkCapabilities)
                    Log.d(TAG, "Network capabilities changed: $network")
                    
                    // 检查网络是否真正可用
                    val hasInternet = networkCapabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                    val isValidated = networkCapabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
                    
                    if (hasInternet && isValidated) {
                        onNetworkConnected()
                    }
                }
            }

            val networkRequest = NetworkRequest.Builder()
                .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                .build()

            connectivityManager?.registerNetworkCallback(networkRequest, networkCallback!!)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to setup network callback", e)
        }
    }

    /**
     * 设置轮询监听 (Android 7.0以下)
     */
    private fun setupPollingMonitor() {
        monitorScope?.launch {
            var wasConnected = isNetworkConnected()
            
            while (isActive && isMonitoring) {
                try {
                    val isConnected = isNetworkConnected()
                    
                    if (isConnected && !wasConnected) {
                        // 网络从断开变为连接
                        Log.d(TAG, "Network connected (polling)")
                        onNetworkConnected()
                    } else if (!isConnected && wasConnected) {
                        // 网络从连接变为断开
                        Log.d(TAG, "Network disconnected (polling)")
                        onNetworkDisconnected()
                    }
                    
                    wasConnected = isConnected
                    delay(5000) // 每5秒检查一次
                } catch (e: Exception) {
                    Log.e(TAG, "Error in polling monitor", e)
                    delay(10000) // 出错时等待10秒
                }
            }
        }
    }

    /**
     * 网络连接时的处理
     */
    private fun onNetworkConnected() {
        monitorScope?.launch {
            try {
                // 延迟一段时间确保网络稳定
                delay(2000)
                
                // 检查是否被用户手动停止
                if (AppConfig.isManuallyStoppedByUser) {
                    Log.d(TAG, "Service was manually stopped by user, skipping network restart")
                    return@launch
                }
                
                if (!AppConfig.isStartAtBootEnabled) {
                    Log.d(TAG, "Auto start disabled, skipping service check")
                    return@launch
                }

                // 检查服务状态
                if (!OpenListService.isRunning) {
                    Log.w(TAG, "Network connected but service not running, restarting service")
                    restartService()
                } else {
                    Log.d(TAG, "Network connected and service is running")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error handling network connected", e)
            }
        }
    }

    /**
     * 网络断开时的处理
     */
    private fun onNetworkDisconnected() {
        Log.d(TAG, "Network disconnected, service may be affected")
        // 网络断开时暂时不做特殊处理，等待网络恢复
    }

    /**
     * 检查网络是否连接
     */
    private fun isNetworkConnected(): Boolean {
        return try {
            val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val network = connectivityManager.activeNetwork ?: return false
                val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return false
                
                capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
                capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
            } else {
                @Suppress("DEPRECATION")
                val networkInfo = connectivityManager.activeNetworkInfo
                networkInfo?.isConnected == true
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to check network connection", e)
            false
        }
    }

    /**
     * 重启服务
     */
    private fun restartService() {
        try {
            val intent = android.content.Intent(context, OpenListService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
            Log.d(TAG, "Service restart command sent")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to restart service", e)
        }
    }

    /**
     * 获取当前网络状态信息
     */
    fun getNetworkInfo(): NetworkInfo {
        return try {
            val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val network = connectivityManager.activeNetwork
                val capabilities = connectivityManager.getNetworkCapabilities(network)
                
                NetworkInfo(
                    isConnected = capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true,
                    isValidated = capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED) == true,
                    networkType = getNetworkType(capabilities),
                    isMetered = capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED) == false
                )
            } else {
                @Suppress("DEPRECATION")
                val networkInfo = connectivityManager.activeNetworkInfo
                
                NetworkInfo(
                    isConnected = networkInfo?.isConnected == true,
                    isValidated = networkInfo?.isConnected == true,
                    networkType = networkInfo?.typeName ?: "Unknown",
                    isMetered = connectivityManager.isActiveNetworkMetered
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get network info", e)
            NetworkInfo(false, false, "Unknown", false)
        }
    }

    /**
     * 获取网络类型
     */
    private fun getNetworkType(capabilities: NetworkCapabilities?): String {
        return when {
            capabilities == null -> "None"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "WiFi"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "Cellular"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "Ethernet"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_BLUETOOTH) -> "Bluetooth"
            else -> "Unknown"
        }
    }

    /**
     * 网络信息数据类
     */
    data class NetworkInfo(
        val isConnected: Boolean,
        val isValidated: Boolean,
        val networkType: String,
        val isMetered: Boolean
    )
}