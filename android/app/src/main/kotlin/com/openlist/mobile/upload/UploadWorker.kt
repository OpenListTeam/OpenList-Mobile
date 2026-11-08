package com.openlist.mobile.upload

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.text.format.Formatter
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.Data
import androidx.work.ForegroundInfo
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import com.openlist.mobile.MainActivity
import com.openlist.mobile.OpenListService
import com.openlist.mobile.R
import com.openlist.mobile.upload.UploadCredentials
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.io.IOException
import java.io.InputStream
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import javax.net.ssl.HttpsURLConnection
import javax.net.ssl.SSLException

/**
 * Streams one local file to an HTTP endpoint as a foreground WorkManager job.
 *
 * Runs in the UI process only (WorkManager is not initialized in `:server`).
 * The body is sent in fixed-length streaming mode, so the file is never
 * buffered in memory. The response status and body are returned as output
 * data; deciding success from the OpenList envelope is left to Dart.
 * HTTPS to loopback is pinned to the core's certificate ([LoopbackTls]).
 */
class UploadWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    companion object {
        private const val TAG = "UploadWorker"
        const val KEY_URL = "url"
        const val KEY_METHOD = "method"
        const val KEY_FILE = "file"
        const val KEY_TITLE = "title"

        /** Flattened header pairs: name0, value0, name1, value1, ... */
        const val KEY_HEADERS = "headers"
        const val KEY_CREDENTIAL_ID = "credential_id"
        const val KEY_SENT = "sent"
        const val KEY_TOTAL = "total"
        const val KEY_STATUS = "status"
        const val KEY_BODY = "body"
        const val KEY_ERROR = "error"
        const val TAG_UPLOAD = "openlist_upload"

        private const val CHANNEL_ID = "openlist_upload"
        private const val BUFFER_SIZE = 64 * 1024
        private const val PROGRESS_INTERVAL_MS = 250L
        private const val NOTIFY_INTERVAL_MS = 1000L

