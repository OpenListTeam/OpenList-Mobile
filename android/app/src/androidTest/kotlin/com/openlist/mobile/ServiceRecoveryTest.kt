package com.openlist.mobile

import android.Manifest
import android.app.ActivityManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ActivityInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Process
import android.os.SystemClock
import android.util.Log
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.filters.LargeTest
import androidx.test.platform.app.InstrumentationRegistry
import com.openlist.mobile.server.ServerSettings
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Recovery guarantees of the OpenList foreground service.
 *
 * The server runs in the `:server` process, so the checks are split in two: the declaration is
 * resolved through [PackageManager], and [serverProcessIsRestoredAfterKill] exercises the real
 * restart path by killing that process.
 *
 * START_STICKY itself cannot be observed from outside the system server - the value returned by
 * `OpenListService.onStartCommand` never leaves the service record - so the behaviour it produces
 * is what the kill test asserts instead.
 */
@RunWith(AndroidJUnit4::class)
class ServiceRecoveryTest {
    private companion object {
        const val TAG = "ServiceRecoveryTest"

        /** `android:process` value from the manifest; the package manager expands the prefix. */
        const val SERVER_PROCESS_SUFFIX = ":server"

        /** The core has to read its config and bind its ports before the service is "started". */
        const val START_TIMEOUT_MS = 30_000L

        /** AMS restarts a sticky service after a back-off, so allow a generous window. */
        const val RESTART_TIMEOUT_MS = 30_000L

        /** Time for a stop request to clear the started state before teardown gives up. */
        const val STOP_TIMEOUT_MS = 10_000L

        const val POLL_INTERVAL_MS = 250L
    }

    private val context: Context = InstrumentationRegistry.getInstrumentation().targetContext
    private val packageManager: PackageManager = context.packageManager

    /** Fully qualified name of the server process, e.g. `com.openlist.mobile:server`. */
    private val serverProcess: String = context.packageName + SERVER_PROCESS_SUFFIX

    /** Set by the kill test so teardown only stops a server that the test started. */
    @Volatile
    private var startedByTest = false

    /** Settings as they were before the kill test, restored in [tearDown]. */
    private var savedSettings: ServerSettings.Values? = null

    // ---- Service declaration ----

    @Test
    fun serviceRunsInServerProcess() {
        val info = serviceInfo()

        assertEquals(
            "OpenListService must not share the UI process",
            serverProcess,
            info.processName
        )
        assertTrue("OpenListService must be enabled", info.enabled)
        assertTrue("the application must be enabled", info.applicationInfo.enabled)
        assertFalse("OpenListService must not be exported", info.exported)
        assertTrue(
            "stopWithTask=false keeps the server alive when the task is removed",
            (info.flags and ServiceInfo.FLAG_STOP_WITH_TASK) == 0
        )
    }

