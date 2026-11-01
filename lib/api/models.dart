// Data models mirroring the OpenList HTTP API responses.

int _int(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

double _double(dynamic v) => v is num ? v.toDouble() : 0;

DateTime? _time(dynamic v) {
  if (v is! String || v.isEmpty) return null;
  final t = DateTime.tryParse(v);
  // Go zero time is reported as year 1.
  return t == null || t.year <= 1 ? null : t;
}

String _str(dynamic v) => v == null ? '' : '$v';

/// Object type codes from `pkg/utils/file.go`.
class ObjType {
  static const unknown = 0;
  static const folder = 1;
  static const video = 2;
  static const audio = 3;
  static const text = 4;
  static const image = 5;
}

class FsObject {
  FsObject({
    required this.name,
    required this.size,
    required this.isDir,
    this.modified,
    this.sign = '',
    this.thumb = '',
    this.type = ObjType.unknown,
    this.rawUrl = '',
    this.provider = '',
  });

  final String name;
  final int size;
  final bool isDir;
  final DateTime? modified;
  final String sign;
  final String thumb;
  final int type;

  /// Only set by `fs/get`.
  final String rawUrl;
  final String provider;

  factory FsObject.fromJson(Map<String, dynamic> j) => FsObject(
        name: _str(j['name']),
        size: _int(j['size']),
        isDir: j['is_dir'] == true,
        modified: _time(j['modified']),
        sign: _str(j['sign']),
        thumb: _str(j['thumb']),
        type: _int(j['type']),
        rawUrl: _str(j['raw_url']),
        provider: _str(j['provider']),
      );
}

class FsListResult {
  FsListResult({
    required this.content,
    required this.total,
    this.readme = '',
    this.write = false,
    this.provider = '',
  });

  final List<FsObject> content;
  final int total;
  final String readme;
  final bool write;
  final String provider;

  factory FsListResult.fromJson(Map<String, dynamic> j) => FsListResult(
        content: ((j['content'] as List?) ?? const [])
            .map((e) => FsObject.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        total: _int(j['total']),
        readme: _str(j['readme']),
        write: j['write'] == true,
        provider: _str(j['provider']),
      );
}

/// Task states from `github.com/OpenListTeam/tache`.
class TaskState {
  static const pending = 0;
  static const running = 1;
  static const succeeded = 2;
  static const canceling = 3;
  static const canceled = 4;
  static const errored = 5;
  static const failing = 6;
  static const failed = 7;
  static const waitingRetry = 8;
  static const beforeRetry = 9;
}

class TaskInfo {
  TaskInfo({
    required this.id,
    required this.name,
    required this.state,
    this.creator = '',
    this.status = '',
    this.progress = 0,
    this.startTime,
    this.endTime,
    this.totalBytes = 0,
    this.error = '',
  });

  final String id;
  final String name;
  final String creator;
  final int state;
  final String status;
  final double progress;
  final DateTime? startTime;
  final DateTime? endTime;
  final int totalBytes;
  final String error;

  bool get isActive =>
      state == TaskState.pending ||
      state == TaskState.running ||
      state == TaskState.canceling ||
      state == TaskState.waitingRetry ||
      state == TaskState.beforeRetry;

  bool get canRetry =>
      state == TaskState.failed ||
      state == TaskState.errored ||
      state == TaskState.canceled;

  factory TaskInfo.fromJson(Map<String, dynamic> j) => TaskInfo(
        id: _str(j['id']),
        name: _str(j['name']),
        creator: _str(j['creator']),
        state: _int(j['state']),
        status: _str(j['status']),
        progress: _double(j['progress']),
        startTime: _time(j['start_time']),
        endTime: _time(j['end_time']),
        totalBytes: _int(j['total_bytes']),
        error: _str(j['error']),
      );
}

/// Storage keeps the raw JSON so updates round-trip fields this client does
/// not model (cache policies, proxy options, ...).
class Storage {
  Storage(Map<String, dynamic> raw) : raw = Map<String, dynamic>.from(raw);

  final Map<String, dynamic> raw;

  int get id => _int(raw['id']);
  String get mountPath => _str(raw['mount_path']);
  String get driver => _str(raw['driver']);
  String get status => _str(raw['status']);
  String get remark => _str(raw['remark']);
  int get order => _int(raw['order']);
  bool get disabled => raw['disabled'] == true;
  DateTime? get modified => _time(raw['modified']);

  /// Driver-specific options, stored by the core as a JSON string.
  String get addition => _str(raw['addition']);

  bool get isWorking => status == 'work';

  factory Storage.fromJson(Map<String, dynamic> j) => Storage(j);

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(raw);
}

/// One configurable field of a driver (`internal/driver/item.go`).
class DriverItem {
  DriverItem({
    required this.name,
    required this.type,
    this.defaultValue = '',
    this.options = '',
    this.required = false,
    this.help = '',
  });

  final String name;

  /// One of `string`, `number`, `float`, `bool`, `select`, `text`.
  final String type;
  final String defaultValue;
  final String options;
  final bool required;
  final String help;

  List<String> get optionList =>
      options.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  factory DriverItem.fromJson(Map<String, dynamic> j) => DriverItem(
        name: _str(j['name']),
        type: _str(j['type']),
        defaultValue: _str(j['default']),
        options: _str(j['options']),
        required: j['required'] == true,
        help: _str(j['help']),
      );
}

class DriverInfo {
  DriverInfo({required this.common, required this.additional, this.config});

  final List<DriverItem> common;
  final List<DriverItem> additional;
  final Map<String, dynamic>? config;

  static List<DriverItem> _items(dynamic v) => ((v as List?) ?? const [])
      .map((e) => DriverItem.fromJson(Map<String, dynamic>.from(e)))
      .toList();

  factory DriverInfo.fromJson(Map<String, dynamic> j) => DriverInfo(
        common: _items(j['common']),
        additional: _items(j['additional']),
        config: j['config'] is Map
            ? Map<String, dynamic>.from(j['config'])
            : null,
      );

  /// Driver notice from `config.alert` (`info|warning|danger|success|text`).
  String get alertLevel {
    final a = _str(config?['alert']);
    final i = a.indexOf('|');
    return i < 0 ? '' : a.substring(0, i);
  }

  String get alertText {
    final a = _str(config?['alert']);
    final i = a.indexOf('|');
    return i < 0 ? a : a.substring(i + 1);
  }

  bool get noUpload => config?['no_upload'] == true;
}

class UserRole {
  static const general = 0;
  static const guest = 1;
  static const admin = 2;
}

class UserInfo {
  UserInfo({
    required this.id,
    required this.username,
    required this.role,
    this.basePath = '/',
    this.permission = 0,
    this.otp = false,
  });

  final int id;
  final String username;
  final int role;
  final String basePath;
  final int permission;
  final bool otp;

  bool get isAdmin => role == UserRole.admin;
  bool get isGuest => role == UserRole.guest;

  factory UserInfo.fromJson(Map<String, dynamic> j) => UserInfo(
        id: _int(j['id']),
        username: _str(j['username']),
        role: _int(j['role']),
        basePath: _str(j['base_path']).isEmpty ? '/' : _str(j['base_path']),
        permission: _int(j['permission']),
        otp: j['otp'] == true,
      );
}

/// One hit from `/api/fs/search`.
class SearchHit {
  SearchHit({
    required this.parent,
    required this.name,
    required this.isDir,
    this.size = 0,
    this.type = ObjType.unknown,
  });

  final String parent;
  final String name;
  final bool isDir;
  final int size;
  final int type;

  String get path => parent == '/' ? '/$name' : '$parent/$name';

  factory SearchHit.fromJson(Map<String, dynamic> j) => SearchHit(
        parent: _str(j['parent']).isEmpty ? '/' : _str(j['parent']),
        name: _str(j['name']),
        isDir: j['is_dir'] == true,
        size: _int(j['size']),
        type: _int(j['type']),
      );
}

/// User permission bits (`internal/model/user.go`).
class UserPerm {
  static const seeHides = 0;
  static const accessWithoutPassword = 1;
  static const offlineDownload = 2;
  static const write = 3;
  static const rename = 4;
  static const move = 5;
  static const copy = 6;
  static const remove = 7;
  static const webdavRead = 8;
  static const webdavManage = 9;
  static const ftpAccess = 10;
  static const ftpManage = 11;
  static const readArchives = 12;
  static const decompress = 13;
  static const share = 14;
  static const customShareId = 15;

  static const all = [
    seeHides, accessWithoutPassword, offlineDownload, write, rename, move, //
    copy, remove, webdavRead, webdavManage, ftpAccess, ftpManage,
    readArchives, decompress, share, customShareId,
  ];
}

/// Admin view of a user; keeps the raw JSON so updates round-trip fields
/// this client does not model (sso_id, otp secret flags, ...).
class AdminUser {
  AdminUser(Map<String, dynamic> raw) : raw = Map<String, dynamic>.from(raw);

  final Map<String, dynamic> raw;

  int get id => _int(raw['id']);
  String get username => _str(raw['username']);
  String get basePath => _str(raw['base_path']).isEmpty ? '/' : _str(raw['base_path']);
  int get role => _int(raw['role']);
  bool get disabled => raw['disabled'] == true;
  int get permission => _int(raw['permission']);

  bool get isAdmin => role == UserRole.admin;
  bool get isGuest => role == UserRole.guest;
  bool can(int bit) => (permission >> bit) & 1 == 1;

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(j);

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(raw);
}

/// One site setting (`internal/model/setting.go`).
class SettingItem {
  SettingItem(Map<String, dynamic> raw) : raw = Map<String, dynamic>.from(raw);

  final Map<String, dynamic> raw;

  String get key => _str(raw['key']);
  String get value => _str(raw['value']);
  set value(String v) => raw['value'] = v;
  String get help => _str(raw['help']);

  /// `string`, `number`, `bool`, `select` or `text`.
  String get type => _str(raw['type']);
  int get group => _int(raw['group']);
  int get flag => _int(raw['flag']);

  /// Flag 2 marks read-only settings, 3 deprecated ones.
  bool get readOnly => flag == 2;
  bool get deprecated => flag == 3;

  List<String> get optionList => _str(raw['options'])
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  factory SettingItem.fromJson(Map<String, dynamic> j) => SettingItem(j);

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(raw);
}
