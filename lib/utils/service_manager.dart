import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// 服务管理器 - 管理OpenList后台服务的启动、停止和状态监控
class ServiceManager {
  static const String _channelName = 'com.openlist.mobile/service';
  static const MethodChannel _channel = MethodChannel(_channelName);
  
  static ServiceManager? _instance;
  static ServiceManager get instance => _instance ??= ServiceManager._();
  
  ServiceManager._();
  
  // 服务状态流控制器
  final StreamController<bool> _serviceStatusController = StreamController<bool>.broadcast();
  
  /// 服务状态流
  Stream<bool> get serviceStatusStream => _serviceStatusController.stream;
  
  bool _isServiceRunning = false;
  Timer? _statusCheckTimer;
  
  /// 当前服务是否运行
  bool get isServiceRunning => _isServiceRunning;
  
  /// 初始化服务管理器
  Future<void> initialize() async {
    if (!Platform.isAndroid) return;
    
    try {
      // 设置方法调用处理器
      _channel.setMethodCallHandler(_handleMethodCall);
      
      // 开始定期检查服务状态
      _startStatusCheck();
      
      // 初始检查服务状态
      await checkServiceStatus();
      
      debugPrint('ServiceManager initialized');
    } catch (e) {
      debugPrint('Failed to initialize ServiceManager: $e');
    }
  }
  
  /// 处理来自原生端的方法调用
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    debugPrint('ServiceManager received method call: ${call.method}');
    switch (call.method) {
      case 'onServiceStatusChanged':
        final bool isRunning = call.arguments['isRunning'] ?? false;
        debugPrint('ServiceManager status change notification: $isRunning');
        _updateServiceStatus(isRunning);
        break;
      default:
        debugPrint('Unknown method call: ${call.method}');
    }
  }
  
  /// 启动OpenList服务
  Future<bool> startService() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final bool result = await _channel.invokeMethod('startService');
      debugPrint('Start service result: $result');
      
      // 延迟检查状态，给服务启动时间
      Timer(const Duration(seconds: 2), () => checkServiceStatus());
      
      return result;
    } catch (e) {
      debugPrint('Failed to start service: $e');
      return false;
    }
  }
  
  /// 停止OpenList服务
  Future<bool> stopService() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final bool result = await _channel.invokeMethod('stopService');
      debugPrint('Stop service result: $result');
      
      // 立即更新状态为停止
      if (result) {
        _updateServiceStatus(false);
      }
      
      // 延迟检查状态，确认服务已停止
      Timer(const Duration(seconds: 1), () => checkServiceStatus());
      
      return result;
    } catch (e) {
      debugPrint('Failed to stop service: $e');
      return false;
    }
  }
  
  /// 检查服务状态
  Future<bool> checkServiceStatus() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final bool isRunning = await _channel.invokeMethod('isServiceRunning');
      _updateServiceStatus(isRunning);
      return isRunning;
    } catch (e) {
      debugPrint('Failed to check service status: $e');
      return false;
    }
  }
  
  /// 重启服务
  Future<bool> restartService() async {
    if (!Platform.isAndroid) return false;
    
    try {
      await stopService();
      await Future.delayed(const Duration(seconds: 2));
      return await startService();
    } catch (e) {
      debugPrint('Failed to restart service: $e');
      return false;
    }
  }
  
  /// 检查是否在电池优化白名单中
  Future<bool> isBatteryOptimizationIgnored() async {
    if (!Platform.isAndroid) return true;
    
    try {
      final bool result = await _channel.invokeMethod('isBatteryOptimizationIgnored');
      return result;
    } catch (e) {
      debugPrint('Failed to check battery optimization status: $e');
      return false;
    }
  }
  
  /// 请求忽略电池优化
  Future<bool> requestIgnoreBatteryOptimization() async {
    if (!Platform.isAndroid) return true;
    
    try {
      final bool result = await _channel.invokeMethod('requestIgnoreBatteryOptimization');
      return result;
    } catch (e) {
      debugPrint('Failed to request battery optimization exemption: $e');
      return false;
    }
  }
  
  /// 打开电池优化设置
  Future<bool> openBatteryOptimizationSettings() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final bool result = await _channel.invokeMethod('openBatteryOptimizationSettings');
      return result;
    } catch (e) {
      debugPrint('Failed to open battery optimization settings: $e');
      return false;
    }
  }
  
  /// 打开自启动设置
  Future<bool> openAutoStartSettings() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final bool result = await _channel.invokeMethod('openAutoStartSettings');
      return result;
    } catch (e) {
      debugPrint('Failed to open auto start settings: $e');
      return false;
    }
  }
  
  /// 获取服务地址
  Future<String> getServiceAddress() async {
    if (!Platform.isAndroid) return '';
    
    try {
      final String address = await _channel.invokeMethod('getServiceAddress');
      return address;
    } catch (e) {
      debugPrint('Failed to get service address: $e');
      return '';
    }
  }
  
  /// 开始定期检查服务状态
  void _startStatusCheck() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      checkServiceStatus();
    });
  }
  
  /// 停止状态检查
  void _stopStatusCheck() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = null;
  }
  
  /// 更新服务状态
  void _updateServiceStatus(bool isRunning) {
    if (_isServiceRunning != isRunning) {
      _isServiceRunning = isRunning;
      _serviceStatusController.add(isRunning);
      debugPrint('Service status changed: $isRunning');
    }
  }
  
  /// 释放资源
  void dispose() {
    _stopStatusCheck();
    _serviceStatusController.close();
  }
}