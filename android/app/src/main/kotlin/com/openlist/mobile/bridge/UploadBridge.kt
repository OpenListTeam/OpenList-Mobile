package com.openlist.mobile.bridge

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.lifecycle.Observer
import androidx.work.Data
import androidx.work.OneTimeWorkRequest
import androidx.work.Operation
import androidx.work.WorkInfo
import androidx.work.WorkManager
import com.openlist.mobile.upload.UploadCredentials
import com.openlist.mobile.upload.UploadWorker
import com.openlist.pigeon.GeneratedApi
import java.util.UUID
import java.util.concurrent.Executor

/**
 * Hands uploads to WorkManager and forwards each job's [WorkInfo] to Dart.
 * Pigeon host calls and LiveData callbacks both run on the main thread.
 */
class UploadBridge(private val context: Context, private val events: GeneratedApi.UploadEventApi) : GeneratedApi.UploadApi {
    companion object {
        private const val TAG = "UploadBridge"
    }

    private val workManager = WorkManager.getInstance(context.applicationContext)

    /** Removes the WorkInfo observer of each tracked job. */
    private val observers = mutableMapOf<UUID, () -> Unit>()
    private val credentialIds = mutableMapOf<UUID, String>()

    /** Runs future listeners on the main thread, like the other callbacks here. */
    private val mainHandler = Handler(Looper.getMainLooper())
    private val mainExecutor = Executor { mainHandler.post(it) }

    private val ignoreResult = object : GeneratedApi.VoidResult {
        override fun success() {}
        override fun error(error: Throwable) {}
    }

    override fun enqueue(request: GeneratedApi.UploadRequest): String {
        val sensitiveHeaders = request.headers.filterKeys {
            it.equals("Authorization", ignoreCase = true) || it.equals("Password", ignoreCase = true)
        }
        val credentialId = if (sensitiveHeaders.isEmpty()) null else UploadCredentials.store(context, sensitiveHeaders)
        val headers = request.headers.filterKeys {
            !it.equals("Authorization", ignoreCase = true) && !it.equals("Password", ignoreCase = true)
        }.flatMap { listOf(it.key, it.value) }.toTypedArray()
        val input = Data.Builder()
            .putString(UploadWorker.KEY_URL, request.url)
            .putString(UploadWorker.KEY_METHOD, request.method)
            .putString(UploadWorker.KEY_FILE, request.filePath)
            .putString(UploadWorker.KEY_TITLE, request.title)
            .putStringArray(UploadWorker.KEY_HEADERS, headers)
        credentialId?.let {
            input.putString(UploadWorker.KEY_CREDENTIAL_ID, it)
        }
        val workData = input.build()
        val work = OneTimeWorkRequest.Builder(UploadWorker::class.java)
            .setInputData(workData)
            .addTag(UploadWorker.TAG_UPLOAD)
            .build()
        val id = work.id
        credentialId?.let { credentialIds[id] = it }
        observe(id)
        watchEnqueue(id, workManager.enqueue(work))
        return id.toString()
    }

    override fun cancel(id: String) {
        val uuid = runCatching { UUID.fromString(id) }.getOrNull() ?: return
        workManager.cancelWorkById(uuid)
    }

    /**
     * Reports the stored WorkInfo of each id and re-observes unfinished jobs.
     * Ids WorkManager no longer has (pruned or never stored) are left out.
     */
    override fun restore(ids: List<String>, result: GeneratedApi.Result<List<GeneratedApi.UploadEvent>>) {
        val uuids = ids.mapNotNull { runCatching { UUID.fromString(it) }.getOrNull() }.distinct()
        if (uuids.isEmpty()) {
            result.success(emptyList())
            return
        }
        val events = mutableListOf<GeneratedApi.UploadEvent>()
        var pending = uuids.size
        var failed = false
        uuids.forEach { id ->
            val future = workManager.getWorkInfoById(id)
            future.addListener({
                if (failed) return@addListener
                val info = try {
                    future.get()
                } catch (e: Exception) {
                    failed = true
                    Log.w(TAG, "restore failed: ${e.message}")
                    result.error(e)
                    return@addListener
                }
                if (info != null) {
                    events.add(toEvent(info))
                    if (!info.state.isFinished && !observers.containsKey(id)) observe(id)
                    if (info.state.isFinished) {
                        info.inputData.getString(UploadWorker.KEY_CREDENTIAL_ID)?.let {
                            UploadCredentials.delete(context, it)
                        }
                    }
                }
                if (--pending == 0) result.success(events)
            }, mainExecutor)
        }
    }

