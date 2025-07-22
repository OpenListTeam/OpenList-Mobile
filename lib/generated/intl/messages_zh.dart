// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'zh';

  static String m0(error) => "取消所有通知失败: ${error}";

  static String m1(error) => "取消下载通知失败: ${error}";

  static String m2(error) => "检查安装权限失败: ${error}";

  static String m3(error) => "清理下载目录失败: ${error}";

  static String m4(filename) => "确定要取消下载 \"${filename}\" 吗？";

  static String m5(filename) => "确定要删除文件 \"${filename}\" 吗？此操作不可撤销。";

  static String m6(filename) => "确定要删除 \"${filename}\" 的下载记录吗？";

  static String m7(error) => "创建OpenList目录失败: ${error}";

  static String m8(path) => "创建OpenList下载目录: ${path}";

  static String m9(count) => "当前有 ${count} 个文件在下载";

  static String m10(error) => "删除文件失败: ${error}";

  static String m11(url) => "下载已取消: ${url}";

  static String m12(filename) => "下载完成: ${filename}";

  static String m13(filename) => "${filename} 下载完毕";

  static String m14(filename) => "下载失败: ${filename}";

  static String m15(count) => "下载管理(${count})";

  static String m16(progress) => "下载进度";

  static String m17(filename) => "已删除文件: ${filename}";

  static String m18(error) => "获取下载目录失败: ${error}";

  static String m19(error) => "获取下载文件列表失败: ${error}";

  static String m20(count) => "${count} 个文件已完成，点击跳转到下载管理";

  static String m21(payload) => "通知被点击: ${payload}";

  static String m22(error) => "通知管理器初始化失败: ${error}";

  static String m23(error) => "打开文件异常: ${error}";

  static String m24(error) => "打开文件失败: ${error}";

  static String m25(type, message) => "打开文件结果: ${type} - ${message}";

  static String m26(path) => "OpenList下载目录: ${path}";

  static String m27(error) => "解析文件名失败: ${error}";

  static String m28(error) => "显示下载完成通知失败: ${error}";

  static String m29(error) => "显示下载进度通知失败: ${error}";

  static String m30(error) => "显示单个文件下载完成通知失败: ${error}";

  static String m31(filename) => "开始下载: ${filename}";

  static String m32(path) => "尝试打开文件: ${path}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "about": MessageLookupByLibrary.simpleMessage("关于"),
        "appName": MessageLookupByLibrary.simpleMessage("OpenList"),
        "autoCheckForUpdates": MessageLookupByLibrary.simpleMessage("自动检查更新"),
        "autoCheckForUpdatesDesc":
            MessageLookupByLibrary.simpleMessage("启动时自动检查更新"),
        "autoStartWebPage": MessageLookupByLibrary.simpleMessage("将网页设置为打开首页"),
        "autoStartWebPageDesc":
            MessageLookupByLibrary.simpleMessage("打开主界面时的首页"),
        "bootAutoStartService": MessageLookupByLibrary.simpleMessage("开机自启动服务"),
        "bootAutoStartServiceDesc": MessageLookupByLibrary.simpleMessage(
            "在开机后自动启动OpenList服务。（请确保授予自启动权限）"),
        "browserDownload": MessageLookupByLibrary.simpleMessage("浏览器下载"),
        "cancel": MessageLookupByLibrary.simpleMessage("取消"),
        "cancelAllNotificationsFailed": m0,
        "cancelDownload": MessageLookupByLibrary.simpleMessage("取消下载"),
        "cancelDownloadNotificationFailed": m1,
        "cancelled": MessageLookupByLibrary.simpleMessage("已取消"),
        "cannotGetBaseDownloadDirectory":
            MessageLookupByLibrary.simpleMessage("无法获取基础下载目录"),
        "cannotGetDownloadDirectory":
            MessageLookupByLibrary.simpleMessage("无法获取下载目录"),
        "cannotInstallApkFile": MessageLookupByLibrary.simpleMessage(
            "无法安装 APK 文件，可能需要在设置中开启\"允许安装未知来源应用\""),
        "checkForUpdates": MessageLookupByLibrary.simpleMessage("检查更新"),
        "checkInstallPermissionFailed": m2,
        "clear": MessageLookupByLibrary.simpleMessage("清空"),
        "clearAll": MessageLookupByLibrary.simpleMessage("清空所有"),
        "clearDownloadDirectoryFailed": m3,
        "clearFailed": MessageLookupByLibrary.simpleMessage("清空失败"),
        "clearRecords": MessageLookupByLibrary.simpleMessage("清空记录"),
        "cleared": MessageLookupByLibrary.simpleMessage("已清空下载目录"),
        "clickToJumpToDownloadManager":
            MessageLookupByLibrary.simpleMessage("点击跳转到下载管理"),
        "completed": MessageLookupByLibrary.simpleMessage("已完成"),
        "completedTime": MessageLookupByLibrary.simpleMessage("完成时间"),
        "confirm": MessageLookupByLibrary.simpleMessage("确认"),
        "confirmCancelDownload": m4,
        "confirmClear": MessageLookupByLibrary.simpleMessage("确认清空"),
        "confirmClearAllFiles":
            MessageLookupByLibrary.simpleMessage("确定要清空所有下载文件吗？此操作不可撤销。"),
        "confirmDelete": MessageLookupByLibrary.simpleMessage("确认删除"),
        "confirmDeleteFile": m5,
        "confirmDeleteRecord": m6,
        "continueDownload": MessageLookupByLibrary.simpleMessage("继续下载"),
        "copiedToClipboard": MessageLookupByLibrary.simpleMessage("已复制到剪贴板"),
        "createOpenListDirectoryFailed": m7,
        "createOpenListDownloadDirectory": m8,
        "currentDownloadingFiles": m9,
        "currentIsLatestVersion":
            MessageLookupByLibrary.simpleMessage("已经是最新版本"),
        "dataDirectory": MessageLookupByLibrary.simpleMessage("data 文件夹路径"),
        "delete": MessageLookupByLibrary.simpleMessage("删除"),
        "deleteFailed": MessageLookupByLibrary.simpleMessage("删除失败"),
        "deleteFile": MessageLookupByLibrary.simpleMessage("删除文件"),
        "deleteFileFailedLog": m10,
        "deleteRecord": MessageLookupByLibrary.simpleMessage("删除记录"),
        "desktopShortcut": MessageLookupByLibrary.simpleMessage("桌面快捷方式"),
        "directDownload": MessageLookupByLibrary.simpleMessage("直接下载"),
        "directDownloadApk": MessageLookupByLibrary.simpleMessage("直接下载APK"),
        "download": MessageLookupByLibrary.simpleMessage("下载"),
        "downloadApk": MessageLookupByLibrary.simpleMessage("下载APK"),
        "downloadCancelled": m11,
        "downloadCancelledStatus":
            MessageLookupByLibrary.simpleMessage("下载已取消"),
        "downloadComplete": m12,
        "downloadCompleteChannel": MessageLookupByLibrary.simpleMessage("下载完成"),
        "downloadCompleteChannelDesc":
            MessageLookupByLibrary.simpleMessage("文件下载完成通知"),
        "downloadCompleteNotificationTitle": m13,
        "downloadCompleteTitle": MessageLookupByLibrary.simpleMessage("下载完成"),
        "downloadDirectory": MessageLookupByLibrary.simpleMessage("下载目录"),
        "downloadDirectoryCleared":
            MessageLookupByLibrary.simpleMessage("已清理下载目录"),
        "downloadFailed": MessageLookupByLibrary.simpleMessage("下载失败"),
        "downloadFailedWithError": m14,
        "downloadManager": MessageLookupByLibrary.simpleMessage("下载管理"),
        "downloadManagerWithCount": m15,
        "downloadProgress": m16,
        "downloadProgressDesc":
            MessageLookupByLibrary.simpleMessage("显示文件下载进度"),
        "downloadRecordsCleared":
            MessageLookupByLibrary.simpleMessage("已清空下载记录"),
        "downloadThisFile": MessageLookupByLibrary.simpleMessage("下载此文件吗？"),
        "downloading": MessageLookupByLibrary.simpleMessage("正在下载"),
        "failed": MessageLookupByLibrary.simpleMessage("失败"),
        "fileDeleted": MessageLookupByLibrary.simpleMessage("文件已删除"),
        "fileDeletedLog": m17,
        "fileInfo": MessageLookupByLibrary.simpleMessage("文件信息"),
        "fileLocation": MessageLookupByLibrary.simpleMessage("文件位置"),
        "fileLocationTip": MessageLookupByLibrary.simpleMessage(
            "您可以使用文件管理器找到此文件，或者尝试安装相应的应用来打开它。"),
        "fileName": MessageLookupByLibrary.simpleMessage("文件名"),
        "fileNotFound": MessageLookupByLibrary.simpleMessage("文件不存在或已被删除"),
        "filePath": MessageLookupByLibrary.simpleMessage("路径"),
        "fileSavedTo": MessageLookupByLibrary.simpleMessage("文件已保存到:"),
        "general": MessageLookupByLibrary.simpleMessage("通用"),
        "getDownloadDirectoryFailed": m18,
        "getDownloadFileListFailed": m19,
        "goTo": MessageLookupByLibrary.simpleMessage("前往"),
        "goToSettings": MessageLookupByLibrary.simpleMessage("去设置"),
        "grantManagerStoragePermission":
            MessageLookupByLibrary.simpleMessage("申请【所有文件访问权限】"),
        "grantNotificationPermission":
            MessageLookupByLibrary.simpleMessage("申请【通知权限】"),
        "grantNotificationPermissionDesc":
            MessageLookupByLibrary.simpleMessage("用于前台服务保活"),
        "grantStoragePermission":
            MessageLookupByLibrary.simpleMessage("申请【读写外置存储权限】"),
        "grantStoragePermissionDesc":
            MessageLookupByLibrary.simpleMessage("挂载本地存储时必须授予，否则无权限读写文件"),
        "importantSettings": MessageLookupByLibrary.simpleMessage("重要"),
        "inProgress": MessageLookupByLibrary.simpleMessage("进行中"),
        "initializingNotificationManager":
            MessageLookupByLibrary.simpleMessage("初始化通知管理器"),
        "jumpToOtherApp": MessageLookupByLibrary.simpleMessage("跳转到其他APP ？"),
        "loadDownloadFilesFailed":
            MessageLookupByLibrary.simpleMessage("加载下载文件失败"),
        "modifiedTime": MessageLookupByLibrary.simpleMessage("修改时间"),
        "modifyAdminPassword":
            MessageLookupByLibrary.simpleMessage("修改admin密码"),
        "moreOptions": MessageLookupByLibrary.simpleMessage("更多选项"),
        "multipleFilesCompleted": m20,
        "needInstallPermission": MessageLookupByLibrary.simpleMessage("需要安装权限"),
        "needInstallPermissionDesc": MessageLookupByLibrary.simpleMessage(
            "为了安装 APK 文件，需要授予安装权限。请在设置中手动开启。"),
        "needInstallPermissionToInstallApk":
            MessageLookupByLibrary.simpleMessage("需要安装权限才能安装 APK 文件"),
        "newVersionFound": MessageLookupByLibrary.simpleMessage("发现新版本"),
        "noActiveDownloads": MessageLookupByLibrary.simpleMessage("暂无进行中的下载"),
        "noAppToOpenFile":
            MessageLookupByLibrary.simpleMessage("没有找到可以打开此文件的应用"),
        "noCompletedDownloads":
            MessageLookupByLibrary.simpleMessage("暂无已完成的下载"),
        "noPermissionToInstallApk":
            MessageLookupByLibrary.simpleMessage("没有权限安装 APK 文件，请在设置中开启安装权限"),
        "noPermissionToOpenFile":
            MessageLookupByLibrary.simpleMessage("没有权限打开此文件"),
        "notificationClicked": m21,
        "notificationManagerInitFailed": m22,
        "notificationManagerInitialized":
            MessageLookupByLibrary.simpleMessage("通知管理器初始化成功"),
        "open": MessageLookupByLibrary.simpleMessage("打开"),
        "openDirectory": MessageLookupByLibrary.simpleMessage("打开目录"),
        "openDownloadManager": MessageLookupByLibrary.simpleMessage("打开下载管理"),
        "openFile": MessageLookupByLibrary.simpleMessage("打开文件"),
        "openFileException": m23,
        "openFileFailed": m24,
        "openFileResult": m25,
        "openListDownloadDirectory": m26,
        "parseFilenameFailed": m27,
        "pending": MessageLookupByLibrary.simpleMessage("等待中"),
        "preparingDownload": MessageLookupByLibrary.simpleMessage("准备下载..."),
        "refresh": MessageLookupByLibrary.simpleMessage("刷新"),
        "releasePage": MessageLookupByLibrary.simpleMessage("发布页面"),
        "selectAppToOpen": MessageLookupByLibrary.simpleMessage("选择应用打开"),
        "setAdminPassword": MessageLookupByLibrary.simpleMessage("设置admin密码"),
        "setDefaultDirectory":
            MessageLookupByLibrary.simpleMessage("是否设为初始目录？"),
        "settings": MessageLookupByLibrary.simpleMessage("设置"),
        "shareFeatureNotImplemented":
            MessageLookupByLibrary.simpleMessage("分享功能待实现"),
        "shareFile": MessageLookupByLibrary.simpleMessage("分享文件"),
        "showDownloadCompleteNotificationFailed": m28,
        "showDownloadProgressNotificationFailed": m29,
        "showSingleFileCompleteNotificationFailed": m30,
        "silentJumpApp": MessageLookupByLibrary.simpleMessage("静默跳转APP"),
        "silentJumpAppDesc":
            MessageLookupByLibrary.simpleMessage("跳转APP时，不弹出提示框"),
        "size": MessageLookupByLibrary.simpleMessage("大小"),
        "startDownload": m31,
        "startTime": MessageLookupByLibrary.simpleMessage("开始时间"),
        "tryToOpenFile": m32,
        "uiSettings": MessageLookupByLibrary.simpleMessage("界面"),
        "userCancelledDownload": MessageLookupByLibrary.simpleMessage("用户取消下载"),
        "viewDownloads": MessageLookupByLibrary.simpleMessage("查看下载"),
        "viewLocation": MessageLookupByLibrary.simpleMessage("查看位置"),
        "wakeLock": MessageLookupByLibrary.simpleMessage("唤醒锁"),
        "wakeLockDesc": MessageLookupByLibrary.simpleMessage(
            "开启防止锁屏后CPU休眠，保持进程在后台运行。（部分系统可能导致杀后台）"),
        "webPage": MessageLookupByLibrary.simpleMessage("网页")
      };
}
