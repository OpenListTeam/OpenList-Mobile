package com.openlist.mobile.bridge

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import androidx.core.content.FileProvider
import androidx.documentfile.provider.DocumentFile
import com.openlist.pigeon.GeneratedApi
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.RandomAccessFile
import java.nio.ByteBuffer
import java.util.UUID
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicReference
import android.webkit.MimeTypeMap

class DownloadStorageBridge(private val activity: Activity) : GeneratedApi.DownloadStorage {
    companion object {
        private const val PREFS = "openlist.download.storage"
        private const val DEFAULT_DIRECTORY = "directory-default"
        private const val SELECTED_DIRECTORY = "selected-directory"
        private const val DIRECTORY_PREFIX = "directory."
        private const val FILE_PREFIX = "file."
        private const val PICK_DIRECTORY_REQUEST = 0x4f44
    }

    private data class DirectoryHandle(
        val reference: String,
        val name: String,
        val path: File? = null,
        val tree: DocumentFile? = null,
    )

    private data class FileHandle(
        val reference: String,
        val directory: DirectoryHandle,
        val name: String,
        val temporaryName: String,
        val file: File? = null,
        val document: DocumentFile? = null,
    )

    private val preferences = activity.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    private val resolver = activity.contentResolver
    private val ioExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private val pendingPicker = AtomicReference<GeneratedApi.NullableResult<GeneratedApi.DownloadDirectory>?>(null)

    override fun getDefaultDirectory(result: GeneratedApi.Result<GeneratedApi.DownloadDirectory>) {
        execute(result) {
            val selected = preferences.getString(SELECTED_DIRECTORY, null)
            val directory = if (selected == null) {
                ensureDefaultDirectory()
            } else {
                resolveDirectory(selected)
            }
            directoryResult(directory)
        }
    }

    override fun chooseDirectory(result: GeneratedApi.NullableResult<GeneratedApi.DownloadDirectory>) {
        if (!pendingPicker.compareAndSet(null, result)) {
            result.error(IllegalStateException("A directory picker is already open"))
            return
        }
        activity.runOnUiThread {
            try {
                val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                    addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                    addFlags(Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
                }
                activity.startActivityForResult(intent, PICK_DIRECTORY_REQUEST)
            } catch (error: Throwable) {
                pendingPicker.getAndSet(null)?.error(error)
            }
        }
    }

    fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != PICK_DIRECTORY_REQUEST) return false
        val callback = pendingPicker.getAndSet(null) ?: return true
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            callback.success(null)
            return true
        }
        try {
            val uri = data.data!!
            val flags = data.flags and
                (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT && flags != 0) {
                resolver.takePersistableUriPermission(uri, flags)
            }
            val tree = DocumentFile.fromTreeUri(activity, uri)
                ?: throw IllegalArgumentException("The selected directory is unavailable")
            if (!tree.isDirectory || !tree.canWrite()) {
                throw IllegalArgumentException("The selected directory is not writable")
            }
            val reference = newDirectoryReference()
            val name = tree.name?.takeIf { it.isNotBlank() } ?: "Selected folder"
            saveDirectory(reference, uri.toString(), name)
            preferences.edit().putString(SELECTED_DIRECTORY, reference).apply()
            callback.success(directoryResult(DirectoryHandle(reference, name, tree = tree)))
        } catch (error: Throwable) {
            callback.error(error)
        }
        return true
    }

    override fun resetSelectedDirectory(result: GeneratedApi.VoidResult) {
        executeVoid(result) {
            val selected = preferences.getString(SELECTED_DIRECTORY, null)
            val uri = selected?.let {
                preferences.getString("$DIRECTORY_PREFIX$it.uri", null)
            }
            if (uri != null) {
                runCatching {
                    resolver.releasePersistableUriPermission(
                        Uri.parse(uri),
                        Intent.FLAG_GRANT_READ_URI_PERMISSION or
                            Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
                    )
                }
            }
            preferences.edit().remove(SELECTED_DIRECTORY).apply()
        }
    }

    override fun reserveFile(
        directoryReference: String,
        filename: String,
        result: GeneratedApi.Result<GeneratedApi.DownloadFile>,
    ) {
        execute(result) {
            val directory = resolveDirectory(directoryReference)
            val requested = safeFilename(filename)
            val finalName = uniqueName(directory, requested)
            val temporaryName = ".openlist-${UUID.randomUUID()}.part"
            val handleReference = newFileReference()
            val localFile: File?
            val document: DocumentFile?
            if (directory.path != null) {
                localFile = File(directory.path, temporaryName).also {
                    if (!it.createNewFile()) throw IllegalStateException("Cannot reserve download file")
                }
                document = null
            } else {
                localFile = null
                document = directory.tree!!.createFile("application/octet-stream", temporaryName)
                    ?: throw IllegalStateException("Cannot reserve download file")
            }
            saveFile(handleReference, directory.reference, finalName, temporaryName, localFile?.let { fileUri(it) } ?: document!!.uri.toString())
            downloadFile(handleReference, directory.reference, finalName, localFile, document)
        }
    }

    override fun getFileLength(fileReference: String, result: GeneratedApi.Result<Long>) {
        execute(result) {
            val handle = resolveFile(fileReference) ?: throw IllegalArgumentException("Download file not found")
            fileLength(handle)
        }
    }

    override fun truncateFile(fileReference: String, result: GeneratedApi.VoidResult) {
        executeVoid(result) {
            val handle = resolveFile(fileReference) ?: throw IllegalArgumentException("Download file not found")
            if (handle.file != null) {
                RandomAccessFile(handle.file, "rw").use { it.setLength(0) }
            } else {
                withOutput(handle) { channel -> channel.truncate(0) }
            }
        }
    }

    override fun writeFile(
        fileReference: String,
        offset: Long,
        data: ByteArray,
        result: GeneratedApi.VoidResult,
    ) {
        executeVoid(result) {
            require(offset >= 0) { "File offset must not be negative" }
            val handle = resolveFile(fileReference) ?: throw IllegalArgumentException("Download file not found")
            if (handle.file != null) {
                RandomAccessFile(handle.file, "rw").use {
                    it.seek(offset)
                    it.write(data)
                }
            } else {
                withOutput(handle) { channel ->
                    channel.position(offset)
                    val bytes = ByteBuffer.wrap(data)
                    while (bytes.hasRemaining()) channel.write(bytes)
                }
            }
        }
    }

    override fun flushFile(fileReference: String, result: GeneratedApi.VoidResult) {
        executeVoid(result) {
            val handle = resolveFile(fileReference) ?: throw IllegalArgumentException("Download file not found")
            if (handle.file != null) {
                RandomAccessFile(handle.file, "rw").use { it.fd.sync() }
            } else {
                withOutput(handle) { channel -> channel.force(true) }
            }
        }
    }

    override fun finalizeFile(
        fileReference: String,
        result: GeneratedApi.Result<GeneratedApi.DownloadFile>,
    ) {
        execute(result) {
            val handle = resolveFile(fileReference) ?: throw IllegalArgumentException("Download file not found")
            val destinationName = uniqueName(handle.directory, handle.name, handle.temporaryName)
            if (handle.file != null) {
                val destination = File(handle.directory.path!!, destinationName)
                if (!handle.file.renameTo(destination)) {
                    throw IllegalStateException("Cannot finalize download file")
                }
                saveFile(handle.reference, handle.directory.reference, destinationName, "", fileUri(destination))
                downloadFile(handle.reference, handle.directory.reference, destinationName, destination, null)
            } else {
                val document = handle.document ?: throw IllegalArgumentException("Download file not found")
                if (!document.renameTo(destinationName)) {
                    throw IllegalStateException("Cannot finalize download file")
                }
                val renamed = handle.directory.tree!!.findFile(destinationName)
                    ?: DocumentFile.fromSingleUri(activity, document.uri)
                    ?: throw IllegalStateException("Finalized download file is unavailable")
                saveFile(handle.reference, handle.directory.reference, destinationName, "", renamed.uri.toString())
                downloadFile(handle.reference, handle.directory.reference, destinationName, null, renamed)
            }
        }
    }

    override fun discardFile(fileReference: String, result: GeneratedApi.VoidResult) {
        executeVoid(result) {
            val handle = resolveFile(fileReference) ?: return@executeVoid
            if (handle.file != null) {
                handle.file.delete()
            } else {
                handle.document?.delete()
            }
            removeFile(handle.reference)
        }
    }

    override fun getFile(fileReference: String, result: GeneratedApi.NullableResult<GeneratedApi.DownloadFile>) {
        executeNullable(result) {
            val handle = resolveFile(fileReference) ?: return@executeNullable null
            if (handle.file?.exists() == false || handle.document?.exists() == false) {
                removeFile(fileReference)
                return@executeNullable null
            }
            downloadFile(handle.reference, handle.directory.reference, handle.name, handle.file, handle.document)
        }
    }

    override fun listFiles(
        directoryReference: String,
        result: GeneratedApi.Result<List<GeneratedApi.DownloadFile>>,
    ) {
        execute(result) {
            val directory = resolveDirectory(directoryReference)
            val files = if (directory.path != null) {
                directory.path.listFiles()?.filter {
                    it.isFile && !it.name.startsWith(".openlist-")
                }?.map { file ->
                    val reference = findOrRegisterFile(directory, file.name, fileUri(file))
                    downloadFile(reference, directory.reference, file.name, file, null)
                } ?: emptyList()
            } else {
                directory.tree!!.listFiles().filter {
                    it.isFile && !it.name.orEmpty().startsWith(".openlist-")
                }.map { document ->
                    val name = document.name ?: return@map null
                    val reference = findOrRegisterFile(directory, name, document.uri.toString())
                    downloadFile(reference, directory.reference, name, null, document)
                }.filterNotNull()
            }
            files.sortedBy { it.getName().lowercase() }
        }
    }

    override fun deleteFile(fileReference: String, result: GeneratedApi.VoidResult) {
        executeVoid(result) {
            val handle = resolveFile(fileReference) ?: return@executeVoid
            val deleted = handle.file?.delete() ?: handle.document?.delete() ?: false
            if (!deleted && (handle.file?.exists() == true || handle.document?.exists() == true)) {
                throw IllegalStateException("Cannot delete download file")
            }
            removeFile(fileReference)
        }
    }

    override fun clearDirectory(directoryReference: String, result: GeneratedApi.VoidResult) {
        executeVoid(result) {
            val directory = resolveDirectory(directoryReference)
            if (directory.path != null) {
                directory.path.listFiles()?.filter { it.isFile }?.forEach { it.delete() }
            } else {
                directory.tree!!.listFiles().filter { it.isFile }.forEach { it.delete() }
            }
            preferences.all.keys.filter { key ->
                key.startsWith(FILE_PREFIX) && key.endsWith(".directory") &&
                    preferences.getString(key, null) == directory.reference
            }.forEach { key ->
                removeFile(key.removePrefix(FILE_PREFIX).removeSuffix(".directory"))
            }
        }
    }

    override fun openFile(fileReference: String, result: GeneratedApi.Result<Boolean>) {
        executeOnMain(result) {
            val handle = resolveFile(fileReference) ?: return@executeOnMain false
            val uri = handle.document?.uri ?: handle.file?.let { Uri.parse(fileUri(it)) } ?: return@executeOnMain false
            val mime = mimeType(handle.name)
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mime)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            try {
                activity.startActivity(intent)
                true
            } catch (_: Throwable) {
                false
            }
        }
    }

    override fun openDirectory(directoryReference: String, result: GeneratedApi.Result<Boolean>) {
        executeOnMain(result) {
            val directory = resolveDirectory(directoryReference)
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && directory.tree != null) {
                    putExtra("android.provider.extra.INITIAL_URI", directory.tree.uri)
                }
            }
            try {
                activity.startActivity(intent)
                true
            } catch (_: Throwable) {
                false
            }
        }
    }

    fun dispose() {
        pendingPicker.getAndSet(null)?.success(null)
        ioExecutor.shutdownNow()
    }

    private fun ensureDefaultDirectory(): DirectoryHandle {
        val directory = activity.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
            ?.resolve("OpenList") ?: activity.filesDir.resolve("Downloads/OpenList")
        if (!directory.exists() && !directory.mkdirs()) {
            throw IllegalStateException("Cannot create default download directory")
        }
        saveDirectory(DEFAULT_DIRECTORY, directory.absolutePath, "OpenList")
        return DirectoryHandle(DEFAULT_DIRECTORY, "OpenList", path = directory)
    }

    private fun resolveDirectory(reference: String): DirectoryHandle {
        if (reference == DEFAULT_DIRECTORY) return ensureDefaultDirectory()
        val path = preferences.getString("$DIRECTORY_PREFIX$reference.path", null)
        if (path != null) {
            val directory = File(path)
            if (!directory.exists() && !directory.mkdirs()) throw IllegalStateException("Download directory is unavailable")
            if (!directory.isDirectory || !directory.canWrite()) throw IllegalStateException("Download directory is not writable")
            val name = preferences.getString("$DIRECTORY_PREFIX$reference.name", directory.name) ?: directory.name
            return DirectoryHandle(reference, name, path = directory)
        }
        val uriString = preferences.getString("$DIRECTORY_PREFIX$reference.uri", null)
            ?: throw IllegalArgumentException("Download directory not found")
        val uri = Uri.parse(uriString)
        val tree = DocumentFile.fromTreeUri(activity, uri)
            ?: throw IllegalStateException("Download directory permission was revoked")
        if (!tree.exists() || !tree.isDirectory || !tree.canWrite()) {
            throw IllegalStateException("Download directory permission was revoked")
        }
        val name = preferences.getString("$DIRECTORY_PREFIX$reference.name", tree.name ?: "Selected folder")
            ?: tree.name ?: "Selected folder"
        return DirectoryHandle(reference, name, tree = tree)
    }

    private fun resolveFile(reference: String): FileHandle? {
        val directoryReference = preferences.getString("$FILE_PREFIX$reference.directory", null) ?: return null
        val directory = resolveDirectory(directoryReference)
        val name = preferences.getString("$FILE_PREFIX$reference.name", null) ?: return null
        val temporaryName = preferences.getString("$FILE_PREFIX$reference.temp", "") ?: ""
        val currentName = temporaryName.ifEmpty { name }
        val storedUri = preferences.getString("$FILE_PREFIX$reference.uri", null)
        if (directory.path != null) {
            return FileHandle(reference, directory, name, temporaryName, file = File(directory.path, currentName))
        }
        val document = storedUri?.let { DocumentFile.fromSingleUri(activity, Uri.parse(it)) }
            ?: directory.tree!!.findFile(currentName)
        return FileHandle(reference, directory, name, temporaryName, document = document)
    }

    private fun uniqueName(directory: DirectoryHandle, requested: String, ignored: String? = null): String {
        var candidate = requested
        var index = 1
        while (exists(directory, candidate) && candidate != ignored) {
            val dot = candidate.lastIndexOf('.')
            val stem = if (dot > 0) candidate.substring(0, dot) else candidate
            val extension = if (dot > 0) candidate.substring(dot) else ""
            candidate = "${stem}_$index$extension"
            index++
        }
        return candidate
    }

    private fun exists(directory: DirectoryHandle, name: String): Boolean {
        return if (directory.path != null) File(directory.path, name).exists()
        else directory.tree!!.findFile(name)?.exists() == true
    }

    private fun safeFilename(filename: String): String {
        val name = filename.trim().replace(Regex("[\\u0000-\\u001f\\\\/]"), "_")
        require(name.isNotEmpty() && name != "." && name != "..") { "Invalid download filename" }
        return name
    }

    private fun fileLength(handle: FileHandle): Long {
        if (handle.file != null) return handle.file.length()
        return withInput(handle) { channel -> channel.size() }
    }

    private fun <T> withInput(handle: FileHandle, block: (java.nio.channels.FileChannel) -> T): T {
        val document = handle.document ?: throw IllegalArgumentException("Download file not found")
        val descriptor = resolver.openFileDescriptor(document.uri, "r")
            ?: throw IllegalStateException("Cannot open download file")
        descriptor.use { pfd ->
            FileInputStream(pfd.fileDescriptor).use { input -> return block(input.channel) }
        }
    }

    private fun <T> withOutput(handle: FileHandle, block: (java.nio.channels.FileChannel) -> T): T {
        val document = handle.document ?: throw IllegalArgumentException("Download file not found")
        val descriptor = resolver.openFileDescriptor(document.uri, "rw")
            ?: throw IllegalStateException("Cannot open download file")
        descriptor.use { pfd ->
            FileOutputStream(pfd.fileDescriptor).use { output -> return block(output.channel) }
        }
    }

    private fun directoryResult(directory: DirectoryHandle) = GeneratedApi.DownloadDirectory.Builder()
        .setReference(directory.reference)
        .setName(directory.name)
        .build()

    private fun downloadFile(
        reference: String,
        directoryReference: String,
        name: String,
        file: File?,
        document: DocumentFile?,
    ) = GeneratedApi.DownloadFile.Builder()
        .setReference(reference)
        .setDirectoryReference(directoryReference)
        .setName(name)
        .setSize(file?.length() ?: document?.length() ?: 0L)
        .setModifiedAt(file?.lastModified() ?: document?.lastModified() ?: 0L)
        .setMimeType(mimeType(name))
        .build()

    private fun findOrRegisterFile(directory: DirectoryHandle, name: String, uri: String): String {
        val existing = preferences.all.keys.firstOrNull { key ->
            key.startsWith(FILE_PREFIX) && key.endsWith(".uri") &&
                preferences.getString(key.removeSuffix(".uri") + ".directory", null) == directory.reference &&
                preferences.getString(key, null) == uri
        }
        if (existing != null) return existing.removePrefix(FILE_PREFIX).removeSuffix(".uri")
        val reference = newFileReference()
        saveFile(reference, directory.reference, name, "", uri)
        return reference
    }

    private fun saveDirectory(reference: String, value: String, name: String) {
        val editor = preferences.edit()
            .putString("$DIRECTORY_PREFIX$reference.name", name)
        if (value.startsWith("/")) editor.putString("$DIRECTORY_PREFIX$reference.path", value)
        else editor.putString("$DIRECTORY_PREFIX$reference.uri", value)
        editor.apply()
    }

    private fun saveFile(reference: String, directory: String, name: String, temporaryName: String, uri: String?) {
        val editor = preferences.edit()
            .putString("$FILE_PREFIX$reference.directory", directory)
            .putString("$FILE_PREFIX$reference.name", name)
            .putString("$FILE_PREFIX$reference.temp", temporaryName)
        if (uri == null) editor.remove("$FILE_PREFIX$reference.uri")
        else editor.putString("$FILE_PREFIX$reference.uri", uri)
        editor.apply()
    }

    private fun removeFile(reference: String) {
        preferences.edit()
            .remove("$FILE_PREFIX$reference.directory")
            .remove("$FILE_PREFIX$reference.name")
            .remove("$FILE_PREFIX$reference.temp")
            .remove("$FILE_PREFIX$reference.uri")
            .apply()
    }

    private fun fileUri(file: File): String = FileProvider.getUriForFile(
        activity,
        "${activity.packageName}.fileprovider",
        file,
    ).toString()

    private fun mimeType(name: String): String = MimeTypeMap.getSingleton()
        .getMimeTypeFromExtension(name.substringAfterLast('.', "").lowercase())
        ?: "application/octet-stream"

    private fun newDirectoryReference() = "directory-${UUID.randomUUID()}"
    private fun newFileReference() = "file-${UUID.randomUUID()}"

    private fun <T> execute(result: GeneratedApi.Result<T>, block: () -> T) {
        ioExecutor.execute {
            try {
                result.success(block())
            } catch (error: Throwable) {
                result.error(error)
            }
        }
    }

    private fun <T> executeNullable(result: GeneratedApi.NullableResult<T>, block: () -> T?) {
        ioExecutor.execute {
            try {
                result.success(block())
            } catch (error: Throwable) {
                result.error(error)
            }
        }
    }

    private fun executeVoid(result: GeneratedApi.VoidResult, block: () -> Unit) {
        ioExecutor.execute {
            try {
                block()
                result.success()
            } catch (error: Throwable) {
                result.error(error)
            }
        }
    }

    private fun <T> executeOnMain(result: GeneratedApi.Result<T>, block: () -> T) {
        activity.runOnUiThread {
            try {
                result.success(block())
            } catch (error: Throwable) {
                result.error(error)
            }
        }
    }
}
