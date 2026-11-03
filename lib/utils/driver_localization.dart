/// Localized display text for metadata returned by known storage drivers.
///
/// Driver identifiers, field names, and option values are matched exactly. API
/// values remain untouched; unknown metadata is always shown verbatim.
class DriverLocalization {
  const DriverLocalization._();

  static const _fields = <String, Map<String, String>>{
    'Aliyundrive': {
      'refresh_token': '刷新令牌',
      'root_folder_id': '根目录 ID',
      'order_by': '排序方式',
      'order_direction': '排序方向',
      'rapid_upload': '快速上传',
    },
    'BaiduNetdisk': {
      'refresh_token': '刷新令牌',
      'root_folder_id': '根目录 ID',
      'order_by': '排序方式',
      'order_direction': '排序方向',
    },
    'GoogleDrive': {
      'client_id': '客户端 ID',
      'client_secret': '客户端密钥',
      'refresh_token': '刷新令牌',
      'root_folder_id': '根目录 ID',
    },
    'Onedrive': {
      'client_id': '客户端 ID',
      'client_secret': '客户端密钥',
      'refresh_token': '刷新令牌',
      'root_folder_id': '根目录 ID',
      'region': '区域',
    },
    'S3': {
      'endpoint': '端点',
      'region': '区域',
      'bucket': '存储桶',
      'access_key_id': '访问密钥 ID',
      'secret_access_key': '访问密钥',
      'session_token': '会话令牌',
      'root': '根目录',
      'force_path_style': '强制路径样式',
    },
    'WebDav': {
      'address': '地址',
      'username': '用户名',
      'password': '密码',
      'vendor': '服务类型',
      'tls_insecure_skip_verify': '跳过 TLS 证书验证',
    },
    'Local': {
      'root': '根目录',
      'enable_signature': '启用签名验证',
    },
    '123Pan': {
      'authorization': '授权令牌',
      'root_folder_id': '根目录 ID',
    },
    'Quark': {
      'cookie': 'Cookie',
      'root_folder_id': '根目录 ID',
    },
    'PikPak': {
      'username': '用户名',
      'password': '密码',
      'refresh_token': '刷新令牌',
      'root_folder_id': '根目录 ID',
    },
    'FTP': {
      'host': '主机',
      'port': '端口',
      'username': '用户名',
      'password': '密码',
      'root': '根目录',
      'tls': '启用 TLS',
    },
    'SMB': {
      'host': '主机',
      'port': '端口',
      'username': '用户名',
      'password': '密码',
      'share_name': '共享名称',
      'root': '根目录',
      'domain': '域',
    },
  };

  static const _options = <String, Map<String, Map<String, String>>>{
    'Aliyundrive': {
      'order_direction': {'ASC': '升序', 'DESC': '降序'},
    },
    'BaiduNetdisk': {
      'order_direction': {'ASC': '升序', 'DESC': '降序'},
    },
    'WebDav': {
      'vendor': {
        'Other': '其他',
        'other': '其他',
        'sharepoint': 'SharePoint',
        'Nextcloud': 'Nextcloud',
        'Owncloud': 'ownCloud',
        'Sharepoint': 'SharePoint',
      },
    },
  };

  static const _alerts = <String, Map<String, String>>{
    'Aliyundrive': {
      '请在阿里云盘开放平台创建应用并填写 refresh_token。': '请在阿里云盘开放平台创建应用并填写刷新令牌。',
    },
  };

  static String fieldLabel({
    required String languageCode,
    required String driver,
    required String field,
    required String fallback,
  }) =>
      _translate(_fields[driver]?[field], languageCode, fallback);

  static String optionLabel({
    required String languageCode,
    required String driver,
    required String field,
    required String option,
  }) =>
      _translate(_options[driver]?[field]?[option], languageCode, option);

  static String alertText({
    required String languageCode,
    required String driver,
    required String text,
  }) =>
      _translate(_alerts[driver]?[text], languageCode, text);

  static String _translate(
      String? translated, String languageCode, String fallback) {
    if (languageCode.toLowerCase().startsWith('zh') && translated != null) {
      return translated;
    }
    return fallback;
  }
}
