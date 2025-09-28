import 'dart:io';
import 'dart:developer';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart' as getx;
import 'download_manager.dart';
import '../pages/download_manager_page.dart';
import '../generated/l10n.dart';

class NotificationManager {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static const int _downloadNotificationId = 1000;
  
  /// 初始化通知
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Android 初始化设置
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS 初始化设置
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // 请求通知权限
      if (Platform.isAndroid) {
        await _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } else if (Platform.isIOS) {
        await _notifications
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      }

      _isInitialized = true;
      log('通知管理器初始化成功');
    } catch (e) {
      log('通知管理器初始化失败: $e');
    }
  }

  /// 处理通知点击事件
  static void _onNotificationTapped(NotificationResponse response) {
    log('通知被点击: ${response.payload}');
    
    // 跳转到下载管理页面
    if (getx.Get.context != null) {
      getx.Get.to(() => const DownloadManagerPage());
    }
  }

  /// 显示或更新下载进度通知
  static Future<void> showDownloadProgressNotification() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      List<DownloadTask> activeTasks = DownloadManager.activeTasks
          .where((task) => task.status == DownloadStatus.downloading)
          .toList();

      if (activeTasks.isEmpty) {
        // 没有活跃下载任务，取消通知
        await _notifications.cancel(_downloadNotificationId);
        return;
      }

      String title;
      String body;
      int progress = 0;
      int maxProgress = 100;

      if (activeTasks.length == 1) {
        // 单个文件下载
        DownloadTask task = activeTasks.first;
        title = S.current.currentlyDownloading;
        body = task.filename;
        progress = (task.progress * 100).round();
      } else {
        // 多个文件下载
        title = S.current.currentlyDownloading;
        body = S.current.currentDownloadingFiles(activeTasks.length);
        
        // 计算总进度 - 所有文件下载进度的总和
        double totalProgress = 0;
        
        for (DownloadTask task in activeTasks) {
          totalProgress += task.progress;
        }
        
        // 总进度条为所有文件进度的平均值
        double avgProgress = totalProgress / activeTasks.length;
        progress = (avgProgress * 100).round();
      }

      // Android 通知详情
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'download_channel',
        S.current.downloadProgressChannel,
        channelDescription: S.current.downloadProgressDesc,
        importance: Importance.low,
        priority: Priority.low,
        showProgress: true,
        maxProgress: maxProgress,
        progress: progress,
        ongoing: true, // 常驻通知
        autoCancel: false,
        playSound: false,
        enableVibration: false,
        icon: '@mipmap/ic_launcher',
        actions: [
          AndroidNotificationAction(
            'view_downloads',
            S.current.viewDownloads,
            showsUserInterface: true,
          ),
        ],
      );

      // iOS 通知详情
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        _downloadNotificationId,
        title,
        body,
        notificationDetails,
        payload: 'download_progress',
      );

    } catch (e) {
      log('显示下载进度通知失败: $e');
    }
  }

  /// 显示下载完成通知
  static Future<void> showDownloadCompleteNotification() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // 检查是否还有其他下载任务在进行
      bool hasActiveDownloads = DownloadManager.activeTasks.isNotEmpty;

      if (hasActiveDownloads) {
        // 还有其他下载在进行，不显示完成通知，继续显示进度通知
        await showDownloadProgressNotification();
        return;
      }

      // 先取消进度通知
      await _notifications.cancel(_downloadNotificationId);

      // 获取最近完成的任务数量
      List<DownloadTask> completedTasks = DownloadManager.completedTasks
          .where((task) => task.status == DownloadStatus.completed)
          .toList();

      if (completedTasks.isEmpty) return;

      String title;
      String body;

      if (completedTasks.length == 1) {
        // 单个文件完成
        DownloadTask task = completedTasks.first;
        title = S.current.downloadCompleteNotificationTitle(task.filename);
        body = S.current.clickToJumpToDownloadManager;
      } else {
        // 多个文件完成
        title = S.current.downloadCompleteTitle;
        body = S.current.multipleFilesCompleted(completedTasks.length);
      }

      // Android 通知详情
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'download_complete_channel',
        S.current.downloadCompleteChannel,
        channelDescription: S.current.downloadCompleteChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        autoCancel: true,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        actions: [
          AndroidNotificationAction(
            'open_downloads',
            S.current.openDownloadManager,
            showsUserInterface: true,
          ),
        ],
      );

      // iOS 通知详情
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        _downloadNotificationId + 1,
        title,
        body,
        notificationDetails,
        payload: 'download_complete',
      );

    } catch (e) {
      log('显示下载完成通知失败: $e');
    }
  }

  /// 显示单个文件下载完成通知
  static Future<void> showSingleFileCompleteNotification(DownloadTask task) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // 检查是否还有其他下载任务在进行
      bool hasActiveDownloads = DownloadManager.activeTasks.isNotEmpty;

      if (hasActiveDownloads) {
        // 还有其他下载在进行，更新进度通知
        await showDownloadProgressNotification();
        return;
      }

      // 先取消进度通知
      await _notifications.cancel(_downloadNotificationId);

      String title = S.current.downloadCompleteNotificationTitle(task.filename);
      String body = S.current.clickToJumpToDownloadManager;

      // Android 通知详情
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'download_complete_channel',
        S.current.downloadCompleteChannel,
        channelDescription: S.current.downloadCompleteChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        autoCancel: true,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        actions: [
          AndroidNotificationAction(
            'open_downloads',
            S.current.openDownloadManager,
            showsUserInterface: true,
          ),
        ],
      );

      // iOS 通知详情
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        _downloadNotificationId + 1,
        title,
        body,
        notificationDetails,
        payload: 'download_complete',
      );

    } catch (e) {
      log('显示单个文件下载完成通知失败: $e');
    }
  }

  /// 取消下载通知
  static Future<void> cancelDownloadNotification() async {
    try {
      await _notifications.cancel(_downloadNotificationId);
    } catch (e) {
      log('取消下载通知失败: $e');
    }
  }

  /// 取消所有通知
  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      log('取消所有通知失败: $e');
    }
  }

  /// 格式化字节大小
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}