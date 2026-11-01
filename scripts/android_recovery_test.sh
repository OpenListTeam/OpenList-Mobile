#!/bin/sh
# OpenList Mobile - Android foreground service recovery test (manual, adb-based).
#
# Verifies, on a device or emulator where the app is ALREADY installed:
#   1. the `:server` process exists and hosts the OpenListService as a foreground service;
#   2. killing that process makes the system bring it back (START_STICKY restart);
#   3. BootReceiver reacts to MY_PACKAGE_REPLACED / BOOT_COMPLETED, where the platform allows it.
#
# The script installs nothing, but it does start the server, so use a test build. Many vendor ROMs
# restrict background starts; run it on a stock image or an emulator if a step fails unexpectedly.
#
# Usage:
#   sh scripts/android_recovery_test.sh
#   ANDROID_SERIAL=emulator-5554 sh scripts/android_recovery_test.sh
#
# Needs: adb on PATH (or ADB=/path/to/adb) and a device with USB debugging.
set -eu

ADB="${ADB:-adb}"
PACKAGE="com.openlist.mobile"
SERVER_PROCESS="${PACKAGE}:server"
SWITCH_ACTIVITY="${PACKAGE}/.SwitchServerActivity"

START_TIMEOUT=30     # seconds to wait for the server to come up
RESTART_TIMEOUT=30   # seconds to wait for a sticky restart after the kill
STOP_TIMEOUT=5       # seconds to confirm that a pid is gone
POLL_INTERVAL=1

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

# ---- Output helpers ----

info() { printf '%s\n' "$*"; }
pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf 'PASS  %s\n' "$*"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf 'FAIL  %s\n' "$*"; }
skip() { SKIP_COUNT=$((SKIP_COUNT + 1)); printf 'SKIP  %s\n' "$*"; }

die() {
    printf 'ERROR %s\n' "$*" >&2
    exit 2
}

# ---- adb helpers ----

# Every `adb shell` line ends with CR on Windows hosts, which breaks string comparisons.
# adbs keeps stdout only; adbs_msg also keeps stderr so failure messages can be inspected.
adbs() { "$ADB" shell "$@" 2>/dev/null | tr -d '\r' || true; }
adbs_msg() { "$ADB" shell "$@" 2>&1 | tr -d '\r' || true; }

require_device() {
    command -v "$ADB" >/dev/null 2>&1 ||
        die "adb not found; install platform-tools or set ADB=/path/to/adb"
    state=$("$ADB" get-state 2>/dev/null | tr -d '\r' || true)
    [ "$state" = "device" ] ||
        die "no device ready (adb get-state: ${state:-none}); check 'adb devices'"
}

require_installed() {
    path=$(adbs pm path "$PACKAGE")
    case "$path" in
        package:*) : ;;
        *) die "$PACKAGE is not installed; install a debug build first" ;;
    esac
    info "Installed: $path"
}

# Prints the pid of the `:server` process, or nothing when it is not running.
server_pid() {
    pid=$(adbs pidof "$SERVER_PROCESS" | awk '{ print $1; exit }')
    if [ -z "$pid" ]; then
        # NAME is the second column of `ps -A -o PID,NAME`, the last one on plain `ps`.
        pid=$(adbs ps -A -o PID,NAME | awk -v p="$SERVER_PROCESS" '$2 == p { print $1; exit }')
    fi
    if [ -z "$pid" ]; then
        pid=$(adbs ps | awk -v p="$SERVER_PROCESS" '$NF == p { print $2; exit }')
    fi
    printf '%s' "${pid:-}"
}

# Prints the ServiceRecord block of OpenListService from `dumpsys activity services`, or nothing
# when the ROM does not expose it.
service_block() {
    dump=$("$ADB" shell dumpsys activity services "$PACKAGE" 2>/dev/null | tr -d '\r' || true)
    block=$(printf '%s\n' "$dump" | filter_service_record)
    if [ -z "$block" ]; then
        # Some builds ignore the package filter; retry on the unfiltered dump.
        dump=$("$ADB" shell dumpsys activity services 2>/dev/null | tr -d '\r' || true)
        block=$(printf '%s\n' "$dump" | filter_service_record)
    fi
    printf '%s' "$block"
}

