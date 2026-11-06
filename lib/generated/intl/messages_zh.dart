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

  static String m0(count) => "重命名选中的 ${count} 个项目";

  static String m1(error) => "取消所有通知失败: ${error}";

  static String m2(error) => "取消下载通知失败: ${error}";

  static String m3(error) => "检查安装权限失败: ${error}";

  static String m4(error) => "清理下载目录失败: ${error}";

  static String m5(filename) => "确定要取消下载 \"${filename}\" 吗？";

  static String m6(filename) => "确定要删除文件 \"${filename}\" 吗？此操作不可撤销。";

  static String m7(names) => "确定删除 ${names}？";

  static String m8(filename) => "确定要删除 \"${filename}\" 的下载记录吗？";

  static String m9(name) => "确定删除存储 ${name}？";

  static String m10(name) => "删除用户 ${name}？";

  static String m11(error) => "创建OpenList目录失败: ${error}";

  static String m12(path) => "创建OpenList下载目录: ${path}";

  static String m13(count) => "当前有 ${count} 个文件在下载";

  static String m14(error) => "删除文件失败: ${error}";

  static String m15(count) => "删除 ${count} 个项目？";

  static String m16(name) => "删除存储 \"${name}\"？";

  static String m17(url) => "下载已取消: ${url}";

  static String m18(filename) => "下载完成: ${filename}";

  static String m19(filename) => "下载完成: ${filename}";

  static String m20(filename) => "${filename} 下载完毕";

  static String m21(filename) => "下载失败: ${filename}";

  static String m22(filename) => "下载失败: ${filename}";

  static String m23(count) => "下载管理(${count})";

  static String m24(progress) => "下载进度: ${progress}%";

  static String m25(current, total) => "正在下载第 ${current}/${total} 个文件";

  static String m26(error) => "复制失败: ${error}";

  static String m27(error) => "创建文件夹失败：${error}";

  static String m28(error) => "删除失败：${error}";

  static String m29(error) => "删除存储失败：${error}";

  static String m30(error) => "移动失败: ${error}";

  static String m31(error) => "切换存储状态失败：${error}";

  static String m32(filename) => "已删除文件: ${filename}";

  static String m33(index) => "第 ${index} 个文件下载失败";

  static String m34(size) => "大小: ${size}";

  static String m35(time) => "时间: ${time}";

  static String m36(error) => "获取下载目录失败: ${error}";

  static String m37(error) => "获取下载文件列表失败: ${error}";

  static String m38(line, error) => "JSON格式错误,第${line}行:${error}";

  static String m39(error) => "加载失败:${error}";

  static String m40(error) => "更改模式失败：${error}";

  static String m41(count) => "${count} 个文件已完成，点击跳转到下载管理";

  static String m42(payload) => "通知被点击: ${payload}";

  static String m43(error) => "通知管理器初始化失败: ${error}";

  static String m44(error) => "打开下载目录失败: ${error}";

  static String m45(error) => "打开文件异常: ${error}";

  static String m46(error) => "打开文件失败: ${error}";

  static String m47(error) => "打开文件管理器失败: ${error}";

  static String m48(type, message) => "打开文件结果: ${type} - ${message}";

  static String m49(path) => "OpenList下载目录: ${path}";

  static String m50(error) => "解析文件名失败: ${error}";

  static String m51(error) => "恢复备份失败:${error}";

  static String m52(error) => "保存失败:${error}";

  static String m53(count) => "${count} 已选择";

  static String m54(error) => "显示下载完成通知失败: ${error}";

  static String m55(error) => "显示下载进度通知失败: ${error}";

  static String m56(error) => "显示单个文件下载完成通知失败: ${error}";

  static String m57(filename) => "开始下载: ${filename}";

  static String m58(filename) => "开始下载: ${filename}";

  static String m59(action) => "存储已${action}";

  static String m60(path) => "尝试打开文件: ${path}";

  static String m61(name) => "正在上传 ${name}";

  static String m62(count) => "${count} 个上传进行中";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("关于"),
    "aboutOpenList": MessageLookupByLibrary.simpleMessage("关于 OpenList"),
    "account": MessageLookupByLibrary.simpleMessage("账户"),
    "addMediaFavorite": MessageLookupByLibrary.simpleMessage("添加到收藏"),
    "addStorage": MessageLookupByLibrary.simpleMessage("添加存储"),
    "addUser": MessageLookupByLibrary.simpleMessage("添加用户"),
    "addresses": MessageLookupByLibrary.simpleMessage("访问地址"),
    "adminOnly": MessageLookupByLibrary.simpleMessage("需要管理员权限"),
    "adminPasswordHint": MessageLookupByLibrary.simpleMessage("admin 密码"),
    "adminPasswordSetupMessage": MessageLookupByLibrary.simpleMessage(
      "本地核心已为 admin 账户生成随机密码。请设置你自己的密码，以便通过网页端或其他设备登录。",
    ),
    "adminPasswordSetupTitle": MessageLookupByLibrary.simpleMessage("设置管理员密码"),
    "adminPasswordUpdated": MessageLookupByLibrary.simpleMessage("admin 密码已更新"),
    "administration": MessageLookupByLibrary.simpleMessage("管理"),
    "administrator": MessageLookupByLibrary.simpleMessage("管理员"),
    "allSystemsOperational": MessageLookupByLibrary.simpleMessage("所有系统正常运行"),
    "apiToken": MessageLookupByLibrary.simpleMessage("API 令牌"),
    "apkDownloadCompleteMessage": MessageLookupByLibrary.simpleMessage(
      "APK文件已下载完成，是否要安装？",
    ),
    "appDetails": MessageLookupByLibrary.simpleMessage("应用详情"),
    "appName": MessageLookupByLibrary.simpleMessage("OpenList"),
    "appearance": MessageLookupByLibrary.simpleMessage("外观"),
    "archiveExtractionUnavailable": MessageLookupByLibrary.simpleMessage(
      "无法获取压缩包文件地址",
    ),
    "askForDownloadDirectory": MessageLookupByLibrary.simpleMessage(
      "每次下载选择保存位置",
    ),
    "askForDownloadDirectoryDesc": MessageLookupByLibrary.simpleMessage(
      "每次下载前询问文件保存位置",
    ),
    "autoCheckForUpdates": MessageLookupByLibrary.simpleMessage("自动检查更新"),
    "autoCheckForUpdatesDesc": MessageLookupByLibrary.simpleMessage(
      "启动时自动检查更新",
    ),
    "autoStartIssue": MessageLookupByLibrary.simpleMessage("自启动相关说明"),
    "autoStartIssueDesc": MessageLookupByLibrary.simpleMessage(
      "设置自启动时建议把app的电池优化一并关闭，当前在开启自启动后，系统重启时服务会自动在后台启动，但可能不会在通知栏弹出通知。请放心，服务已正常运行，您可以在通知栏快捷开关查看服务状态，或回到主界面查看服务开关确认服务是否已启动。",
    ),
    "autoStartSettings": MessageLookupByLibrary.simpleMessage("自启动设置"),
    "autoStartSettingsDesc": MessageLookupByLibrary.simpleMessage(
      "部分厂商系统需要允许自启动，否则会停止后台应用。",
    ),
    "autoStartWebPage": MessageLookupByLibrary.simpleMessage("将网页设置为打开首页"),
    "autoStartWebPageDesc": MessageLookupByLibrary.simpleMessage("打开主界面时的首页"),
    "back": MessageLookupByLibrary.simpleMessage("返回"),
    "backgroundRestricted": MessageLookupByLibrary.simpleMessage("系统限制了后台活动"),
    "backgroundRunning": MessageLookupByLibrary.simpleMessage("后台运行"),
    "backupRestored": MessageLookupByLibrary.simpleMessage("备份已恢复"),
    "basePath": MessageLookupByLibrary.simpleMessage("基础路径"),
    "batchDownloadComplete": MessageLookupByLibrary.simpleMessage("批量下载完成"),
    "batchRename": MessageLookupByLibrary.simpleMessage("批量重命名"),
    "batchRenameDesc": m0,
    "batteryOptimization": MessageLookupByLibrary.simpleMessage("电池优化"),
    "batteryOptimizationActive": MessageLookupByLibrary.simpleMessage(
      "受限制，系统可能会停止服务器。",
    ),
    "batteryOptimizationIgnored": MessageLookupByLibrary.simpleMessage("未限制"),
    "bootAutoStartService": MessageLookupByLibrary.simpleMessage("开机自启动服务"),
    "bootAutoStartServiceDesc": MessageLookupByLibrary.simpleMessage(
      "在开机后自动启动OpenList服务。（请确保授予自启动权限）",
    ),
    "browseFiles": MessageLookupByLibrary.simpleMessage("浏览文件"),
    "browseFunctionalityComingSoon": MessageLookupByLibrary.simpleMessage(
      "浏览功能即将推出",
    ),
    "browserDownload": MessageLookupByLibrary.simpleMessage("浏览器下载"),
    "browserDownloadMethod": MessageLookupByLibrary.simpleMessage("浏览器下载"),
    "browserDownloadMethodDesc": MessageLookupByLibrary.simpleMessage(
      "使用系统浏览器",
    ),
    "cache": MessageLookupByLibrary.simpleMessage("缓存"),
    "cacheCleared": MessageLookupByLibrary.simpleMessage("缓存已清除"),
    "cancel": MessageLookupByLibrary.simpleMessage("取消"),
    "cancelAllNotificationsFailed": m1,
    "cancelDownload": MessageLookupByLibrary.simpleMessage("取消下载"),
    "cancelDownloadNotificationFailed": m2,
    "canceled": MessageLookupByLibrary.simpleMessage("已取消"),
    "cancelled": MessageLookupByLibrary.simpleMessage("已取消"),
    "cancelling": MessageLookupByLibrary.simpleMessage("正在取消"),
    "cannotGetBaseDownloadDirectory": MessageLookupByLibrary.simpleMessage(
      "无法获取基础下载目录",
    ),
    "cannotGetDownloadDirectory": MessageLookupByLibrary.simpleMessage(
      "无法获取下载目录",
    ),
    "cannotGetDownloadDirectoryError": MessageLookupByLibrary.simpleMessage(
      "无法获取下载目录",
    ),
    "cannotInstallApkFile": MessageLookupByLibrary.simpleMessage(
      "无法安装 APK 文件，可能需要在设置中开启\"允许安装未知来源应用\"",
    ),
    "cannotInstallApkNeedPermission": MessageLookupByLibrary.simpleMessage(
      "无法安装 APK 文件，可能需要在设置中开启\"允许安装未知来源应用\"",
    ),
    "certFile": MessageLookupByLibrary.simpleMessage("证书（PEM）"),
    "changeAdminPassword": MessageLookupByLibrary.simpleMessage("更改管理员密码"),
    "changeAdminPasswordDesc": MessageLookupByLibrary.simpleMessage(
      "更新服务器管理员密码",
    ),
    "checkAdmin2fa": MessageLookupByLibrary.simpleMessage("管理员两步验证"),
    "checkDownloadManagerForFiles": MessageLookupByLibrary.simpleMessage(
      "请通过底部导航栏的\"下载管理\"查看下载文件",
    ),
    "checkForUpdates": MessageLookupByLibrary.simpleMessage("检查更新"),
    "checkForceHttps": MessageLookupByLibrary.simpleMessage(
      "禁用 HTTP 或强制跳转 HTTPS",
    ),
    "checkFtpPlaintext": MessageLookupByLibrary.simpleMessage("FTP 以明文传输凭据"),
    "checkGuestDisabled": MessageLookupByLibrary.simpleMessage("游客账户已禁用"),
    "checkImageInDownloadFolder": MessageLookupByLibrary.simpleMessage(
      "请在下载目录查看图片",
    ),
    "checkInstallPermissionFailed": m3,
    "checkNotInitialized": MessageLookupByLibrary.simpleMessage("服务器尚未初始化"),
    "checkS3Tls": MessageLookupByLibrary.simpleMessage("S3 服务使用 TLS"),
    "checkTls": MessageLookupByLibrary.simpleMessage("有效的 TLS 证书"),
    "chooseFile": MessageLookupByLibrary.simpleMessage("选择文件"),
    "clear": MessageLookupByLibrary.simpleMessage("清空"),
    "clearAll": MessageLookupByLibrary.simpleMessage("清空所有"),
    "clearCache": MessageLookupByLibrary.simpleMessage("清除缓存"),
    "clearCacheDesc": MessageLookupByLibrary.simpleMessage("释放存储空间"),
    "clearCompleted": MessageLookupByLibrary.simpleMessage("清除已完成"),
    "clearDownloadDirectoryFailed": m4,
    "clearFailed": MessageLookupByLibrary.simpleMessage("清空失败"),
    "clearFinished": MessageLookupByLibrary.simpleMessage("清除已结束"),
    "clearRecords": MessageLookupByLibrary.simpleMessage("清空记录"),
    "clearSucceeded": MessageLookupByLibrary.simpleMessage("清除已成功"),
    "cleared": MessageLookupByLibrary.simpleMessage("已清空下载目录"),
    "clickToJumpToDownloadManager": MessageLookupByLibrary.simpleMessage(
      "点击查看下载",
    ),
    "completed": MessageLookupByLibrary.simpleMessage("已完成"),
    "completedTime": MessageLookupByLibrary.simpleMessage("完成时间"),
    "configSavedRestartRequired": MessageLookupByLibrary.simpleMessage(
      "配置已保存,请重启OpenList服务以生效",
    ),
    "configuration": MessageLookupByLibrary.simpleMessage("配置"),
    "confirm": MessageLookupByLibrary.simpleMessage("确认"),
    "confirmCancelDownload": m5,
    "confirmClear": MessageLookupByLibrary.simpleMessage("确认清空"),
    "confirmClearAllFiles": MessageLookupByLibrary.simpleMessage(
      "确定要清空 OpenList 管理的所有文件吗？此操作不可撤销。",
    ),
    "confirmDelete": MessageLookupByLibrary.simpleMessage("确认删除"),
    "confirmDeleteFile": m6,
    "confirmDeleteItems": m7,
    "confirmDeleteRecord": m8,
    "confirmDeleteStorage": m9,
    "confirmDeleteUser": m10,
    "confirmDownload": MessageLookupByLibrary.simpleMessage("确认下载"),
    "confirmDownloadMessage": MessageLookupByLibrary.simpleMessage(
      "是否要下载这个文件？",
    ),
    "confirmSaveConfigMessage": MessageLookupByLibrary.simpleMessage(
      "修改配置可能导致服务不可用,确定保存吗?",
    ),
    "confirmSaveConfigTitle": MessageLookupByLibrary.simpleMessage("确认保存"),
    "connectFailed": MessageLookupByLibrary.simpleMessage("连接失败"),
    "connectToServer": MessageLookupByLibrary.simpleMessage("连接到服务器"),
    "connectedToServer": MessageLookupByLibrary.simpleMessage("已连接到服务器"),
    "connection": MessageLookupByLibrary.simpleMessage("连接"),
    "connectionUrls": MessageLookupByLibrary.simpleMessage("连接 URL"),
    "continueDownload": MessageLookupByLibrary.simpleMessage("继续下载"),
    "copiedToClipboard": MessageLookupByLibrary.simpleMessage("已复制到剪贴板"),
    "copy": MessageLookupByLibrary.simpleMessage("复制"),
    "copyFunctionalityComingSoon": MessageLookupByLibrary.simpleMessage(
      "复制功能即将推出",
    ),
    "copyLink": MessageLookupByLibrary.simpleMessage("复制链接"),
    "copyTo": MessageLookupByLibrary.simpleMessage("复制到"),
    "copying": MessageLookupByLibrary.simpleMessage("复制中..."),
    "coreSettings": MessageLookupByLibrary.simpleMessage("核心设置"),
    "coreSettingsDesc": MessageLookupByLibrary.simpleMessage(
      "无需网页界面即可配置 OpenList Core",
    ),
    "couldNotOpenUrl": MessageLookupByLibrary.simpleMessage("无法打开 URL"),
    "cpuTime": MessageLookupByLibrary.simpleMessage("CPU 时间"),
    "create": MessageLookupByLibrary.simpleMessage("创建"),
    "createOpenListDirectoryFailed": m11,
    "createOpenListDownloadDirectory": m12,
    "currentDownloadingFiles": m13,
    "currentIsLatestVersion": MessageLookupByLibrary.simpleMessage("已经是最新版本"),
    "currentlyDownloading": MessageLookupByLibrary.simpleMessage("正在下载"),
    "dataDirectory": MessageLookupByLibrary.simpleMessage("data 文件夹路径"),
    "dataDirectoryChangeWarning": MessageLookupByLibrary.simpleMessage(
      "服务将直接使用所选目录，不会迁移现有数据。请只选择应用可访问的本地目录。",
    ),
    "dataDirectoryRestartRequired": MessageLookupByLibrary.simpleMessage(
      "服务运行中时，必须重启才能使用新的数据目录。",
    ),
    "databaseNotSavedIssue": MessageLookupByLibrary.simpleMessage("数据库未保存问题"),
    "databaseNotSavedIssueDesc": MessageLookupByLibrary.simpleMessage(
      "如不手动关闭OpenList，则数据库可能不会被保存到对应的db文件中，如遇到此问题，请手动关闭以解决此问题。（开关位于主程序菜单OpenList界面，以及通知栏的通知上）",
    ),
    "defaultDirectory": MessageLookupByLibrary.simpleMessage("默认目录"),
    "delete": MessageLookupByLibrary.simpleMessage("删除"),
    "deleteFailed": MessageLookupByLibrary.simpleMessage("删除失败"),
    "deleteFile": MessageLookupByLibrary.simpleMessage("删除文件"),
    "deleteFileFailedLog": m14,
    "deleteFiles": MessageLookupByLibrary.simpleMessage("删除文件"),
    "deleteItemsConfirm": m15,
    "deletePolicy": MessageLookupByLibrary.simpleMessage("删除策略"),
    "deleteRecord": MessageLookupByLibrary.simpleMessage("删除记录"),
    "deleteStorage": MessageLookupByLibrary.simpleMessage("删除存储"),
    "deleteStorageMessage": m16,
    "deleteStorageTitle": MessageLookupByLibrary.simpleMessage("删除存储"),
    "description": MessageLookupByLibrary.simpleMessage("说明："),
    "desktopShortcut": MessageLookupByLibrary.simpleMessage("桌面快捷方式"),
    "directDownload": MessageLookupByLibrary.simpleMessage("直接下载"),
    "directDownloadApk": MessageLookupByLibrary.simpleMessage("直接下载APK"),
    "directDownloadMethod": MessageLookupByLibrary.simpleMessage("直接下载"),
    "directDownloadMethodDesc": MessageLookupByLibrary.simpleMessage(
      "使用应用内下载器",
    ),
    "disable": MessageLookupByLibrary.simpleMessage("禁用"),
    "disableStorage": MessageLookupByLibrary.simpleMessage("禁用存储"),
    "disabled": MessageLookupByLibrary.simpleMessage("禁用"),
    "download": MessageLookupByLibrary.simpleMessage("下载"),
    "downloadApk": MessageLookupByLibrary.simpleMessage("下载APK"),
    "downloadCancelled": m17,
    "downloadCancelledStatus": MessageLookupByLibrary.simpleMessage("下载已取消"),
    "downloadCancelledText": MessageLookupByLibrary.simpleMessage("下载已取消"),
    "downloadComplete": m18,
    "downloadCompleteChannel": MessageLookupByLibrary.simpleMessage("下载完成"),
    "downloadCompleteChannelDesc": MessageLookupByLibrary.simpleMessage(
      "文件下载完成通知",
    ),
    "downloadCompleteFile": m19,
    "downloadCompleteNotificationTitle": m20,
    "downloadCompleteTitle": MessageLookupByLibrary.simpleMessage("下载完成"),
    "downloadDirectory": MessageLookupByLibrary.simpleMessage("下载目录"),
    "downloadDirectoryCleared": MessageLookupByLibrary.simpleMessage("已清理下载目录"),
    "downloadDirectoryNotWritable": MessageLookupByLibrary.simpleMessage(
      "OpenList 无法写入所选目录",
    ),
    "downloadDirectoryOpened": MessageLookupByLibrary.simpleMessage("已打开下载目录"),
    "downloadDirectoryPathUnknown": MessageLookupByLibrary.simpleMessage(
      "下载目录路径未知",
    ),
    "downloadFailed": MessageLookupByLibrary.simpleMessage("下载失败"),
    "downloadFailedFile": m21,
    "downloadFailedWithError": m22,
    "downloadFunctionTest": MessageLookupByLibrary.simpleMessage("下载功能测试"),
    "downloadInstructions": MessageLookupByLibrary.simpleMessage(
      "• 文件将下载到系统下载目录\\n• 下载过程会显示进度通知\\n• 下载完成后可以选择打开文件\\n• 如果文件名重复会自动添加序号\\n• 请通过底部导航栏的\\\"下载管理\\\"查看下载文件",
    ),
    "downloadManager": MessageLookupByLibrary.simpleMessage("下载管理"),
    "downloadManagerWithCount": m23,
    "downloadProgress": m24,
    "downloadProgressChannel": MessageLookupByLibrary.simpleMessage("下载进度"),
    "downloadProgressDesc": MessageLookupByLibrary.simpleMessage("显示文件下载进度"),
    "downloadRecordsCleared": MessageLookupByLibrary.simpleMessage("已清空下载记录"),
    "downloadStarted": MessageLookupByLibrary.simpleMessage("下载已开始"),
    "downloadThisFile": MessageLookupByLibrary.simpleMessage("下载此文件吗？"),
    "downloadedFilesWillAppearHere": MessageLookupByLibrary.simpleMessage(
      "下载的文件将显示在这里",
    ),
    "downloading": MessageLookupByLibrary.simpleMessage("下载中"),
    "downloadingFileProgress": m25,
    "downloadingImage": MessageLookupByLibrary.simpleMessage("正在下载图片..."),
    "downloads": MessageLookupByLibrary.simpleMessage("下载"),
    "driver": MessageLookupByLibrary.simpleMessage("驱动"),
    "driverNoUpload": MessageLookupByLibrary.simpleMessage("该驱动不支持上传"),
    "edit": MessageLookupByLibrary.simpleMessage("编辑"),
    "editOpenListConfig": MessageLookupByLibrary.simpleMessage(
      "修改OpenList配置文件",
    ),
    "editStorage": MessageLookupByLibrary.simpleMessage("编辑存储"),
    "editUser": MessageLookupByLibrary.simpleMessage("编辑用户"),
    "emptyFolder": MessageLookupByLibrary.simpleMessage("文件夹为空"),
    "emptyInput": MessageLookupByLibrary.simpleMessage("输入不能为空"),
    "enable": MessageLookupByLibrary.simpleMessage("启用"),
    "enableStorage": MessageLookupByLibrary.simpleMessage("启用存储"),
    "enableWebBrowser": MessageLookupByLibrary.simpleMessage("启用内置网页浏览器"),
    "enableWebBrowserDesc": MessageLookupByLibrary.simpleMessage(
      "允许网页页面运行内置浏览器",
    ),
    "enabled": MessageLookupByLibrary.simpleMessage("启用"),
    "english": MessageLookupByLibrary.simpleMessage("English"),
    "enterFileName": MessageLookupByLibrary.simpleMessage("输入文件名称"),
    "enterFolderName": MessageLookupByLibrary.simpleMessage("输入文件夹名称"),
    "error": MessageLookupByLibrary.simpleMessage("错误"),
    "exposureMode": MessageLookupByLibrary.simpleMessage("访问模式"),
    "failed": MessageLookupByLibrary.simpleMessage("失败"),
    "failedToConnectToServer": MessageLookupByLibrary.simpleMessage("无法连接到服务器"),
    "failedToCopy": m26,
    "failedToCreateFolder": m27,
    "failedToDelete": m28,
    "failedToDeleteStorage": m29,
    "failedToLoadFiles": MessageLookupByLibrary.simpleMessage("无法加载文件"),
    "failedToMove": m30,
    "failedToToggleStorage": m31,
    "favorites": MessageLookupByLibrary.simpleMessage("收藏"),
    "fileDeleted": MessageLookupByLibrary.simpleMessage("文件已删除"),
    "fileDeletedLog": m32,
    "fileDownloadFailed": m33,
    "fileInfo": MessageLookupByLibrary.simpleMessage("文件信息"),
    "fileLocation": MessageLookupByLibrary.simpleMessage("文件位置"),
    "fileLocationTip": MessageLookupByLibrary.simpleMessage(
      "您可以使用文件管理器找到此文件，或者尝试安装相应的应用来打开它。",
    ),
    "fileManagerOpened": MessageLookupByLibrary.simpleMessage("已打开文件管理器"),
    "fileName": MessageLookupByLibrary.simpleMessage("文件名称"),
    "fileNotFound": MessageLookupByLibrary.simpleMessage("文件不存在或已被删除"),
    "fileNotFoundWillCreateOnSave": MessageLookupByLibrary.simpleMessage(
      "文件不存在,保存时将创建",
    ),
    "filePath": MessageLookupByLibrary.simpleMessage("路径"),
    "filePermissionDenied": MessageLookupByLibrary.simpleMessage(
      "文件权限被拒绝,请检查应用权限",
    ),
    "fileSavedTo": MessageLookupByLibrary.simpleMessage("文件已保存到:"),
    "fileSize": m34,
    "fileTime": m35,
    "files": MessageLookupByLibrary.simpleMessage("文件"),
    "findApkInDownloadFolder": MessageLookupByLibrary.simpleMessage(
      "请在下载目录找到APK文件进行安装",
    ),
    "findReplace": MessageLookupByLibrary.simpleMessage("查找替换"),
    "folderName": MessageLookupByLibrary.simpleMessage("文件夹名称"),
    "folderPassword": MessageLookupByLibrary.simpleMessage("文件夹密码"),
    "followSystem": MessageLookupByLibrary.simpleMessage("跟随系统"),
    "forceHttps": MessageLookupByLibrary.simpleMessage("强制 HTTPS"),
    "fullscreen": MessageLookupByLibrary.simpleMessage("全屏"),
    "general": MessageLookupByLibrary.simpleMessage("通用"),
    "getDownloadDirectoryFailed": m36,
    "getDownloadFileListFailed": m37,
    "getDownloadPathFailed": MessageLookupByLibrary.simpleMessage("获取失败"),
    "githubRepo": MessageLookupByLibrary.simpleMessage("GitHub 仓库"),
    "goTo": MessageLookupByLibrary.simpleMessage("前往"),
    "goToSettings": MessageLookupByLibrary.simpleMessage("去设置"),
    "goroutines": MessageLookupByLibrary.simpleMessage("协程数"),
    "grantManagerStoragePermission": MessageLookupByLibrary.simpleMessage(
      "申请【所有文件访问权限】",
    ),
    "grantNotificationPermission": MessageLookupByLibrary.simpleMessage(
      "申请【通知权限】",
    ),
    "grantNotificationPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "用于前台服务保活",
    ),
    "grantStoragePermission": MessageLookupByLibrary.simpleMessage(
      "申请【读写外置存储权限】",
    ),
    "grantStoragePermissionDesc": MessageLookupByLibrary.simpleMessage(
      "挂载本地存储时必须授予，否则无权限读写文件",
    ),
    "groupFtp": MessageLookupByLibrary.simpleMessage("FTP"),
    "groupGlobal": MessageLookupByLibrary.simpleMessage("全局"),
    "groupIndex": MessageLookupByLibrary.simpleMessage("索引"),
    "groupLdap": MessageLookupByLibrary.simpleMessage("LDAP"),
    "groupMedia": MessageLookupByLibrary.simpleMessage("媒体"),
    "groupOfflineDownload": MessageLookupByLibrary.simpleMessage("离线下载"),
    "groupPreview": MessageLookupByLibrary.simpleMessage("预览"),
    "groupS3": MessageLookupByLibrary.simpleMessage("S3"),
    "groupSite": MessageLookupByLibrary.simpleMessage("站点"),
    "groupSso": MessageLookupByLibrary.simpleMessage("单点登录"),
    "groupStyle": MessageLookupByLibrary.simpleMessage("样式"),
    "groupTraffic": MessageLookupByLibrary.simpleMessage("流量"),
    "groupTranscode": MessageLookupByLibrary.simpleMessage("转码"),
    "home": MessageLookupByLibrary.simpleMessage("主页"),
    "httpPort": MessageLookupByLibrary.simpleMessage("HTTP 端口"),
    "httpsPort": MessageLookupByLibrary.simpleMessage("HTTPS 端口"),
    "imageDownloadSuccess": MessageLookupByLibrary.simpleMessage("图片下载成功"),
    "importantSettings": MessageLookupByLibrary.simpleMessage("重要"),
    "inProgress": MessageLookupByLibrary.simpleMessage("进行中"),
    "info": MessageLookupByLibrary.simpleMessage("信息"),
    "initializingNotificationManager": MessageLookupByLibrary.simpleMessage(
      "初始化通知管理器",
    ),
    "installNow": MessageLookupByLibrary.simpleMessage("立即安装"),
    "invalidFilenameChars": MessageLookupByLibrary.simpleMessage("名称包含非法字符"),
    "invalidJsonFormat": m38,
    "invalidPem": MessageLookupByLibrary.simpleMessage("该文件不是 PEM 格式的证书或私钥"),
    "invalidPort": MessageLookupByLibrary.simpleMessage(
      "请输入 1 到 65535 的端口，或 -1 表示禁用",
    ),
    "invalidRegex": MessageLookupByLibrary.simpleMessage("不是有效的正则表达式"),
    "iosBackgroundNote": MessageLookupByLibrary.simpleMessage(
      "iOS 仅在应用处于前台或刚切到后台的短时间内保持服务器运行。",
    ),
    "jumpToOtherApp": MessageLookupByLibrary.simpleMessage("跳转到其他APP ？"),
    "keyFile": MessageLookupByLibrary.simpleMessage("私钥（PEM）"),
    "language": MessageLookupByLibrary.simpleMessage("语言"),
    "languageSettings": MessageLookupByLibrary.simpleMessage("语言设置"),
    "languageSettingsDesc": MessageLookupByLibrary.simpleMessage("选择应用显示语言"),
    "lastError": MessageLookupByLibrary.simpleMessage("最近错误"),
    "later": MessageLookupByLibrary.simpleMessage("稍后"),
    "laterInstall": MessageLookupByLibrary.simpleMessage("稍后安装"),
    "loadDownloadFilesFailed": MessageLookupByLibrary.simpleMessage("加载下载文件失败"),
    "loadFailed": m39,
    "loadStoragesFailed": MessageLookupByLibrary.simpleMessage("加载存储失败"),
    "loadingStorages": MessageLookupByLibrary.simpleMessage("加载中..."),
    "localServer": MessageLookupByLibrary.simpleMessage("本机服务器"),
    "login": MessageLookupByLibrary.simpleMessage("登录"),
    "logout": MessageLookupByLibrary.simpleMessage("退出登录"),
    "manageStorages": MessageLookupByLibrary.simpleMessage("管理存储"),
    "manageStoragesDesc": MessageLookupByLibrary.simpleMessage("添加、编辑或删除存储位置"),
    "mediaFavoriteAdded": MessageLookupByLibrary.simpleMessage("已添加到收藏"),
    "mediaLibraryUnavailable": MessageLookupByLibrary.simpleMessage("媒体库未启用"),
    "mediaPlaybackInterrupted": MessageLookupByLibrary.simpleMessage(
      "播放已中断，请检查文件格式或网络连接。",
    ),
    "mediaPlaybackUnavailable": MessageLookupByLibrary.simpleMessage(
      "该设备不支持播放此媒体",
    ),
    "memory": MessageLookupByLibrary.simpleMessage("内存"),
    "mode": MessageLookupByLibrary.simpleMessage("模式"),
    "modeChangeFailed": m40,
    "modeChangeRestart": MessageLookupByLibrary.simpleMessage("新模式在服务器重启后生效。"),
    "modeChangedRestart": MessageLookupByLibrary.simpleMessage(
      "模式已更改。重启服务器以应用。",
    ),
    "modeLan": MessageLookupByLibrary.simpleMessage("局域网"),
    "modeLanDesc": MessageLookupByLibrary.simpleMessage("监听所有网卡，同一网络中的设备可以访问。"),
    "modeLocal": MessageLookupByLibrary.simpleMessage("仅本机"),
    "modeLocalDesc": MessageLookupByLibrary.simpleMessage(
      "仅监听 127.0.0.1，其他设备无法访问。",
    ),
    "modePublic": MessageLookupByLibrary.simpleMessage("公网"),
    "modePublicDesc": MessageLookupByLibrary.simpleMessage(
      "可从互联网访问。需要 TLS、强制 HTTPS 并禁用游客账户。",
    ),
    "modifiedTime": MessageLookupByLibrary.simpleMessage("修改时间"),
    "modifyAdminPassword": MessageLookupByLibrary.simpleMessage("修改Admin密码"),
    "moreOptions": MessageLookupByLibrary.simpleMessage("更多选项"),
    "move": MessageLookupByLibrary.simpleMessage("移动"),
    "moveFunctionalityComingSoon": MessageLookupByLibrary.simpleMessage(
      "移动功能即将推出",
    ),
    "moveTo": MessageLookupByLibrary.simpleMessage("移动到"),
    "moving": MessageLookupByLibrary.simpleMessage("移动中..."),
    "multipleFilesCompleted": m41,
    "myStorages": MessageLookupByLibrary.simpleMessage("我的存储"),
    "nativeFiles": MessageLookupByLibrary.simpleMessage("文件"),
    "needInstallPermission": MessageLookupByLibrary.simpleMessage("需要安装权限"),
    "needInstallPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "为了安装 APK 文件，需要授予安装权限。请在设置中手动开启。",
    ),
    "needInstallPermissionToInstallApk": MessageLookupByLibrary.simpleMessage(
      "需要安装权限才能安装 APK 文件",
    ),
    "networkMode": MessageLookupByLibrary.simpleMessage("网络模式"),
    "newFile": MessageLookupByLibrary.simpleMessage("新建文件"),
    "newFolder": MessageLookupByLibrary.simpleMessage("新建文件夹"),
    "newName": MessageLookupByLibrary.simpleMessage("新名称"),
    "newVersionFound": MessageLookupByLibrary.simpleMessage("发现新版本"),
    "noActiveDownloads": MessageLookupByLibrary.simpleMessage("暂无进行中的下载"),
    "noAppToOpenFile": MessageLookupByLibrary.simpleMessage("没有找到可以打开此文件的应用"),
    "noBackupFound": MessageLookupByLibrary.simpleMessage("未找到备份文件"),
    "noChanges": MessageLookupByLibrary.simpleMessage("没有修改"),
    "noCompletedDownloads": MessageLookupByLibrary.simpleMessage("暂无已完成的下载"),
    "noDownloads": MessageLookupByLibrary.simpleMessage("没有下载"),
    "noFilesHere": MessageLookupByLibrary.simpleMessage("这里没有文件"),
    "noMediaItems": MessageLookupByLibrary.simpleMessage("暂无媒体内容"),
    "noOfflineTools": MessageLookupByLibrary.simpleMessage("服务器未配置离线下载工具"),
    "noPermissionToInstallApk": MessageLookupByLibrary.simpleMessage(
      "没有权限安装 APK 文件，请在设置中开启安装权限",
    ),
    "noPermissionToInstallApkFile": MessageLookupByLibrary.simpleMessage(
      "没有权限安装 APK 文件，请在设置中开启安装权限",
    ),
    "noPermissionToOpenFile": MessageLookupByLibrary.simpleMessage("没有权限打开此文件"),
    "noRecentFiles": MessageLookupByLibrary.simpleMessage("暂无最近文件"),
    "noSearchResults": MessageLookupByLibrary.simpleMessage("没有结果"),
    "noStorages": MessageLookupByLibrary.simpleMessage("没有存储"),
    "noStoragesConfigured": MessageLookupByLibrary.simpleMessage("未配置存储"),
    "noStoragesDesc": MessageLookupByLibrary.simpleMessage(
      "添加存储以开始使用 OpenList",
    ),
    "noTasks": MessageLookupByLibrary.simpleMessage("暂无任务"),
    "noUploads": MessageLookupByLibrary.simpleMessage("没有上传"),
    "notConfigured": MessageLookupByLibrary.simpleMessage("未配置"),
    "notConnected": MessageLookupByLibrary.simpleMessage("未连接"),
    "notificationClicked": m42,
    "notificationManagerInitFailed": m43,
    "notificationManagerInitialized": MessageLookupByLibrary.simpleMessage(
      "通知管理器初始化成功",
    ),
    "notificationsDisabled": MessageLookupByLibrary.simpleMessage(
      "通知已关闭，服务器状态通知不会显示",
    ),
    "offlineAdded": MessageLookupByLibrary.simpleMessage("已添加离线下载任务"),
    "offlineDownload": MessageLookupByLibrary.simpleMessage("离线下载"),
    "offlineTool": MessageLookupByLibrary.simpleMessage("工具"),
    "offlineUrls": MessageLookupByLibrary.simpleMessage("链接（每行一个）"),
    "ok": MessageLookupByLibrary.simpleMessage("确定"),
    "open": MessageLookupByLibrary.simpleMessage("打开"),
    "openDirectory": MessageLookupByLibrary.simpleMessage("打开目录"),
    "openDownloadDirectoryFailed": m44,
    "openDownloadManager": MessageLookupByLibrary.simpleMessage("打开下载"),
    "openDownloadTestPage": MessageLookupByLibrary.simpleMessage(
      "是否要打开下载测试页面？",
    ),
    "openFile": MessageLookupByLibrary.simpleMessage("打开文件"),
    "openFileException": m45,
    "openFileFailed": m46,
    "openFileManager": MessageLookupByLibrary.simpleMessage("打开文件管理器"),
    "openFileManagerFailed": m47,
    "openFileResult": m48,
    "openListDownloadDirectory": m49,
    "openSourceLicenses": MessageLookupByLibrary.simpleMessage("开源许可证"),
    "openWebInterface": MessageLookupByLibrary.simpleMessage("打开网页界面"),
    "openlist": MessageLookupByLibrary.simpleMessage("OpenList"),
    "openlistMobile": MessageLookupByLibrary.simpleMessage("OpenList Mobile"),
    "operationDone": MessageLookupByLibrary.simpleMessage("完成"),
    "operationFailed": MessageLookupByLibrary.simpleMessage("操作失败"),
    "otpCode": MessageLookupByLibrary.simpleMessage("两步验证码（可选）"),
    "parseFilenameFailed": m50,
    "password": MessageLookupByLibrary.simpleMessage("密码"),
    "passwordKeepHint": MessageLookupByLibrary.simpleMessage("留空则保持当前密码"),
    "pause": MessageLookupByLibrary.simpleMessage("暂停"),
    "pauseIndividualTransfers": MessageLookupByLibrary.simpleMessage("暂停单个传输"),
    "paused": MessageLookupByLibrary.simpleMessage("已暂停"),
    "pending": MessageLookupByLibrary.simpleMessage("等待中"),
    "permAccessWithoutPassword": MessageLookupByLibrary.simpleMessage("无需密码访问"),
    "permCopy": MessageLookupByLibrary.simpleMessage("复制"),
    "permCustomShareId": MessageLookupByLibrary.simpleMessage("自定义分享 ID"),
    "permDecompress": MessageLookupByLibrary.simpleMessage("解压压缩包"),
    "permFtpAccess": MessageLookupByLibrary.simpleMessage("FTP/SFTP 读取"),
    "permFtpManage": MessageLookupByLibrary.simpleMessage("FTP/SFTP 写入"),
    "permMove": MessageLookupByLibrary.simpleMessage("移动"),
    "permOfflineDownload": MessageLookupByLibrary.simpleMessage("添加离线下载"),
    "permReadArchives": MessageLookupByLibrary.simpleMessage("读取压缩包"),
    "permRemove": MessageLookupByLibrary.simpleMessage("删除"),
    "permRename": MessageLookupByLibrary.simpleMessage("重命名"),
    "permSeeHides": MessageLookupByLibrary.simpleMessage("查看隐藏文件"),
    "permShare": MessageLookupByLibrary.simpleMessage("创建分享"),
    "permWebdavManage": MessageLookupByLibrary.simpleMessage("WebDAV 写入"),
    "permWebdavRead": MessageLookupByLibrary.simpleMessage("WebDAV 读取"),
    "permWrite": MessageLookupByLibrary.simpleMessage("创建文件夹和上传"),
    "permissions": MessageLookupByLibrary.simpleMessage("权限"),
    "photos": MessageLookupByLibrary.simpleMessage("照片"),
    "play": MessageLookupByLibrary.simpleMessage("播放"),
    "policyDeleteAlways": MessageLookupByLibrary.simpleMessage("总是删除"),
    "policyDeleteNever": MessageLookupByLibrary.simpleMessage("从不删除"),
    "policyDeleteOnUploadFailed": MessageLookupByLibrary.simpleMessage(
      "上传失败后删除",
    ),
    "policyDeleteOnUploadSucceed": MessageLookupByLibrary.simpleMessage(
      "上传成功后删除",
    ),
    "policyUploadDownloadStream": MessageLookupByLibrary.simpleMessage(
      "边下载边上传",
    ),
    "preparingDownload": MessageLookupByLibrary.simpleMessage("准备下载..."),
    "preparingDownloadStatus": MessageLookupByLibrary.simpleMessage("准备下载..."),
    "preview": MessageLookupByLibrary.simpleMessage("预览"),
    "previewNotSupported": MessageLookupByLibrary.simpleMessage("不支持预览该类型文件"),
    "processMemory": MessageLookupByLibrary.simpleMessage("进程内存 (PSS)"),
    "publicBlocked": MessageLookupByLibrary.simpleMessage(
      "在所有必需检查通过之前无法启用公网模式。",
    ),
    "publicModeWarning": MessageLookupByLibrary.simpleMessage(
      "将服务器暴露到公网后任何人都可以访问。请确保管理员密码足够强并开启两步验证。",
    ),
    "quickAccess": MessageLookupByLibrary.simpleMessage("快速访问"),
    "recentFiles": MessageLookupByLibrary.simpleMessage("最近文件"),
    "refresh": MessageLookupByLibrary.simpleMessage("刷新"),
    "regexRename": MessageLookupByLibrary.simpleMessage("正则表达式"),
    "releasePage": MessageLookupByLibrary.simpleMessage("发布页面"),
    "reloadAll": MessageLookupByLibrary.simpleMessage("全部重新加载"),
    "remark": MessageLookupByLibrary.simpleMessage("备注"),
    "remoteServer": MessageLookupByLibrary.simpleMessage("远程服务器"),
    "remove": MessageLookupByLibrary.simpleMessage("移除"),
    "removeMediaFavorite": MessageLookupByLibrary.simpleMessage("取消收藏"),
    "rename": MessageLookupByLibrary.simpleMessage("重命名"),
    "renameNoMatch": MessageLookupByLibrary.simpleMessage("没有匹配的项目"),
    "renamePaddingZeros": MessageLookupByLibrary.simpleMessage("补零位数"),
    "renamePattern": MessageLookupByLibrary.simpleMessage("匹配规则（正则表达式）"),
    "renameReplacement": MessageLookupByLibrary.simpleMessage("替换为"),
    "renameSearchText": MessageLookupByLibrary.simpleMessage("查找文本"),
    "renameStartNumber": MessageLookupByLibrary.simpleMessage("起始编号"),
    "requestIgnoreBattery": MessageLookupByLibrary.simpleMessage("允许后台运行"),
    "requiredField": MessageLookupByLibrary.simpleMessage("必填"),
    "reset2fa": MessageLookupByLibrary.simpleMessage("重置两步验证"),
    "resetToken": MessageLookupByLibrary.simpleMessage("重置 API 令牌"),
    "resetTokenConfirm": MessageLookupByLibrary.simpleMessage(
      "重置 API 令牌会使使用当前令牌的客户端失效，是否继续？",
    ),
    "resetTokenSuccess": MessageLookupByLibrary.simpleMessage("API 令牌已重置"),
    "restartServer": MessageLookupByLibrary.simpleMessage("重启服务器"),
    "restartingService": MessageLookupByLibrary.simpleMessage(
      "正在重启OpenList服务...",
    ),
    "restoreBackup": MessageLookupByLibrary.simpleMessage("恢复备份"),
    "restoreBackupFailed": m51,
    "resume": MessageLookupByLibrary.simpleMessage("继续"),
    "retry": MessageLookupByLibrary.simpleMessage("重试"),
    "retryFailed": MessageLookupByLibrary.simpleMessage("重试失败"),
    "role": MessageLookupByLibrary.simpleMessage("角色"),
    "roleAdmin": MessageLookupByLibrary.simpleMessage("管理员"),
    "roleGeneral": MessageLookupByLibrary.simpleMessage("普通用户"),
    "roleGuest": MessageLookupByLibrary.simpleMessage("访客"),
    "running": MessageLookupByLibrary.simpleMessage("运行中"),
    "runtimeStatistics": MessageLookupByLibrary.simpleMessage("运行时统计"),
    "runtimeStatus": MessageLookupByLibrary.simpleMessage("运行状态"),
    "save": MessageLookupByLibrary.simpleMessage("保存"),
    "saveAndRestart": MessageLookupByLibrary.simpleMessage("保存并重启"),
    "saveFailed": m52,
    "saveOnly": MessageLookupByLibrary.simpleMessage("仅保存"),
    "saved": MessageLookupByLibrary.simpleMessage("已保存"),
    "search": MessageLookupByLibrary.simpleMessage("搜索"),
    "searchAll": MessageLookupByLibrary.simpleMessage("全部"),
    "searchFiles": MessageLookupByLibrary.simpleMessage("文件"),
    "searchFolders": MessageLookupByLibrary.simpleMessage("文件夹"),
    "searchHint": MessageLookupByLibrary.simpleMessage("关键词"),
    "securityChecks": MessageLookupByLibrary.simpleMessage("安全检查"),
    "seeAll": MessageLookupByLibrary.simpleMessage("查看全部"),
    "selectAppToOpen": MessageLookupByLibrary.simpleMessage("选择应用打开"),
    "selectDownloadMethod": MessageLookupByLibrary.simpleMessage("选择下载方式"),
    "selectNetworkMode": MessageLookupByLibrary.simpleMessage("选择网络模式"),
    "selectThisFolder": MessageLookupByLibrary.simpleMessage("选择此文件夹"),
    "selected": MessageLookupByLibrary.simpleMessage("已选择"),
    "selectedCount": m53,
    "sequentialRename": MessageLookupByLibrary.simpleMessage("顺序编号"),
    "server": MessageLookupByLibrary.simpleMessage("服务器"),
    "serverDetails": MessageLookupByLibrary.simpleMessage("服务器详情"),
    "serverDetailsDesc": MessageLookupByLibrary.simpleMessage("查看运行信息和连接详情"),
    "serverNotRunning": MessageLookupByLibrary.simpleMessage("本机服务器未运行"),
    "serverRunning": MessageLookupByLibrary.simpleMessage("服务器运行中"),
    "serverRuntime": MessageLookupByLibrary.simpleMessage("服务器"),
    "serverStopped": MessageLookupByLibrary.simpleMessage("服务器已停止"),
    "serverUrl": MessageLookupByLibrary.simpleMessage("服务器地址"),
    "serviceRestartFailed": MessageLookupByLibrary.simpleMessage(
      "服务重启失败,请手动重启",
    ),
    "serviceRestartOnlyAndroid": MessageLookupByLibrary.simpleMessage(
      "服务重启仅支持Android系统",
    ),
    "serviceRestartSuccess": MessageLookupByLibrary.simpleMessage("服务重启成功"),
    "setAdminPassword": MessageLookupByLibrary.simpleMessage("设置Admin密码"),
    "setDefaultDirectory": MessageLookupByLibrary.simpleMessage("是否设为初始目录？"),
    "settings": MessageLookupByLibrary.simpleMessage("设置"),
    "shareFeatureNotImplemented": MessageLookupByLibrary.simpleMessage(
      "分享功能待实现",
    ),
    "shareFile": MessageLookupByLibrary.simpleMessage("分享文件"),
    "shareLink": MessageLookupByLibrary.simpleMessage("分享链接"),
    "shareLinkDesc": MessageLookupByLibrary.simpleMessage("分享下载链接"),
    "showDownloadCompleteNotificationFailed": m54,
    "showDownloadProgressNotificationFailed": m55,
    "showInFileManager": MessageLookupByLibrary.simpleMessage("在文件管理器中显示"),
    "showSingleFileCompleteNotificationFailed": m56,
    "signOut": MessageLookupByLibrary.simpleMessage("退出登录"),
    "signOutConfirmMessage": MessageLookupByLibrary.simpleMessage("确定要退出登录吗？"),
    "signOutConfirmTitle": MessageLookupByLibrary.simpleMessage("退出登录"),
    "silentJumpApp": MessageLookupByLibrary.simpleMessage("静默跳转APP"),
    "silentJumpAppDesc": MessageLookupByLibrary.simpleMessage("跳转APP时，不弹出提示框"),
    "simplifiedChinese": MessageLookupByLibrary.simpleMessage("简体中文"),
    "siteSettings": MessageLookupByLibrary.simpleMessage("站点设置"),
    "size": MessageLookupByLibrary.simpleMessage("大小"),
    "sort": MessageLookupByLibrary.simpleMessage("排序"),
    "sortByDate": MessageLookupByLibrary.simpleMessage("修改日期"),
    "sortByName": MessageLookupByLibrary.simpleMessage("名称"),
    "sortBySize": MessageLookupByLibrary.simpleMessage("大小"),
    "sortByType": MessageLookupByLibrary.simpleMessage("类型"),
    "standbyBucket": MessageLookupByLibrary.simpleMessage("待机分组"),
    "startDownload": m57,
    "startDownloadFile": m58,
    "startServer": MessageLookupByLibrary.simpleMessage("启动服务器"),
    "startServerToAcceptConnections": MessageLookupByLibrary.simpleMessage(
      "启动服务器以接受连接",
    ),
    "startTime": MessageLookupByLibrary.simpleMessage("开始时间"),
    "startWebBrowser": MessageLookupByLibrary.simpleMessage("启动网页浏览器"),
    "status": MessageLookupByLibrary.simpleMessage("状态"),
    "stopServer": MessageLookupByLibrary.simpleMessage("停止服务器"),
    "stopServerMessage": MessageLookupByLibrary.simpleMessage("确定要停止服务器吗？"),
    "stopServerTitle": MessageLookupByLibrary.simpleMessage("停止服务器"),
    "stopWebBrowser": MessageLookupByLibrary.simpleMessage("停止"),
    "stopped": MessageLookupByLibrary.simpleMessage("已停止"),
    "storage": MessageLookupByLibrary.simpleMessage("存储"),
    "storageActions": MessageLookupByLibrary.simpleMessage("存储操作"),
    "storageDeleted": MessageLookupByLibrary.simpleMessage("存储已删除"),
    "storageDisabled": MessageLookupByLibrary.simpleMessage("已禁用"),
    "storageManagement": MessageLookupByLibrary.simpleMessage("存储管理"),
    "storageManagementDesc": MessageLookupByLibrary.simpleMessage("配置存储后端"),
    "storageToggled": m59,
    "storages": MessageLookupByLibrary.simpleMessage("存储"),
    "success": MessageLookupByLibrary.simpleMessage("成功"),
    "systemDefault": MessageLookupByLibrary.simpleMessage("系统默认"),
    "taskDone": MessageLookupByLibrary.simpleMessage("已结束"),
    "taskGroupCopy": MessageLookupByLibrary.simpleMessage("复制"),
    "taskGroupDecompress": MessageLookupByLibrary.simpleMessage("解压"),
    "taskGroupDecompressUpload": MessageLookupByLibrary.simpleMessage("解压上传"),
    "taskGroupMove": MessageLookupByLibrary.simpleMessage("移动"),
    "taskGroupOfflineDownload": MessageLookupByLibrary.simpleMessage("离线下载"),
    "taskGroupTransfer": MessageLookupByLibrary.simpleMessage("离线转存"),
    "taskGroupUpload": MessageLookupByLibrary.simpleMessage("上传"),
    "taskUndone": MessageLookupByLibrary.simpleMessage("进行中"),
    "tasks": MessageLookupByLibrary.simpleMessage("任务"),
    "testDirectDownloadFunction": MessageLookupByLibrary.simpleMessage(
      "测试直接下载功能",
    ),
    "testDownloadJsonFile": MessageLookupByLibrary.simpleMessage("测试下载JSON文件"),
    "testDownloadLargeFile": MessageLookupByLibrary.simpleMessage(
      "测试下载大文件(1MB)",
    ),
    "testDownloadPngImage": MessageLookupByLibrary.simpleMessage("测试下载PNG图片"),
    "theme": MessageLookupByLibrary.simpleMessage("主题"),
    "themeDark": MessageLookupByLibrary.simpleMessage("深色"),
    "themeLight": MessageLookupByLibrary.simpleMessage("浅色"),
    "themeSystem": MessageLookupByLibrary.simpleMessage("跟随系统"),
    "tlsCertificate": MessageLookupByLibrary.simpleMessage("HTTPS 证书"),
    "tlsCertificates": MessageLookupByLibrary.simpleMessage("TLS 证书"),
    "tlsCertificatesDesc": MessageLookupByLibrary.simpleMessage(
      "管理 SSL/TLS 证书",
    ),
    "tlsNeedsCert": MessageLookupByLibrary.simpleMessage(
      "启用 HTTPS 需要同时提供证书和私钥",
    ),
    "transfers": MessageLookupByLibrary.simpleMessage("传输"),
    "troubleshooting": MessageLookupByLibrary.simpleMessage("疑难解答"),
    "troubleshootingDesc": MessageLookupByLibrary.simpleMessage("常见问题与解决方案"),
    "tryToOpenFile": m60,
    "uiSettings": MessageLookupByLibrary.simpleMessage("界面"),
    "upload": MessageLookupByLibrary.simpleMessage("上传"),
    "uploadCanceled": MessageLookupByLibrary.simpleMessage("已取消"),
    "uploadDone": MessageLookupByLibrary.simpleMessage("上传完成"),
    "uploadFailed": MessageLookupByLibrary.simpleMessage("上传失败"),
    "uploadFailedState": MessageLookupByLibrary.simpleMessage("失败"),
    "uploadFiles": MessageLookupByLibrary.simpleMessage("上传文件"),
    "uploadFilesFromFilesScreen": MessageLookupByLibrary.simpleMessage(
      "从文件界面上传文件",
    ),
    "uploadFilesOrCreateFolder": MessageLookupByLibrary.simpleMessage(
      "上传文件或创建新文件夹",
    ),
    "uploadFunctionalityComingSoon": MessageLookupByLibrary.simpleMessage(
      "上传功能即将推出",
    ),
    "uploadPhotos": MessageLookupByLibrary.simpleMessage("上传图片"),
    "uploadQueued": MessageLookupByLibrary.simpleMessage("排队中"),
    "uploadRunning": MessageLookupByLibrary.simpleMessage("上传中"),
    "uploadSucceeded": MessageLookupByLibrary.simpleMessage("已完成"),
    "uploadVideos": MessageLookupByLibrary.simpleMessage("上传视频"),
    "uploading": MessageLookupByLibrary.simpleMessage("上传中"),
    "uploadingFile": m61,
    "uploads": MessageLookupByLibrary.simpleMessage("上传"),
    "uploadsActive": m62,
    "uploadsKeepAppAlive": MessageLookupByLibrary.simpleMessage(
      "上传会在应用进程存活期间继续；从最近任务中划掉应用会中止上传。",
    ),
    "uptime": MessageLookupByLibrary.simpleMessage("运行时间"),
    "user": MessageLookupByLibrary.simpleMessage("用户"),
    "userCancelledDownload": MessageLookupByLibrary.simpleMessage("用户取消下载"),
    "userCancelledDownloadError": MessageLookupByLibrary.simpleMessage(
      "用户取消下载",
    ),
    "userDisabled": MessageLookupByLibrary.simpleMessage("已禁用"),
    "userManagement": MessageLookupByLibrary.simpleMessage("用户管理"),
    "userManagementDesc": MessageLookupByLibrary.simpleMessage("管理用户和权限"),
    "username": MessageLookupByLibrary.simpleMessage("用户名"),
    "users": MessageLookupByLibrary.simpleMessage("用户"),
    "version": MessageLookupByLibrary.simpleMessage("版本"),
    "videos": MessageLookupByLibrary.simpleMessage("视频"),
    "view": MessageLookupByLibrary.simpleMessage("查看"),
    "viewDownloadDirectory": MessageLookupByLibrary.simpleMessage("查看下载目录"),
    "viewDownloadFiles": MessageLookupByLibrary.simpleMessage("查看下载文件"),
    "viewDownloads": MessageLookupByLibrary.simpleMessage("查看下载"),
    "viewLocation": MessageLookupByLibrary.simpleMessage("查看位置"),
    "viewThirdPartyLicenses": MessageLookupByLibrary.simpleMessage("查看第三方许可证"),
    "waiting": MessageLookupByLibrary.simpleMessage("等待中"),
    "wakeLock": MessageLookupByLibrary.simpleMessage("唤醒锁"),
    "wakeLockDesc": MessageLookupByLibrary.simpleMessage(
      "开启防止锁屏后CPU休眠，保持进程在后台运行。（部分系统可能导致杀后台）",
    ),
    "webBrowserDownloadInProgress": MessageLookupByLibrary.simpleMessage(
      "下载进行中，无法停止浏览器",
    ),
    "webBrowserStatus": MessageLookupByLibrary.simpleMessage("内置网页浏览器"),
    "webBrowserStopped": MessageLookupByLibrary.simpleMessage("内置网页浏览器已停止"),
    "webPage": MessageLookupByLibrary.simpleMessage("网页"),
  };
}
