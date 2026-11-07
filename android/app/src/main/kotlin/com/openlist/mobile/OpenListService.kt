package com.openlist.mobile

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Bundle
import android.os.Debug
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.Message
import android.os.Messenger
import android.os.PowerManager
import android.os.Process
import android.os.RemoteException
import android.util.Log
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.openlist.mobile.model.openlist.Logger
import com.openlist.mobile.model.openlist.OpenList
import com.openlist.mobile.model.openlist.OpenListConfigManager
import com.openlist.mobile.server.ServerSettings
import com.openlist.mobile.utils.ClipboardUtils
import com.openlist.mobile.utils.NetworkUtils
import com.openlist.mobile.utils.ToastUtils.toast
import org.json.JSONObject
import java.util.ArrayDeque
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import com.openlist.mobile.server.ServerProtocol as P

/**
 * Foreground service that hosts the OpenList core in the `:server` process.
 *
 * The core never runs in the UI process, so the server keeps working after the
 * Flutter engine or the task is gone. The UI talks to it through a [Messenger]
 * (see [P]); start/stop requests arrive as service intents. All core calls are
 * serialized on a single thread to avoid concurrent init/start/shutdown.
 */
class OpenListService : Service(), OpenList.Listener, Logger.Listener {
    companion object {
        const val TAG = "OpenListService"
        const val ACTION_START = "com.openlist.mobile.server.action.START"
        const val ACTION_STOP = "com.openlist.mobile.server.action.STOP"
        const val ACTION_RESTART = "com.openlist.mobile.server.action.RESTART"
        const val ACTION_COPY_ADDRESS = "com.openlist.mobile.server.action.COPY_ADDRESS"

        // Legacy stop action, kept for intents created by older versions.
        const val ACTION_SHUTDOWN =
            "com.openlist.openlistandroid.service.OpenListService.ACTION_SHUTDOWN"

        // Local broadcast inside the `:server` process (tile, shortcuts).
        const val ACTION_STATUS_CHANGED =
            "com.openlist.openlistandroid.service.OpenListService.ACTION_STATUS_CHANGED"

        const val NOTIFICATION_CHAN_ID = "openlist_server"
        const val FOREGROUND_ID = 5224
        private const val MAX_LOGS = 300
        private const val MAX_LOG_LENGTH = 1000
        private const val DB_SYNC_INTERVAL_MIN = 5L

        /** Core state; only meaningful inside the `:server` process. */
        @Volatile
        var isRunning = false
            private set

        /** Sends a control action. Callers handle FGS start restrictions. */
        fun sendAction(context: Context, action: String) {
            val intent = Intent(context, OpenListService::class.java).setAction(action)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }

    private val main = Handler(Looper.getMainLooper())
    private val core = Executors.newSingleThreadScheduledExecutor { Thread(it, "openlist-core") }
    private val clients = mutableListOf<Messenger>()
    private val logs = ArrayDeque<Bundle>()
    private val starting = AtomicInteger(0)
    private val messenger = Messenger(Handler(Looper.getMainLooper()) { handleMessage(it) })

    @Volatile
    private var lastError: String? = null

    @Volatile
    private var runningMode: String? = null

    @Volatile
    private var destroyed = false

    private var inForeground = false
    private var wakeLock: PowerManager.WakeLock? = null
    private var wifiLock: WifiManager.WifiLock? = null
    private var dbSyncTask: ScheduledFuture<*>? = null

    override fun onBind(intent: Intent?): IBinder = messenger.binder

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "onCreate, pid=${Process.myPid()}")
        createChannel()
        OpenList.addListener(this)
        Logger.addListener(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        Log.d(TAG, "onStartCommand: action=$action")
        // startForegroundService() requires startForeground() within the deadline,
        // even when the command turns out to be a stop.
        enterForeground()
        when {
            // Null intent: sticky restart after the process was killed.
            intent == null -> {
                val s = ServerSettings.get()
                if (s.wasRunning && !s.manuallyStopped) requestStart(false) else publishStatus()
            }

            action == ACTION_STOP || action == ACTION_SHUTDOWN -> requestStop(true)
            action == ACTION_RESTART -> requestRestart()
            action == ACTION_COPY_ADDRESS -> copyAddress()
            else -> requestStart(true)
        }
        return START_STICKY
    }