# Keeps the ServiceRecord block that mentions OpenListService; a new ServiceRecord header ends it.
filter_service_record() {
    awk '
        /^[ \t]*\* ServiceRecord\{/ { inside = 0 }
        /\.OpenListService/ { inside = 1 }
        inside { print }
    '
}

# Prints "yes", "no" or "unknown" for the foreground state of the service record.
service_foreground_state() {
    block=$(service_block)
    if [ -z "$block" ]; then
        printf 'unknown'
    elif printf '%s\n' "$block" | grep -q 'isForeground=true'; then
        printf 'yes'
    else
        printf 'no'
    fi
}

# Polls until the `:server` process exists and prints its pid; returns 1 on timeout.
wait_for_pid() {
    seconds=$1
    elapsed=0
    while [ "$elapsed" -lt "$seconds" ]; do
        pid=$(server_pid)
        if [ -n "$pid" ]; then
            printf '%s' "$pid"
            return 0
        fi
        sleep "$POLL_INTERVAL"
        elapsed=$((elapsed + POLL_INTERVAL))
    done
    return 1
}

# Polls until the given pid is no longer the `:server` pid.
wait_for_exit() {
    pid=$1
    seconds=$2
    elapsed=0
    while [ "$elapsed" -lt "$seconds" ]; do
        current=$(server_pid)
        if [ "$current" != "$pid" ]; then
            return 0
        fi
        sleep "$POLL_INTERVAL"
        elapsed=$((elapsed + POLL_INTERVAL))
    done
    return 1
}

# Polls until a pid different from the given one appears.
wait_for_new_pid() {
    old_pid=$1
    seconds=$2
    elapsed=0
    while [ "$elapsed" -lt "$seconds" ]; do
        pid=$(server_pid)
        if [ -n "$pid" ] && [ "$pid" != "$old_pid" ]; then
            printf '%s' "$pid"
            return 0
        fi
        sleep "$POLL_INTERVAL"
        elapsed=$((elapsed + POLL_INTERVAL))
    done
    return 1
}

# ---- Step 1: start the server ----

start_server() {
    info ""
    info "== 1. Start the server =="

    pid=$(server_pid)
    if [ -n "$pid" ]; then
        info "$SERVER_PROCESS already running (pid $pid); leaving it as it is"
    else
        # SwitchServerActivity is the exported launcher shortcut: it runs in :server and toggles
        # the service. The service itself is not exported, so `am startservice` from the shell
        # user cannot reach it. The toggle means this must only run while the server is stopped,
        # which is exactly the branch above.
        info "Starting $SWITCH_ACTIVITY"
        adbs am start -n "$SWITCH_ACTIVITY" >/dev/null
        pid=$(wait_for_pid "$START_TIMEOUT") || {
            fail "$SERVER_PROCESS did not start within ${START_TIMEOUT}s" \
                "(see: adb logcat -s OpenListService)"
            return 1
        }
    fi

    state=$(service_foreground_state)
    case "$state" in
        yes)
            pass "$SERVER_PROCESS is running as a foreground service (pid $pid)"
            ;;
        no)
            fail "$SERVER_PROCESS is running (pid $pid) but the service is not foreground"
            return 1
            ;;
        *)
            skip "dumpsys did not expose the ServiceRecord; cannot check the foreground state"
            ;;
    esac
    return 0
}

# ---- Step 2: kill and wait for the sticky restart ----