    fun dispose() {
        observers.values.toList().forEach { it() }
        observers.clear()
        credentialIds.clear()
    }

    private fun observe(id: UUID) {
        val live = workManager.getWorkInfoByIdLiveData(id)
        // LiveData yields null until the request is stored.
        val observer = Observer<WorkInfo?> { info ->
            if (info == null) return@Observer
            events.onUploadEvent(toEvent(info), ignoreResult)
            if (info.state.isFinished) {
                info.inputData.getString(UploadWorker.KEY_CREDENTIAL_ID)?.let {
                    UploadCredentials.delete(context, it)
                }
                credentialIds.remove(id)
                stopObserving(id)
            }
        }
        observers[id] = { live.removeObserver(observer) }
        live.observeForever(observer)
    }

    private fun inputCredentialId(id: UUID): String? = credentialIds[id]

    private fun stopObserving(id: UUID) {
        observers.remove(id)?.invoke()
    }

    /** An enqueue that fails (e.g. input Data over 10 KB) never produces a WorkInfo. */
    private fun watchEnqueue(id: UUID, op: Operation) {
        val state = op.state
        state.observeForever(object : Observer<Operation.State?> {
            override fun onChanged(value: Operation.State?) {
                when (value) {
                    is Operation.State.SUCCESS -> state.removeObserver(this)
                    is Operation.State.FAILURE -> {
                        state.removeObserver(this)
                        Log.w(TAG, "enqueue failed: ${value.throwable.message}")
                        inputCredentialId(id)?.let { UploadCredentials.delete(context, it) }
                        credentialIds.remove(id)
                        stopObserving(id)
                        events.onUploadEvent(
                            event(id, GeneratedApi.UploadEventState.FAILED, 0, 0)
                                .setError(value.throwable.message ?: "enqueue failed")
                                .build(),
                            ignoreResult
                        )
                    }

                    else -> {}
                }
            }
        })
    }

    private fun toEvent(info: WorkInfo): GeneratedApi.UploadEvent {
        val out = info.outputData
        return when (info.state) {
            WorkInfo.State.SUCCEEDED -> event(
                info.id, GeneratedApi.UploadEventState.COMPLETED,
                out.getLong(UploadWorker.KEY_SENT, 0), out.getLong(UploadWorker.KEY_TOTAL, 0)
            )
                .setHttpStatus(out.getInt(UploadWorker.KEY_STATUS, 0).toLong())
                .setBody(out.getString(UploadWorker.KEY_BODY))
                .build()

            WorkInfo.State.FAILED -> event(info.id, GeneratedApi.UploadEventState.FAILED, 0, 0)
                .setError(out.getString(UploadWorker.KEY_ERROR) ?: "upload failed")
                .build()

            WorkInfo.State.CANCELLED -> event(info.id, GeneratedApi.UploadEventState.CANCELED, 0, 0).build()

            WorkInfo.State.RUNNING -> event(
                info.id, GeneratedApi.UploadEventState.RUNNING,
                info.progress.getLong(UploadWorker.KEY_SENT, 0), info.progress.getLong(UploadWorker.KEY_TOTAL, 0)
            ).build()

            // ENQUEUED (including a system-stopped job waiting to rerun) and BLOCKED.
            else -> event(info.id, GeneratedApi.UploadEventState.ENQUEUED, 0, 0).build()
        }
    }

    private fun event(id: UUID, state: GeneratedApi.UploadEventState, sent: Long, total: Long) =
        GeneratedApi.UploadEvent.Builder()
            .setId(id.toString())
            .setState(state)
            .setSent(sent)
            .setTotal(total)
            .setHttpStatus(0L)
}