    override fun onDestroy() {
        Log.d(TAG, "onDestroy")
        destroyed = true
        OpenList.removeListener(this)
        Logger.removeListener(this)
        // Keep wasRunning so a system kill restores the server on restart.
        runCatching { core.execute { if (isRunning || OpenList.isRunning()) doStop() } }
        core.shutdown()
        main.removeCallbacksAndMessages(null)
        clients.clear()
        super.onDestroy()
    }

    // ---- Foreground state ----

    private fun enterForeground() {
        try {
            val n = buildNotification(statusBundle())
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(FOREGROUND_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
            } else {
                startForeground(FOREGROUND_ID, n)
            }
            inForeground = true
        } catch (e: Exception) {
            // e.g. ForegroundServiceStartNotAllowedException on a background sticky restart.
            Log.e(TAG, "startForeground failed", e)
            lastError = "foreground: ${e.message}"
        }
    }

    @Suppress("DEPRECATION")
    private fun leaveForeground() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            stopForeground(true)
        }
        inForeground = false
        // Drops the started state; a bound UI keeps the process alive.
        stopSelf()
    }

    // ---- Lifecycle (core thread) ----

    private fun runOnCore(block: () -> Unit) {
        if (destroyed) return
        try {
            core.execute(block)
        } catch (e: RejectedExecutionException) {
            Log.w(TAG, "Core executor is shut down", e)
        }
    }

    private fun requestStart(clearManualStop: Boolean) {
        if (clearManualStop) ServerSettings.update { it.copy(manuallyStopped = false) }
        starting.incrementAndGet()
        lastError = null
        publishStatus()
        runOnCore {
            try {
                doStart()
            } finally {
                starting.decrementAndGet()
                publishStatus()
            }
        }
    }

    private fun doStart() {
        if (isRunning && OpenList.isRunning()) return
        val mode = ServerSettings.get().mode
        try {
            OpenList.startup(mode)
            if (!OpenList.isRunning()) error(lastError ?: "core did not start")
            isRunning = true
            runningMode = mode
            ServerSettings.update { it.copy(wasRunning = true) }
            applyLocks()
            scheduleDbSync()
            Log.i(TAG, "Core started, mode=$mode")
        } catch (t: Throwable) {
            Log.e(TAG, "Failed to start core", t)
            lastError = t.message ?: t.toString()
            OpenList.shutdown()
            if (OpenList.isRunning()) {
                isRunning = true
                runningMode = mode
                ServerSettings.update { it.copy(wasRunning = true) }
                applyLocks()
                scheduleDbSync()
            } else {
                markStopped()
                ServerSettings.update { it.copy(wasRunning = false) }
            }
            toast(getString(R.string.server_start_failed, lastError))
        }
    }

    private fun requestStop(manual: Boolean) {
        runOnCore {
            val stopped = if (isRunning || OpenList.isRunning()) {
                doStop()
            } else {
                markStopped()
                ServerSettings.update { it.copy(wasRunning = false) }
                true
            }
            if (manual && stopped) {
                ServerSettings.update { it.copy(manuallyStopped = true, wasRunning = false) }
            }
            publishStatus()
        }
    }

    private fun doStop(): Boolean {
        dbSyncTask?.cancel(false)
        if (OpenList.isRunning()) OpenList.forceDatabaseSync()
        OpenList.shutdown()
        if (OpenList.isRunning()) {
            lastError = getString(R.string.shutdown_failed)
            isRunning = true
            runningMode = runningMode ?: ServerSettings.get().mode
            ServerSettings.update { it.copy(wasRunning = true) }
            applyLocks()
            scheduleDbSync()
            return false
        }
        markStopped()
        ServerSettings.update { it.copy(wasRunning = false) }
        return true
    }

    private fun requestRestart() {
        ServerSettings.update { it.copy(manuallyStopped = false) }
        starting.incrementAndGet()
        publishStatus()
        runOnCore {
            try {
                if (isRunning || OpenList.isRunning()) {
                    if (!doStop()) return@runOnCore
                }
                lastError = null
                doStart()
            } finally {
                starting.decrementAndGet()
                publishStatus()
            }
        }
    }

    private fun markStopped() {
        isRunning = false
        runningMode = null
        dbSyncTask?.cancel(false)
        dbSyncTask = null
        releaseLocks()
    }

    // Go hooks may fire on any thread.
    override fun onShutdown(type: String) {
        runOnCore {
            if (isRunning && !OpenList.isRunning()) {
                Log.w(TAG, "Core stopped unexpectedly: $type")
                markStopped()
                ServerSettings.update { it.copy(wasRunning = false) }
            }
            publishStatus()
        }
    }

    override fun onStartError(type: String, msg: String) {
        lastError = "$type: $msg"
        onShutdown(type)
    }

    // ---- Wake/Wi-Fi locks (core thread) ----

    @SuppressLint("WakelockTimeout")
    @Suppress("DEPRECATION")
    private fun applyLocks() {
        releaseLocks()
        if (!isRunning || !ServerSettings.get().wakeLock) return
        try {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "openlist::server")
                .apply { setReferenceCounted(false); acquire() }
            // Keeps the Wi-Fi radio awake for LAN clients; HIGH_PERF is a no-op on 34+.
            if (runningMode != ServerSettings.MODE_LOCAL &&
                Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE
            ) {
                val wm = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                wifiLock = wm.createWifiLock(WifiManager.WIFI_MODE_FULL_HIGH_PERF, "openlist::server")
                    .apply { setReferenceCounted(false); acquire() }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to acquire locks", e)
        }
    }

    private fun releaseLocks() {
        runCatching { wakeLock?.takeIf { it.isHeld }?.release() }
        runCatching { wifiLock?.takeIf { it.isHeld }?.release() }
        wakeLock = null
        wifiLock = null
    }

    private fun scheduleDbSync() {
        dbSyncTask?.cancel(false)
        dbSyncTask = core.scheduleWithFixedDelay({
            if (isRunning && OpenList.isRunning()) OpenList.forceDatabaseSync()
        }, DB_SYNC_INTERVAL_MIN, DB_SYNC_INTERVAL_MIN, TimeUnit.MINUTES)
    }

    // ---- Status ----

    private fun statusBundle(): Bundle {
        val settings = ServerSettings.get()
        val mode = runningMode ?: settings.mode
        val scheme = OpenListConfigManager.configOrNull()?.scheme
        return Bundle().apply {
            putBoolean(P.KEY_RUNNING, isRunning)
            putBoolean(P.KEY_STARTING, starting.get() > 0)
            putString(P.KEY_MODE, mode)
            putInt(P.KEY_HTTP_PORT, scheme?.httpPort ?: 5244)
            putInt(P.KEY_HTTPS_PORT, scheme?.httpsPort ?: -1)
            putBoolean(P.KEY_FORCE_HTTPS, scheme?.forceHttps ?: false)
            putStringArrayList(P.KEY_ADDRESSES, ArrayList(addresses(mode, scheme?.address)))
            putBoolean(P.KEY_MANUALLY_STOPPED, settings.manuallyStopped)
            lastError?.let { putString(P.KEY_LAST_ERROR, it) }
        }
    }

    private fun addresses(mode: String, configured: String?): List<String> {
        if (mode == ServerSettings.MODE_LOCAL) return listOf("127.0.0.1")
        // A pinned interface address in config.json is the only reachable host.
        val pinned = configured?.takeIf { it.isNotBlank() && it != "0.0.0.0" && it != "::" }
        if (pinned != null) return listOf(pinned)
        return NetworkUtils.localIPv4Addresses() + "127.0.0.1"
    }

    private fun primaryUrl(s: Bundle): String {
        val host = s.getStringArrayList(P.KEY_ADDRESSES)?.firstOrNull() ?: "127.0.0.1"
        val httpsPort = s.getInt(P.KEY_HTTPS_PORT)
        val httpPort = s.getInt(P.KEY_HTTP_PORT)
        return if (httpsPort > 0 && (s.getBoolean(P.KEY_FORCE_HTTPS) || httpPort <= 0)) {
            "https://$host:$httpsPort"
        } else {
            "http://$host:$httpPort"
        }
    }

    private fun publishStatus() {
        if (destroyed) return
        main.post {
            if (destroyed) return@post
            val s = statusBundle()
            broadcast(P.MSG_STATUS, s)
            LocalBroadcastManager.getInstance(this).sendBroadcast(Intent(ACTION_STATUS_CHANGED))
            if (isRunning || starting.get() > 0) {
                val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                if (inForeground) nm.notify(FOREGROUND_ID, buildNotification(s)) else enterForeground()
            } else {
                leaveForeground()
            }
        }
    }

    // ---- Notification ----

    private fun servicePendingIntent(action: String, requestCode: Int): PendingIntent {
        val intent = Intent(this, OpenListService::class.java).setAction(action)
        return PendingIntent.getService(this, requestCode, intent, pendingIntentFlags())
    }

    private fun pendingIntentFlags(): Int {
        val immutable = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE
        } else {
            0
        }
        return immutable or PendingIntent.FLAG_UPDATE_CURRENT
    }

    @Suppress("DEPRECATION")
    private fun buildNotification(s: Bundle): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, NOTIFICATION_CHAN_ID)
        } else {
            Notification.Builder(this)
        }
        val running = s.getBoolean(P.KEY_RUNNING)
        val title = if (running) {
            getString(R.string.openlist_server_running)
        } else {
            getString(R.string.openlist_starting)
        }
        val mode = modeLabel(s.getString(P.KEY_MODE))
        val text = if (running) "$mode · ${primaryUrl(s)}" else mode
        val openApp = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java), pendingIntentFlags()
        )
        builder
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) R.drawable.server
                else R.mipmap.ic_launcher_round
            )
            .setContentIntent(openApp)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .addAction(0, getString(R.string.shutdown), servicePendingIntent(ACTION_STOP, 1))
        if (running) {
            builder.addAction(
                0, getString(R.string.copy_address), servicePendingIntent(ACTION_COPY_ADDRESS, 2)
            )
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
        }
        return builder.build()
    }

    private fun modeLabel(mode: String?) = getString(
        when (mode) {
            ServerSettings.MODE_LAN -> R.string.server_mode_lan
            ServerSettings.MODE_PUBLIC -> R.string.server_mode_public
            else -> R.string.server_mode_local
        }
    )

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val chan = NotificationChannel(
            NOTIFICATION_CHAN_ID,
            getString(R.string.openlist_server),
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            lockscreenVisibility = Notification.VISIBILITY_PRIVATE
            setShowBadge(false)
        }
        (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
            .createNotificationChannel(chan)
    }

    private fun copyAddress() {
        val url = primaryUrl(statusBundle())
        ClipboardUtils.copyText("OpenList", url)
        toast(R.string.address_copied)
        publishStatus()
    }

    // ---- Messenger IPC (main thread) ----

    private fun handleMessage(msg: Message): Boolean {
        val to = msg.replyTo
        val id = msg.arg1
        // Message is recycled after return; copy what async work needs.
        val data = Bundle(msg.data)
        when (msg.what) {
            P.MSG_REGISTER -> to?.let {
                if (it !in clients) clients.add(it)
                send(it, Message.obtain(null, P.MSG_STATUS).apply { this.data = statusBundle() })
            }

            P.MSG_UNREGISTER -> to?.let { clients.remove(it) }
            P.MSG_GET_STATUS -> reply(to, id, statusBundle())
            P.MSG_GET_LOGS -> reply(to, id, logsBundle())

            P.MSG_SET_ADMIN_PASSWORD -> onCore(to, id) {
                val pwd = data.getString(P.KEY_PASSWORD).orEmpty()
                require(pwd.isNotBlank()) { "password is empty" }
                OpenList.setAdminPassword(pwd)
                ""
            }

            P.MSG_GET_TOKEN -> onCore(to, id) {
                check(isRunning) { "server is not running" }
                OpenList.adminToken()
            }

            P.MSG_GET_RUNTIME -> onCore(to, id) { runtimeJson() }
            P.MSG_GET_SECURITY -> onCore(to, id) {
                OpenList.securityReport(ServerSettings.normalizeMode(data.getString(P.KEY_MODE)))
            }

            P.MSG_SYNC_DB -> runOnCore { if (isRunning) OpenList.forceDatabaseSync() }
            P.MSG_REFRESH_SETTINGS -> runOnCore {
                applyLocks()
                publishStatus()
            }

            else -> return false
        }
        return true
    }

    /** Runs [block] on the core thread and replies with its result or error. */
    private fun onCore(to: Messenger?, id: Int, block: () -> String) {
        if (destroyed) {
            reply(to, id, Bundle().apply { putString(P.KEY_ERROR, "service destroyed") })
            return
        }
        runOnCore {
            val b = Bundle()
            try {
                b.putString(P.KEY_RESULT, block())
            } catch (t: Throwable) {
                Log.e(TAG, "Request failed", t)
                b.putString(P.KEY_ERROR, t.message ?: t.toString())
            }
            reply(to, id, b)
        }
    }

    private fun reply(to: Messenger?, id: Int, data: Bundle) {
        to ?: return
        send(to, Message.obtain(null, P.MSG_REPLY, id, 0).apply { this.data = data })
    }

    private fun send(to: Messenger, msg: Message) {
        try {
            to.send(msg)
        } catch (e: RemoteException) {
            Log.w(TAG, "Client is gone", e)
            main.post { clients.remove(to) }
        }
    }

    private fun broadcast(what: Int, data: Bundle) {
        main.post {
            clients.toList().forEach {
                send(it, Message.obtain(null, what).apply { this.data = Bundle(data) })
            }
        }
    }

    // ---- Logs ----

    override fun onLog(level: Int, time: String, msg: String) {
        val entry = Bundle().apply {
            putInt(P.KEY_LEVEL, level)
            putString(P.KEY_TIME, time)
            putString(P.KEY_MESSAGE, msg.take(MAX_LOG_LENGTH))
        }
        synchronized(logs) {
            logs.addLast(entry)
            while (logs.size > MAX_LOGS) logs.removeFirst()
        }
        broadcast(P.MSG_LOG, entry)
    }

    private fun logsBundle(): Bundle {
        val snapshot = synchronized(logs) { logs.toList() }
        return Bundle().apply {
            putIntArray(P.KEY_LEVELS, snapshot.map { it.getInt(P.KEY_LEVEL) }.toIntArray())
            putStringArrayList(P.KEY_TIMES, ArrayList(snapshot.map { it.getString(P.KEY_TIME).orEmpty() }))
            putStringArrayList(
                P.KEY_MESSAGES, ArrayList(snapshot.map { it.getString(P.KEY_MESSAGE).orEmpty() })
            )
        }
    }

    /** Go runtime status merged with Android process resource usage. */
    private fun runtimeJson(): String {
        val o = if (isRunning) JSONObject(OpenList.runtimeStatus()) else JSONObject().put("running", false)
        val mem = Debug.MemoryInfo().also { Debug.getMemoryInfo(it) }
        return o.put("pid", Process.myPid())
            .put("pss_kb", mem.totalPss)
            .put("cpu_time_ms", Process.getElapsedCpuTime())
            .toString()
    }
}
