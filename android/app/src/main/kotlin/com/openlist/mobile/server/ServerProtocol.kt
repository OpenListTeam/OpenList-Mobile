package com.openlist.mobile.server

/**
 * Messenger protocol between the UI process and the `:server` process.
 * Requests carry a correlation id in `arg1`; replies echo it back.
 */
object ServerProtocol {
    const val MSG_REGISTER = 1
    const val MSG_UNREGISTER = 2
    const val MSG_GET_STATUS = 3
    const val MSG_STATUS = 4
    const val MSG_LOG = 5
    const val MSG_GET_LOGS = 6
    const val MSG_SET_ADMIN_PASSWORD = 7
    const val MSG_GET_TOKEN = 8
    const val MSG_GET_RUNTIME = 9
    const val MSG_GET_SECURITY = 10
    const val MSG_SYNC_DB = 11
    const val MSG_REFRESH_SETTINGS = 12
    const val MSG_REPLY = 100

    const val KEY_RUNNING = "running"
    const val KEY_STARTING = "starting"
    const val KEY_MODE = "mode"
    const val KEY_HTTP_PORT = "httpPort"
    const val KEY_HTTPS_PORT = "httpsPort"
    const val KEY_FORCE_HTTPS = "forceHttps"
    const val KEY_ADDRESSES = "addresses"
    const val KEY_LAST_ERROR = "lastError"
    const val KEY_MANUALLY_STOPPED = "manuallyStopped"

    const val KEY_LEVEL = "level"
    const val KEY_TIME = "time"
    const val KEY_MESSAGE = "message"
    const val KEY_LEVELS = "levels"
    const val KEY_TIMES = "times"
    const val KEY_MESSAGES = "messages"

    const val KEY_PASSWORD = "password"
    const val KEY_RESULT = "result"
    const val KEY_ERROR = "error"
}