    @Test
    fun serviceDeclaresSpecialUseForegroundType() {
        // foregroundServiceType is only reported from Android 14 on; older platforms ignore the
        // manifest value, so there is nothing meaningful to compare there.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            assumeTrue("specialUse is only reported from Android 14", false)
            return
        }
        val type = serviceInfo().foregroundServiceType
        assertTrue(
            "specialUse is the only foreground service type allowed to start from BOOT_COMPLETED",
            (type and ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE) != 0
        )
    }

    @Test
    fun foregroundServicePermissionsAreDeclared() {
        val declared = requestedPermissions()
        assertTrue(
            "${Manifest.permission.FOREGROUND_SERVICE} is required by OpenListService",
            declared.contains(Manifest.permission.FOREGROUND_SERVICE)
        )
        assertTrue(
            "${Manifest.permission.FOREGROUND_SERVICE_SPECIAL_USE} is required on Android 14+",
            declared.contains(Manifest.permission.FOREGROUND_SERVICE_SPECIAL_USE)
        )
    }

    // ---- Boot receiver ----

    @Test
    fun bootReceiverHandlesBootAndPackageReplace() {
        assertTrue(
            "${Manifest.permission.RECEIVE_BOOT_COMPLETED} must be requested " +
                "or BOOT_COMPLETED is never delivered",
            requestedPermissions().contains(Manifest.permission.RECEIVE_BOOT_COMPLETED)
        )
        assertReceiverRegistered(Intent.ACTION_BOOT_COMPLETED)
        assertReceiverRegistered(Intent.ACTION_MY_PACKAGE_REPLACED)
    }

    // ---- Sticky restart ----

    /**
     * Starts the service, kills the `:server` process and waits for it to come back.
     *
     * This depends on the real Go core starting, because the service leaves the foreground (and
     * stops itself) when the core is not running, which removes the started state a sticky
     * restart relies on. That is why the test is [LargeTest] and fails instead of skipping when
     * the core does not come up.
     *
     * ServerClient is deliberately not used here: its BIND_AUTO_CREATE connection would recreate
     * the process after the kill and mask a missing START_STICKY restart.
     */
    @LargeTest
    @Test(timeout = 180_000L)
    fun serverProcessIsRestoredAfterKill() {
        // Snapshot first: starting and stopping the server rewrites wasRunning/manuallyStopped.
        savedSettings = runCatching { ServerSettings.get() }.getOrNull()

        startedByTest = true
        startServerService()

        val started = awaitUntil(START_TIMEOUT_MS) { isServerServiceStarted() }
        assertTrue(
            "the OpenList service did not reach the started state within " +
                "${START_TIMEOUT_MS / 1000}s; the core probably failed to start " +
                "(see logcat tag ${OpenListService.TAG})",
            started
        )

        val pid = findServerPid()
        assertTrue("cannot resolve the pid of $serverProcess", pid > 0)
        Log.i(TAG, "Killing $serverProcess (pid=$pid)")
        // Same uid (the instrumentation runs inside the app's own process), so the KILL signal is
        // allowed. killProcess() has no return value; the new pid below is what proves it worked.
        Process.killProcess(pid)

        val restarted = awaitServerPid(RESTART_TIMEOUT_MS, excludePid = pid)
        assertTrue(
            "$serverProcess did not come back within ${RESTART_TIMEOUT_MS / 1000}s after the " +
                "kill; the START_STICKY restart failed",
            restarted > 0
        )
        Log.i(TAG, "$serverProcess was restarted (pid=$restarted)")
    }

    /** Stops a server started by the kill test and puts the persisted settings back. */
    @After
    fun tearDown() {
        try {
            if (startedByTest) {
                runCatching { OpenListService.sendAction(context, OpenListService.ACTION_STOP) }
                awaitUntil(STOP_TIMEOUT_MS) { !isServerServiceStarted() }
            }
        } finally {
            startedByTest = false
            // Restore after the stop, otherwise the stop overwrites manuallyStopped/wasRunning.
            savedSettings?.let { saved -> runCatching { ServerSettings.update { saved } } }
            savedSettings = null
        }
    }

    // ---- Helpers ----

    /**
     * Starts the server the way the UI does.
     *
     * Starting a service from the background is normally restricted, but instrumented processes
     * are exempt, so the direct call is expected to succeed. If the system still rejects it, the
     * exported [SwitchServerActivity] shortcut is the fallback: it runs in `:server` and starts
     * the service from a visible activity. That shortcut toggles, so it must only be used when
     * the service is not running - which is exactly the state in which the direct call throws.
     */
    private fun startServerService() {
        try {
            OpenListService.sendAction(context, OpenListService.ACTION_START)
            return
        } catch (e: Exception) {
            Log.w(TAG, "Foreground service start rejected, using the launcher shortcut", e)
        }
        runCatching {
            context.startActivity(
                Intent(context, SwitchServerActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
        }.onFailure { Log.e(TAG, "Launcher shortcut could not be started", it) }
    }

    @Suppress("DEPRECATION")
    private fun serviceInfo(): ServiceInfo {
        val component = ComponentName(context, OpenListService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            return packageManager.getServiceInfo(
                component,
                PackageManager.ComponentInfoFlags.of(0L)
            )
        }
        return packageManager.getServiceInfo(component, 0)
    }

    @Suppress("DEPRECATION")
    private fun packageInfo(): PackageInfo {
        val flags = PackageManager.GET_PERMISSIONS
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            return packageManager.getPackageInfo(
                context.packageName,
                PackageManager.PackageInfoFlags.of(flags.toLong())
            )
        }
        return packageManager.getPackageInfo(context.packageName, flags)
    }

    private fun requestedPermissions(): List<String> =
        packageInfo().requestedPermissions?.toList().orEmpty()

    /**
     * Resolves [BootReceiver] for [action] so its declaration and `enabled` flag can be checked.
     *
     * MATCH_DISABLED_COMPONENTS (API 24+) matters: without it a disabled receiver does not
     * resolve at all, and "missing" and "disabled" would be indistinguishable.
     */
    @Suppress("DEPRECATION")
    private fun receiverMatches(action: String): ActivityInfo? {
        val intent = Intent(action).setPackage(context.packageName)
        val matches: List<ResolveInfo> =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.queryBroadcastReceivers(
                    intent,
                    PackageManager.ResolveInfoFlags.of(
                        PackageManager.MATCH_DISABLED_COMPONENTS.toLong()
                    )
                )
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                packageManager.queryBroadcastReceivers(
                    intent,
                    PackageManager.MATCH_DISABLED_COMPONENTS
                )
            } else {
                packageManager.queryBroadcastReceivers(intent, 0)
            }
        return matches.firstOrNull { it.activityInfo?.name == BootReceiver::class.java.name }
            ?.activityInfo
    }

    /** Asserts that [BootReceiver] is declared and enabled for [action]. */
    private fun assertReceiverRegistered(action: String) {
        val info = receiverMatches(action)
        assertNotNull("BootReceiver is not declared for $action", info)
        assertTrue(
            "BootReceiver must be enabled for $action",
            info!!.enabled && info.applicationInfo.enabled
        )
    }

    /**
     * True when `OpenListService` is in the started state (not merely bound), which is the
     * precondition for a sticky restart. Only the caller's own services are reported.
     */
    @Suppress("DEPRECATION")
    private fun isServerServiceStarted(): Boolean {
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val services = am.getRunningServices(Int.MAX_VALUE) ?: return findServerPid() > 0
        val component = ComponentName(context, OpenListService::class.java)
        val match = services.firstOrNull { it.service == component }
        // Absent ServiceRecord: either the service is gone, or this ROM does not report it. The
        // process pid distinguishes the two, since a started service always owns its process.
        return match?.started ?: (findServerPid() > 0)
    }

    @Suppress("DEPRECATION")
    private fun findServerPid(): Int {
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        am.getRunningServices(Int.MAX_VALUE)
            ?.firstOrNull { it.process == serverProcess && it.pid > 0 }
            ?.let { return it.pid }
        // runningAppProcesses is filtered to the caller's own processes since Android 5.1, which
        // includes `:server` because it belongs to this app.
        return am.runningAppProcesses
            ?.firstOrNull { it.processName == serverProcess }
            ?.pid ?: -1
    }

    /** Polls [condition] until it is true or [timeoutMs] elapses. */
    private fun awaitUntil(timeoutMs: Long, condition: () -> Boolean): Boolean {
        val deadline = SystemClock.elapsedRealtime() + timeoutMs
        while (SystemClock.elapsedRealtime() < deadline) {
            if (condition()) return true
            Thread.sleep(POLL_INTERVAL_MS)
        }
        return condition()
    }

    /** Waits for a live `:server` pid that differs from [excludePid], or -1 on timeout. */
    private fun awaitServerPid(timeoutMs: Long, excludePid: Int = -1): Int {
        awaitUntil(timeoutMs) {
            val pid = findServerPid()
            pid > 0 && pid != excludePid
        }
        val pid = findServerPid()
        return if (pid > 0 && pid != excludePid) pid else -1
    }
}
