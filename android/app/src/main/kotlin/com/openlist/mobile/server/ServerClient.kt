package com.openlist.mobile.server

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.Message
import android.os.Messenger
import android.os.RemoteException
import android.util.Log
import com.openlist.mobile.OpenListService

/**
 * UI-process client of [OpenListService]. Binding only creates the service
 * process; it never starts the Go core. Requests issued before the
 * connection is ready are queued and flushed on connect.
 */
object ServerClient {
    private const val TAG = "ServerClient"

    interface Listener {
        fun onStatus(status: Bundle)
        fun onLog(level: Int, time: String, message: String)
    }

    private val handler = Handler(Looper.getMainLooper()) { msg -> handle(msg); true }
    private val replyTo = Messenger(handler)
    private val listeners = mutableListOf<Listener>()
    private val pending = mutableMapOf<Int, (Bundle) -> Unit>()
    private val queue = mutableListOf<Message>()
    private var nextId = 1
    private var service: Messenger? = null
    private var appContext: Context? = null
    private var bound = false

    @Volatile
    var lastStatus: Bundle = Bundle()
        private set

    private val connection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, binder: IBinder?) {
            service = Messenger(binder)
            Log.d(TAG, "Connected to server process")
            send(Message.obtain(null, ServerProtocol.MSG_REGISTER).apply { this.replyTo = this@ServerClient.replyTo })
            queue.toList().also { queue.clear() }.forEach(::send)
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            // The server process died; the binding reconnects once it restarts.
            Log.w(TAG, "Server process disconnected")
            service = null
            failPending("server process disconnected")
            lastStatus = Bundle()
            listeners.toList().forEach { it.onStatus(lastStatus) }
        }
    }

    fun bind(context: Context) {
        if (bound) return
        appContext = context.applicationContext
        bound = appContext!!.bindService(
            Intent(appContext, OpenListService::class.java),
            connection,
            Context.BIND_AUTO_CREATE
        )
    }

    fun unbind() {
        if (!bound) return
        send(Message.obtain(null, ServerProtocol.MSG_UNREGISTER).apply { this.replyTo = this@ServerClient.replyTo })
        runCatching { appContext?.unbindService(connection) }
        bound = false
        service = null
        failPending("client unbound")
    }

    fun addListener(l: Listener) = listeners.add(l)
    fun removeListener(l: Listener) = listeners.remove(l)

    /** Fire-and-forget message. */
    fun notify(what: Int) = enqueue(Message.obtain(null, what))

    /** Request with a reply; [callback] runs on the main thread. */
    fun request(what: Int, data: Bundle = Bundle(), callback: (Bundle) -> Unit) {
        val id = nextId++
        pending[id] = callback
        enqueue(Message.obtain(null, what, id, 0).apply {
            this.data = data
            replyTo = this@ServerClient.replyTo
        })
    }

    private fun enqueue(msg: Message) {
        if (service == null) {
            queue.add(msg)
            appContext?.let { bind(it) }
        } else {
            send(msg)
        }
    }

    private fun send(msg: Message) {
        try {
            service?.send(msg) ?: queue.add(msg)
        } catch (e: RemoteException) {
            Log.e(TAG, "Failed to send message ${msg.what}", e)
            if (msg.arg1 != 0) pending.remove(msg.arg1)?.invoke(errorBundle(e.toString()))
        }
    }

    private fun handle(msg: Message) {
        when (msg.what) {
            ServerProtocol.MSG_STATUS -> {
                lastStatus = msg.data
                listeners.toList().forEach { it.onStatus(msg.data) }
            }

            ServerProtocol.MSG_LOG -> {
                val d = msg.data
                listeners.toList().forEach {
                    it.onLog(
                        d.getInt(ServerProtocol.KEY_LEVEL),
                        d.getString(ServerProtocol.KEY_TIME).orEmpty(),
                        d.getString(ServerProtocol.KEY_MESSAGE).orEmpty()
                    )
                }
            }

            ServerProtocol.MSG_REPLY -> pending.remove(msg.arg1)?.invoke(msg.data)
        }
    }

    private fun failPending(reason: String) {
        val callbacks = pending.values.toList()
        pending.clear()
        callbacks.forEach { it(errorBundle(reason)) }
    }

    private fun errorBundle(reason: String) = Bundle().apply { putString(ServerProtocol.KEY_ERROR, reason) }
}