kill_and_wait() {
    info ""
    info "== 2. Kill $SERVER_PROCESS and wait for the restart =="
    pid=$(server_pid)
    if [ -z "$pid" ]; then
        fail "$SERVER_PROCESS is not running; cannot test the restart"
        return 1
    fi
    info "Killing pid $pid"

    # `adb shell kill` runs as uid 2000 and cannot signal an app process unless adbd is root.
    # `am crash <pid>` is the portable way to kill one specific process; `am kill` only reaches
    # background processes, and a foreground service usually survives it.
    killed=0
    output=$(adbs_msg kill -9 "$pid")
    case "$output" in
        *ermitted*|*"No such process"*|*"not found"*) info "kill denied: $output" ;;
        *)
            if wait_for_exit "$pid" "$STOP_TIMEOUT"; then
                info "Killed with /system/bin/kill (adbd runs as root)"
                killed=1
            fi
            ;;
    esac

    if [ "$killed" -ne 1 ]; then
        info "Falling back to: am crash $pid"
        adbs_msg am crash "$pid" >/dev/null
        if wait_for_exit "$pid" "$STOP_TIMEOUT"; then
            info "Killed with am crash (some builds show a crash dialog)"
            killed=1
        fi
    fi
    if [ "$killed" -ne 1 ]; then
        adbs_msg am kill "$PACKAGE" >/dev/null
        if wait_for_exit "$pid" "$STOP_TIMEOUT"; then
            info "Killed with am kill"
            killed=1
        fi
    fi
    if [ "$killed" -ne 1 ]; then
        fail "could not kill $SERVER_PROCESS (pid $pid); needs a rooted or emulator image"
        return 1
    fi

    new_pid=$(wait_for_new_pid "$pid" "$RESTART_TIMEOUT") || {
        fail "$SERVER_PROCESS did not come back within ${RESTART_TIMEOUT}s (START_STICKY failed)"
        return 1
    }
    pass "$SERVER_PROCESS was restarted (pid $new_pid) after the kill"

    # A sticky restart is a background start, so Android 12+ may refuse to re-enter the
    # foreground here; that is reported as information rather than as a failure.
    case "$(service_foreground_state)" in
        yes) info "Foreground state restored" ;;
        *) info "Note: not in the foreground state yet; on Android 12+ a sticky restart may need" \
                "the user to reopen the app (check the notification on the device)" ;;
    esac
}

# ---- Step 3/4: receiver broadcasts ----

# BOOT_COMPLETED and MY_PACKAGE_REPLACED are <protected-broadcast>: only the system may send
# them, so `am broadcast` works only when adbd runs as root (adb root on emulator/userdebug).
try_broadcast() {
    action=$1
    output=$(adbs_msg am broadcast -a "$action" -p "$PACKAGE")
    case "$output" in
        *"Permission Denial"*|*"SecurityException"*|*"not allowed to send broadcast"*)
            return 1
            ;;
    esac
    printf '%s' "$output"
    return 0
}

report_broadcast() {
    action=$1
    label=$2
    if output=$(try_broadcast "$action"); then
        if printf '%s' "$output" | grep -q 'Broadcast completed'; then
            pass "$label delivered to BootReceiver"
        else
            fail "$label was not delivered"
            info "$output"
        fi
    else
        skip "am broadcast of $label is denied (protected broadcast); 'adb root' is required"
    fi
}

test_package_replaced() {
    info ""
    info "== 3. MY_PACKAGE_REPLACED =="
    report_broadcast "android.intent.action.MY_PACKAGE_REPLACED" "MY_PACKAGE_REPLACED"
}

test_boot_completed() {
    info ""
    info "== 4. BOOT_COMPLETED =="
    report_broadcast "android.intent.action.BOOT_COMPLETED" "BOOT_COMPLETED"
    info "     Unrooted alternative: enable 'start at boot' in the app, run 'adb reboot', then"
    info "     check 'adb shell pidof $SERVER_PROCESS' once the device is up."
}

# ---- Main ----

main() {
    require_device
    require_installed

    # A failing step must not abort the run: every step reports and the summary decides.
    set +e
    start_server
    started=$?
    if [ "$started" -eq 0 ]; then
        kill_and_wait
    fi
    test_package_replaced
    test_boot_completed
    set -e

    info ""
    info "== Summary =="
    info "PASS: $PASS_COUNT  FAIL: $FAIL_COUNT  SKIP: $SKIP_COUNT"
    if [ "$FAIL_COUNT" -gt 0 ]; then
        info "RESULT: FAIL"
        exit 1
    fi
    info "RESULT: PASS"
}

main "$@"