        // WorkManager output Data is capped at 10 KB; envelopes are far smaller.
        const val MAX_BODY_CHARS = 2000
        private const val MAX_ERROR_CHARS = 500
        private const val CONNECT_TIMEOUT_MS = 10_000
        private const val READ_TIMEOUT_MS = 60_000
    }

    // Notification ids are per package, so avoid the server's foreground id.
    private val notificationId =
        id.hashCode().let { if (it == OpenListService.FOREGROUND_ID) it + 1 else it }
    private val title = inputData.getString(KEY_TITLE).orEmpty()
    private var inForeground = false

    override suspend fun doWork(): Result {
        val credentialId = inputData.getString(KEY_CREDENTIAL_ID)
        var keepCredentials = false
        return try {
            val url = inputData.getString(KEY_URL)
            val path = inputData.getString(KEY_FILE)
            if (url.isNullOrEmpty() || path.isNullOrEmpty()) return fail("invalid upload request")
            val file = File(path)
            if (!file.isFile) return fail("file not found")
            val total = file.length()
            setProgress(progressData(0, total))
            createChannel()
            enterForeground(0, total)
            transfer(url, file, total)
        } catch (e: CancellationException) {
            keepCredentials = true
            throw e
        } catch (e: IOException) {
            if (isStopped) keepCredentials = true
            fail(e.message ?: e.javaClass.simpleName)
        } finally {
            if (!keepCredentials) {
                credentialId?.let { UploadCredentials.delete(applicationContext, it) }
            }
        }
    }

    private suspend fun enterForeground(sent: Long, total: Long) {
        try {
            setForeground(foregroundInfo(sent, total))
            inForeground = true
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            // Android 12+ refuses foreground starts from the background; the
            // job still runs as regular background work.
            Log.w(TAG, "setForeground failed: ${e.message}")
        }
    }

    /** Sends the request; cancelling the coroutine closes the socket. */
    private suspend fun transfer(url: String, file: File, total: Long): Result = coroutineScope {
        val conn = URL(url).openConnection() as HttpURLConnection
        val abort = launch {
            try {
                awaitCancellation()
            } finally {
                conn.disconnect()
            }
        }
        try {
            withContext(Dispatchers.IO) { secure(conn) { send(conn, file, total) } }
        } finally {
            abort.cancel()
        }
    }

    /**
     * Pins loopback HTTPS to the embedded core's certificate; any other URL
     * keeps the system trust. Throws [IOException] if the pin cannot be set.
     */
    private fun <T> secure(conn: HttpURLConnection, block: () -> T): T {
        if (conn !is HttpsURLConnection || !LoopbackTls.isLoopbackHost(conn.url.host)) return block()
        var rejected: String? = null
        LoopbackTls.pin(conn) { rejected = it }
        return try {
            block()
        } catch (e: SSLException) {
            // Report the pin mismatch rather than a generic handshake error.
            throw rejected?.let { IOException(it, e) } ?: e
        }
    }

    private fun send(conn: HttpURLConnection, file: File, total: Long): Result {
        conn.requestMethod = inputData.getString(KEY_METHOD) ?: "PUT"
        conn.doOutput = true
        conn.instanceFollowRedirects = false
        conn.connectTimeout = CONNECT_TIMEOUT_MS
        conn.readTimeout = READ_TIMEOUT_MS
        conn.setFixedLengthStreamingMode(total)
        val credentialId = inputData.getString(KEY_CREDENTIAL_ID)
        val headers = headers() + credentialId?.let { UploadCredentials.read(applicationContext, it) }.orEmpty()
        headers.forEach { (name, value) -> conn.setRequestProperty(name, value) }

        var sent = 0L
        var lastProgress = 0L
        var lastNotify = 0L
        file.inputStream().use { input ->
            conn.outputStream.use { output ->
                val buf = ByteArray(BUFFER_SIZE)
                while (true) {
                    if (isStopped) throw IOException("canceled")
                    val n = input.read(buf)
                    if (n < 0) break
                    output.write(buf, 0, n)
                    sent += n
                    val now = System.currentTimeMillis()
                    if (now - lastProgress >= PROGRESS_INTERVAL_MS) {
                        lastProgress = now
                        setProgressAsync(progressData(sent, total))
                    }
                    if (inForeground && now - lastNotify >= NOTIFY_INTERVAL_MS) {
                        lastNotify = now
                        setForegroundAsync(foregroundInfo(sent, total))
                    }
                }
            }
        }

        val status = conn.responseCode
        val stream: InputStream? = if (status >= 400) conn.errorStream else conn.inputStream
        val body = stream?.let { readCapped(it) } ?: ""
        if (body.length > MAX_BODY_CHARS) return fail("response too large (HTTP $status)")
        conn.disconnect()
        return Result.success(
            Data.Builder()
                .putLong(KEY_SENT, sent)
                .putLong(KEY_TOTAL, total)
                .putInt(KEY_STATUS, status)
                .putString(KEY_BODY, body)
                .build()
        )
    }

    /** Reads at most one char past the cap so oversized bodies are detectable. */
    private fun readCapped(stream: InputStream): String =
        InputStreamReader(stream, Charsets.UTF_8).use { reader ->
            val out = StringBuilder()
            val buf = CharArray(1024)
            while (out.length <= MAX_BODY_CHARS) {
                val n = reader.read(buf)
                if (n < 0) break
                out.append(buf, 0, n)
            }
            out.toString()
        }

    private fun headers(): List<Pair<String, String>> {
        val flat = inputData.getStringArray(KEY_HEADERS) ?: return emptyList()
        return (0 until flat.size / 2)
            .map { flat[it * 2] to flat[it * 2 + 1] }
            .filterNot { it.first.equals("Content-Length", ignoreCase = true) }
    }

    private fun progressData(sent: Long, total: Long) =
        Data.Builder().putLong(KEY_SENT, sent).putLong(KEY_TOTAL, total).build()

    private fun fail(message: String): Result =
        Result.failure(Data.Builder().putString(KEY_ERROR, message.take(MAX_ERROR_CHARS)).build())

    private fun foregroundInfo(sent: Long, total: Long): ForegroundInfo {
        val n = notification(sent, total)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ForegroundInfo(notificationId, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            ForegroundInfo(notificationId, n)
        }
    }

    private fun notification(sent: Long, total: Long): Notification {
        val ctx = applicationContext
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(ctx, CHANNEL_ID)
        } else {
            Notification.Builder(ctx)
        }
        val immutable = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE
        } else {
            0
        }
        val openApp = PendingIntent.getActivity(
            ctx, 0, Intent(ctx, MainActivity::class.java), immutable or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val cancel = WorkManager.getInstance(ctx).createCancelPendingIntent(id)
        val percent = if (total > 0) (sent * 100 / total).toInt().coerceIn(0, 100) else 0
        return builder
            .setContentTitle(ctx.getString(R.string.upload_notification_title, title))
            .setContentText(
                ctx.getString(
                    R.string.upload_notification_progress,
                    Formatter.formatShortFileSize(ctx, sent),
                    Formatter.formatShortFileSize(ctx, total)
                )
            )
            .setSmallIcon(android.R.drawable.stat_sys_upload)
            .setContentIntent(openApp)
            .setProgress(100, percent, total <= 0)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .addAction(0, ctx.getString(R.string.cancel), cancel)
            .build()
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val chan = NotificationChannel(
            CHANNEL_ID,
            applicationContext.getString(R.string.upload_notification_channel),
            NotificationManager.IMPORTANCE_LOW
        ).apply { setShowBadge(false) }
        (applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
            .createNotificationChannel(chan)
    }
}
