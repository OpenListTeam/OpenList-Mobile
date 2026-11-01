import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/generated_api.dart',
  javaOut: 'android/app/src/main/java/com/openlist/pigeon/GeneratedApi.java',
  javaOptions: JavaOptions(package: 'com.openlist.pigeon'),
  swiftOut: 'ios/Runner/PigeonApi.swift',
))
@HostApi()
abstract class AppConfig {
  bool isWakeLockEnabled();

  void setWakeLockEnabled(bool enabled);

  bool isStartAtBootEnabled();

  void setStartAtBootEnabled(bool enabled);

  bool isAutoCheckUpdateEnabled();

  void setAutoCheckUpdateEnabled(bool enabled);

  bool isAutoOpenWebPageEnabled();

  void setAutoOpenWebPageEnabled(bool enabled);

  String getDataDir();

  void setDataDir(String dir);

  bool isSilentJumpAppEnabled();

  void setSilentJumpAppEnabled(bool enabled);
}

@HostApi()
abstract class NativeCommon {
  bool startActivityFromUri(String intentUri);

  int getDeviceSdkInt();

  String getDeviceCPUABI();

  String getVersionName();

  int getVersionCode();

  void toast(String msg);

  void longToast(String msg);
}

@HostApi()
abstract class Android {
  void addShortcut();

  void startService();

  int getOpenListHttpPort();

  bool isRunning();

  String getOpenListVersion();
}

/// Snapshot of the embedded server. On Android it is produced by the
/// independent server process and delivered over IPC.
class ServerStatus {
  ServerStatus({
    required this.running,
    required this.mode,
    required this.httpPort,
    required this.httpsPort,
    required this.forceHttps,
    required this.addresses,
    required this.manuallyStopped,
  });

  bool running;

  /// One of `local`, `lan`, `public`.
  String mode;
  int httpPort;
  int httpsPort;
  bool forceHttps;
  List<String> addresses;
  bool manuallyStopped;
  String? lastError;
}

class LogEntry {
  LogEntry({required this.level, required this.time, required this.message});

  int level;
  String time;
  String message;
}

class BackgroundDiagnostics {
  BackgroundDiagnostics({
    required this.manufacturer,
    required this.brand,
    required this.sdkInt,
    required this.ignoringBatteryOptimizations,
    required this.backgroundRestricted,
    required this.standbyBucket,
    required this.notificationsEnabled,
    required this.autoStartSettingsAvailable,
  });

  String manufacturer;
  String brand;
  int sdkInt;
  bool ignoringBatteryOptimizations;
  bool backgroundRestricted;

  /// UsageStatsManager standby bucket, or -1 when unavailable.
  int standbyBucket;
  bool notificationsEnabled;
  bool autoStartSettingsAvailable;
}

@HostApi()
abstract class ServerApi {
  @async
  void start();

  @async
  void stop();

  @async
  void restart();

  @async
  ServerStatus getStatus();

  String getMode();

  void setMode(String mode);

  @async
  void setAdminPassword(String pwd);

  /// Admin token for the in-app client, issued over private IPC only.
  @async
  String getLocalToken();

  /// JSON produced by the Go core `RuntimeStatus`, plus process stats.
  @async
  String getRuntimeStatus();

  /// JSON produced by the Go core `SecurityReport` for the given mode.
  @async
  String getSecurityReport(String mode);

  @async
  List<LogEntry> getRecentLogs();
}

@HostApi()
abstract class BackgroundApi {
  BackgroundDiagnostics getDiagnostics();

  bool requestIgnoreBatteryOptimizations();

  bool openBatteryOptimizationSettings();

  bool openAutoStartSettings();

  bool openAppDetailsSettings();
}

/// One file upload handed to the platform's background transfer service.
class UploadRequest {
  UploadRequest({
    required this.url,
    required this.method,
    required this.filePath,
    required this.headers,
    required this.title,
  });

  String url;
  String method;

  /// Local file streamed as the request body; reopened on each attempt.
  String filePath;

  /// Sent as-is; the platform sets Content-Length from the file size.
  Map<String, String> headers;

  /// Shown in the system notification where there is one.
  String title;
}

enum UploadEventState { enqueued, running, completed, failed, canceled }

/// Progress or result of a native upload. `completed` means the HTTP
/// exchange finished; Dart decides success from [httpStatus] and [body].
class UploadEvent {
  UploadEvent({
    required this.id,
    required this.state,
    required this.sent,
    required this.total,
    required this.httpStatus,
  });

  String id;
  UploadEventState state;
  int sent;
  int total;
  int httpStatus;
  String? body;
  String? error;
}

@HostApi()
abstract class UploadApi {
  /// Starts a background upload and returns its id.
  String enqueue(UploadRequest request);

  void cancel(String id);

  /// Current state of each known job in [ids], used after a relaunch.
  /// Unfinished jobs resume sending events. Ids the platform no longer knows
  /// are left out of the result; results kept for ids not in [ids] are
  /// dropped, so Dart passes every id it still tracks.
  @async
  List<UploadEvent> restore(List<String> ids);
}

@FlutterApi()
abstract class UploadEventApi {
  void onUploadEvent(UploadEvent event);
}

@FlutterApi()
abstract class Event {
  void onServiceStatusChanged(bool isRunning);

  void onServerStatus(ServerStatus status);

  void onServerLog(
    int level,
    String time,
    String log,
  );
}
