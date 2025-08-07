class Storage {
  final int? id;
  final String mountPath;
  final int order;
  final String driver;
  final int cacheExpiration;
  final String status;
  final String addition;
  final String remark;
  final DateTime? modified;
  final bool disabled;
  final bool disableIndex;
  final bool enableSign;
  final String orderBy;
  final String orderDirection;
  final String extractFolder;
  final bool webProxy;
  final String webdavPolicy;
  final bool proxyRange;
  final String downProxyURL;
  final bool disableProxySign;

  Storage({
    this.id,
    required this.mountPath,
    this.order = 0,
    required this.driver,
    this.cacheExpiration = 30,
    this.status = '',
    this.addition = '',
    this.remark = '',
    this.modified,
    this.disabled = false,
    this.disableIndex = false,
    this.enableSign = false,
    this.orderBy = 'name',
    this.orderDirection = 'asc',
    this.extractFolder = '',
    this.webProxy = false,
    this.webdavPolicy = '',
    this.proxyRange = false,
    this.downProxyURL = '',
    this.disableProxySign = false,
  });

  factory Storage.fromJson(Map<String, dynamic> json) {
    return Storage(
      id: json['id'],
      mountPath: json['mount_path'] ?? '',
      order: json['order'] ?? 0,
      driver: json['driver'] ?? '',
      cacheExpiration: json['cache_expiration'] ?? 30,
      status: json['status'] ?? '',
      addition: json['addition'] ?? '',
      remark: json['remark'] ?? '',
      modified: json['modified'] != null ? DateTime.parse(json['modified']) : null,
      disabled: json['disabled'] ?? false,
      disableIndex: json['disable_index'] ?? false,
      enableSign: json['enable_sign'] ?? false,
      orderBy: json['order_by'] ?? 'name',
      orderDirection: json['order_direction'] ?? 'asc',
      extractFolder: json['extract_folder'] ?? '',
      webProxy: json['web_proxy'] ?? false,
      webdavPolicy: json['webdav_policy'] ?? '',
      proxyRange: json['proxy_range'] ?? false,
      downProxyURL: json['down_proxy_url'] ?? '',
      disableProxySign: json['disable_proxy_sign'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'mount_path': mountPath,
      'order': order,
      'driver': driver,
      'cache_expiration': cacheExpiration,
      'status': status,
      'addition': addition,
      'remark': remark,
      if (modified != null) 'modified': modified!.toIso8601String(),
      'disabled': disabled,
      'disable_index': disableIndex,
      'enable_sign': enableSign,
      'order_by': orderBy,
      'order_direction': orderDirection,
      'extract_folder': extractFolder,
      'web_proxy': webProxy,
      'webdav_policy': webdavPolicy,
      'proxy_range': proxyRange,
      'down_proxy_url': downProxyURL,
      'disable_proxy_sign': disableProxySign,
    };
  }

  Storage copyWith({
    int? id,
    String? mountPath,
    int? order,
    String? driver,
    int? cacheExpiration,
    String? status,
    String? addition,
    String? remark,
    DateTime? modified,
    bool? disabled,
    bool? disableIndex,
    bool? enableSign,
    String? orderBy,
    String? orderDirection,
    String? extractFolder,
    bool? webProxy,
    String? webdavPolicy,
    bool? proxyRange,
    String? downProxyURL,
    bool? disableProxySign,
  }) {
    return Storage(
      id: id ?? this.id,
      mountPath: mountPath ?? this.mountPath,
      order: order ?? this.order,
      driver: driver ?? this.driver,
      cacheExpiration: cacheExpiration ?? this.cacheExpiration,
      status: status ?? this.status,
      addition: addition ?? this.addition,
      remark: remark ?? this.remark,
      modified: modified ?? this.modified,
      disabled: disabled ?? this.disabled,
      disableIndex: disableIndex ?? this.disableIndex,
      enableSign: enableSign ?? this.enableSign,
      orderBy: orderBy ?? this.orderBy,
      orderDirection: orderDirection ?? this.orderDirection,
      extractFolder: extractFolder ?? this.extractFolder,
      webProxy: webProxy ?? this.webProxy,
      webdavPolicy: webdavPolicy ?? this.webdavPolicy,
      proxyRange: proxyRange ?? this.proxyRange,
      downProxyURL: downProxyURL ?? this.downProxyURL,
      disableProxySign: disableProxySign ?? this.disableProxySign,
    );
  }
}

class PageResponse<T> {
  final List<T> content;
  final int total;

  PageResponse({
    required this.content,
    required this.total,
  });

  factory PageResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    return PageResponse(
      content: (json['content'] as List<dynamic>)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] ?? 0,
    );
  }
}

class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;

  ApiResponse({
    required this.code,
    required this.message,
    this.data,
  });

  bool get isSuccess => code == 200;

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>)? fromJsonT) {
    return ApiResponse(
      code: json['code'] ?? 0,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null 
          ? fromJsonT(json['data'] as Map<String, dynamic>)
          : json['data'] as T?,
    );
  }
}
