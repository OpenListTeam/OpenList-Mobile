// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `OpenList`
  String get appName {
    return Intl.message('OpenList', name: 'appName', desc: '', args: []);
  }

  /// `桌面快捷方式`
  String get desktopShortcut {
    return Intl.message('桌面快捷方式', name: 'desktopShortcut', desc: '', args: []);
  }

  /// `设置admin密码`
  String get setAdminPassword {
    return Intl.message(
      '设置admin密码',
      name: 'setAdminPassword',
      desc: '',
      args: [],
    );
  }

  /// `更多选项`
  String get moreOptions {
    return Intl.message('更多选项', name: 'moreOptions', desc: '', args: []);
  }

  /// `检查更新`
  String get checkForUpdates {
    return Intl.message('检查更新', name: 'checkForUpdates', desc: '', args: []);
  }

  /// `已经是最新版本`
  String get currentIsLatestVersion {
    return Intl.message(
      '已经是最新版本',
      name: 'currentIsLatestVersion',
      desc: '',
      args: [],
    );
  }

  /// `确认`
  String get confirm {
    return Intl.message('确认', name: 'confirm', desc: '', args: []);
  }

  /// `取消`
  String get cancel {
    return Intl.message('取消', name: 'cancel', desc: '', args: []);
  }

  /// `发布页面`
  String get releasePage {
    return Intl.message('发布页面', name: 'releasePage', desc: '', args: []);
  }

  /// `下载APK`
  String get downloadApk {
    return Intl.message('下载APK', name: 'downloadApk', desc: '', args: []);
  }

  /// `关于`
  String get about {
    return Intl.message('关于', name: 'about', desc: '', args: []);
  }

  /// `通用`
  String get general {
    return Intl.message('通用', name: 'general', desc: '', args: []);
  }

  /// `自动检查更新`
  String get autoCheckForUpdates {
    return Intl.message(
      '自动检查更新',
      name: 'autoCheckForUpdates',
      desc: '',
      args: [],
    );
  }

  /// `启动时自动检查更新`
  String get autoCheckForUpdatesDesc {
    return Intl.message(
      '启动时自动检查更新',
      name: 'autoCheckForUpdatesDesc',
      desc: '',
      args: [],
    );
  }

  /// `唤醒锁`
  String get wakeLock {
    return Intl.message('唤醒锁', name: 'wakeLock', desc: '', args: []);
  }

  /// `开启防止锁屏后CPU休眠，保持进程在后台运行。（部分系统可能导致杀后台）`
  String get wakeLockDesc {
    return Intl.message(
      '开启防止锁屏后CPU休眠，保持进程在后台运行。（部分系统可能导致杀后台）',
      name: 'wakeLockDesc',
      desc: '',
      args: [],
    );
  }

  /// `开机自启动服务`
  String get bootAutoStartService {
    return Intl.message(
      '开机自启动服务',
      name: 'bootAutoStartService',
      desc: '',
      args: [],
    );
  }

  /// `在开机后自动启动OpenList服务。（请确保授予自启动权限）`
  String get bootAutoStartServiceDesc {
    return Intl.message(
      '在开机后自动启动OpenList服务。（请确保授予自启动权限）',
      name: 'bootAutoStartServiceDesc',
      desc: '',
      args: [],
    );
  }

  /// `网页`
  String get webPage {
    return Intl.message('网页', name: 'webPage', desc: '', args: []);
  }

  /// `设置`
  String get settings {
    return Intl.message('设置', name: 'settings', desc: '', args: []);
  }

  /// `选择应用打开`
  String get selectAppToOpen {
    return Intl.message('选择应用打开', name: 'selectAppToOpen', desc: '', args: []);
  }

  /// `前往`
  String get goTo {
    return Intl.message('前往', name: 'goTo', desc: '', args: []);
  }

  /// `下载此文件吗？`
  String get downloadThisFile {
    return Intl.message(
      '下载此文件吗？',
      name: 'downloadThisFile',
      desc: '',
      args: [],
    );
  }

  /// `下载`
  String get download {
    return Intl.message('下载', name: 'download', desc: '', args: []);
  }

  /// `已复制到剪贴板`
  String get copiedToClipboard {
    return Intl.message(
      '已复制到剪贴板',
      name: 'copiedToClipboard',
      desc: '',
      args: [],
    );
  }

  /// `重要`
  String get importantSettings {
    return Intl.message('重要', name: 'importantSettings', desc: '', args: []);
  }

  /// `界面`
  String get uiSettings {
    return Intl.message('界面', name: 'uiSettings', desc: '', args: []);
  }

  /// `申请【所有文件访问权限】`
  String get grantManagerStoragePermission {
    return Intl.message(
      '申请【所有文件访问权限】',
      name: 'grantManagerStoragePermission',
      desc: '',
      args: [],
    );
  }

  /// `挂载本地存储时必须授予，否则无权限读写文件`
  String get grantStoragePermissionDesc {
    return Intl.message(
      '挂载本地存储时必须授予，否则无权限读写文件',
      name: 'grantStoragePermissionDesc',
      desc: '',
      args: [],
    );
  }

  /// `申请【读写外置存储权限】`
  String get grantStoragePermission {
    return Intl.message(
      '申请【读写外置存储权限】',
      name: 'grantStoragePermission',
      desc: '',
      args: [],
    );
  }

  /// `申请【通知权限】`
  String get grantNotificationPermission {
    return Intl.message(
      '申请【通知权限】',
      name: 'grantNotificationPermission',
      desc: '',
      args: [],
    );
  }

  /// `用于前台服务保活`
  String get grantNotificationPermissionDesc {
    return Intl.message(
      '用于前台服务保活',
      name: 'grantNotificationPermissionDesc',
      desc: '',
      args: [],
    );
  }

  /// `将网页设置为打开首页`
  String get autoStartWebPage {
    return Intl.message(
      '将网页设置为打开首页',
      name: 'autoStartWebPage',
      desc: '',
      args: [],
    );
  }

  /// `跳转到其他APP ？`
  String get jumpToOtherApp {
    return Intl.message(
      '跳转到其他APP ？',
      name: 'jumpToOtherApp',
      desc: '',
      args: [],
    );
  }

  /// `打开主界面时的首页`
  String get autoStartWebPageDesc {
    return Intl.message(
      '打开主界面时的首页',
      name: 'autoStartWebPageDesc',
      desc: '',
      args: [],
    );
  }

  /// `data 文件夹路径`
  String get dataDirectory {
    return Intl.message(
      'data 文件夹路径',
      name: 'dataDirectory',
      desc: '',
      args: [],
    );
  }

  /// `是否设为初始目录？`
  String get setDefaultDirectory {
    return Intl.message(
      '是否设为初始目录？',
      name: 'setDefaultDirectory',
      desc: '',
      args: [],
    );
  }

  /// `静默跳转APP`
  String get silentJumpApp {
    return Intl.message('静默跳转APP', name: 'silentJumpApp', desc: '', args: []);
  }

  /// `跳转APP时，不弹出提示框`
  String get silentJumpAppDesc {
    return Intl.message(
      '跳转APP时，不弹出提示框',
      name: 'silentJumpAppDesc',
      desc: '',
      args: [],
    );
  }

  /// `发现新版本`
  String get newVersionFound {
    return Intl.message('发现新版本', name: 'newVersionFound', desc: '', args: []);
  }

  /// `直接下载APK`
  String get directDownloadApk {
    return Intl.message(
      '直接下载APK',
      name: 'directDownloadApk',
      desc: '',
      args: [],
    );
  }

  /// `初始化通知管理器`
  String get initializingNotificationManager {
    return Intl.message(
      '初始化通知管理器',
      name: 'initializingNotificationManager',
      desc: '',
      args: [],
    );
  }

  /// `下载管理`
  String get downloadManager {
    return Intl.message('下载管理', name: 'downloadManager', desc: '', args: []);
  }

  /// `下载管理({count})`
  String downloadManagerWithCount(int count) {
    return Intl.message(
      '下载管理($count)',
      name: 'downloadManagerWithCount',
      desc: '',
      args: [count],
    );
  }

  /// `修改admin密码`
  String get modifyAdminPassword {
    return Intl.message(
      '修改admin密码',
      name: 'modifyAdminPassword',
      desc: '',
      args: [],
    );
  }

  /// `直接下载`
  String get directDownload {
    return Intl.message('直接下载', name: 'directDownload', desc: '', args: []);
  }

  /// `浏览器下载`
  String get browserDownload {
    return Intl.message('浏览器下载', name: 'browserDownload', desc: '', args: []);
  }

  /// `加载下载文件失败`
  String get loadDownloadFilesFailed {
    return Intl.message(
      '加载下载文件失败',
      name: 'loadDownloadFilesFailed',
      desc: '',
      args: [],
    );
  }

  /// `暂无进行中的下载`
  String get noActiveDownloads {
    return Intl.message(
      '暂无进行中的下载',
      name: 'noActiveDownloads',
      desc: '',
      args: [],
    );
  }

  /// `下载失败`
  String get downloadFailed {
    return Intl.message('下载失败', name: 'downloadFailed', desc: '', args: []);
  }

  /// `开始时间`
  String get startTime {
    return Intl.message('开始时间', name: 'startTime', desc: '', args: []);
  }

  /// `暂无已完成的下载`
  String get noCompletedDownloads {
    return Intl.message(
      '暂无已完成的下载',
      name: 'noCompletedDownloads',
      desc: '',
      args: [],
    );
  }

  /// `完成时间`
  String get completedTime {
    return Intl.message('完成时间', name: 'completedTime', desc: '', args: []);
  }

  /// `大小`
  String get size {
    return Intl.message('大小', name: 'size', desc: '', args: []);
  }

  /// `打开文件`
  String get openFile {
    return Intl.message('打开文件', name: 'openFile', desc: '', args: []);
  }

  /// `删除记录`
  String get deleteRecord {
    return Intl.message('删除记录', name: 'deleteRecord', desc: '', args: []);
  }

  /// `删除文件`
  String get deleteFile {
    return Intl.message('删除文件', name: 'deleteFile', desc: '', args: []);
  }

  /// `确认清空`
  String get confirmClear {
    return Intl.message('确认清空', name: 'confirmClear', desc: '', args: []);
  }

  /// `确定要清空所有下载文件吗？此操作不可撤销。`
  String get confirmClearAllFiles {
    return Intl.message(
      '确定要清空所有下载文件吗？此操作不可撤销。',
      name: 'confirmClearAllFiles',
      desc: '',
      args: [],
    );
  }

  /// `已清空下载目录`
  String get cleared {
    return Intl.message('已清空下载目录', name: 'cleared', desc: '', args: []);
  }

  /// `清空失败`
  String get clearFailed {
    return Intl.message('清空失败', name: 'clearFailed', desc: '', args: []);
  }

  /// `取消下载`
  String get cancelDownload {
    return Intl.message('取消下载', name: 'cancelDownload', desc: '', args: []);
  }

  /// `确定要取消下载 "{filename}" 吗？`
  String confirmCancelDownload(String filename) {
    return Intl.message(
      '确定要取消下载 "$filename" 吗？',
      name: 'confirmCancelDownload',
      desc: '',
      args: [filename],
    );
  }

  /// `继续下载`
  String get continueDownload {
    return Intl.message('继续下载', name: 'continueDownload', desc: '', args: []);
  }

  /// `确定要删除 "{filename}" 的下载记录吗？`
  String confirmDeleteRecord(String filename) {
    return Intl.message(
      '确定要删除 "$filename" 的下载记录吗？',
      name: 'confirmDeleteRecord',
      desc: '',
      args: [filename],
    );
  }

  /// `删除`
  String get delete {
    return Intl.message('删除', name: 'delete', desc: '', args: []);
  }

  /// `分享文件`
  String get shareFile {
    return Intl.message('分享文件', name: 'shareFile', desc: '', args: []);
  }

  /// `分享功能待实现`
  String get shareFeatureNotImplemented {
    return Intl.message(
      '分享功能待实现',
      name: 'shareFeatureNotImplemented',
      desc: '',
      args: [],
    );
  }

  /// `文件信息`
  String get fileInfo {
    return Intl.message('文件信息', name: 'fileInfo', desc: '', args: []);
  }

  /// `文件名`
  String get fileName {
    return Intl.message('文件名', name: 'fileName', desc: '', args: []);
  }

  /// `修改时间`
  String get modifiedTime {
    return Intl.message('修改时间', name: 'modifiedTime', desc: '', args: []);
  }

  /// `路径`
  String get filePath {
    return Intl.message('路径', name: 'filePath', desc: '', args: []);
  }

  /// `确认删除`
  String get confirmDelete {
    return Intl.message('确认删除', name: 'confirmDelete', desc: '', args: []);
  }

  /// `确定要删除文件 "{filename}" 吗？此操作不可撤销。`
  String confirmDeleteFile(String filename) {
    return Intl.message(
      '确定要删除文件 "$filename" 吗？此操作不可撤销。',
      name: 'confirmDeleteFile',
      desc: '',
      args: [filename],
    );
  }

  /// `文件已删除`
  String get fileDeleted {
    return Intl.message('文件已删除', name: 'fileDeleted', desc: '', args: []);
  }

  /// `删除失败`
  String get deleteFailed {
    return Intl.message('删除失败', name: 'deleteFailed', desc: '', args: []);
  }

  /// `清空`
  String get clear {
    return Intl.message('清空', name: 'clear', desc: '', args: []);
  }

  /// `没有找到可以打开此文件的应用`
  String get noAppToOpenFile {
    return Intl.message(
      '没有找到可以打开此文件的应用',
      name: 'noAppToOpenFile',
      desc: '',
      args: [],
    );
  }

  /// `查看位置`
  String get viewLocation {
    return Intl.message('查看位置', name: 'viewLocation', desc: '', args: []);
  }

  /// `文件不存在或已被删除`
  String get fileNotFound {
    return Intl.message('文件不存在或已被删除', name: 'fileNotFound', desc: '', args: []);
  }

  /// `没有权限打开此文件`
  String get noPermissionToOpenFile {
    return Intl.message(
      '没有权限打开此文件',
      name: 'noPermissionToOpenFile',
      desc: '',
      args: [],
    );
  }

  /// `打开文件失败: {error}`
  String openFileFailed(String error) {
    return Intl.message(
      '打开文件失败: $error',
      name: 'openFileFailed',
      desc: '',
      args: [error],
    );
  }

  /// `文件位置`
  String get fileLocation {
    return Intl.message('文件位置', name: 'fileLocation', desc: '', args: []);
  }

  /// `文件已保存到:`
  String get fileSavedTo {
    return Intl.message('文件已保存到:', name: 'fileSavedTo', desc: '', args: []);
  }

  /// `您可以使用文件管理器找到此文件，或者尝试安装相应的应用来打开它。`
  String get fileLocationTip {
    return Intl.message(
      '您可以使用文件管理器找到此文件，或者尝试安装相应的应用来打开它。',
      name: 'fileLocationTip',
      desc: '',
      args: [],
    );
  }

  /// `下载目录`
  String get downloadDirectory {
    return Intl.message('下载目录', name: 'downloadDirectory', desc: '', args: []);
  }

  /// `打开目录`
  String get openDirectory {
    return Intl.message('打开目录', name: 'openDirectory', desc: '', args: []);
  }

  /// `清空记录`
  String get clearRecords {
    return Intl.message('清空记录', name: 'clearRecords', desc: '', args: []);
  }

  /// `清空所有`
  String get clearAll {
    return Intl.message('清空所有', name: 'clearAll', desc: '', args: []);
  }

  /// `已清空下载记录`
  String get downloadRecordsCleared {
    return Intl.message(
      '已清空下载记录',
      name: 'downloadRecordsCleared',
      desc: '',
      args: [],
    );
  }

  /// `进行中`
  String get inProgress {
    return Intl.message('进行中', name: 'inProgress', desc: '', args: []);
  }

  /// `已完成`
  String get completed {
    return Intl.message('已完成', name: 'completed', desc: '', args: []);
  }

  /// `刷新`
  String get refresh {
    return Intl.message('刷新', name: 'refresh', desc: '', args: []);
  }

  /// `等待中`
  String get pending {
    return Intl.message('等待中', name: 'pending', desc: '', args: []);
  }

  /// `下载中`
  String get downloading {
    return Intl.message('下载中', name: 'downloading', desc: '', args: []);
  }

  /// `失败`
  String get failed {
    return Intl.message('失败', name: 'failed', desc: '', args: []);
  }

  /// `已取消`
  String get cancelled {
    return Intl.message('已取消', name: 'cancelled', desc: '', args: []);
  }

  /// `无法获取下载目录`
  String get cannotGetDownloadDirectory {
    return Intl.message(
      '无法获取下载目录',
      name: 'cannotGetDownloadDirectory',
      desc: '',
      args: [],
    );
  }

  /// `开始下载: {filename}`
  String startDownload(String filename) {
    return Intl.message(
      '开始下载: $filename',
      name: 'startDownload',
      desc: '',
      args: [filename],
    );
  }

  /// `下载进度: {progress}%`
  String downloadProgress(String progress) {
    return Intl.message(
      '下载进度: $progress%',
      name: 'downloadProgress',
      desc: '',
      args: [progress],
    );
  }

  /// `下载完成: {filename}`
  String downloadComplete(String filename) {
    return Intl.message(
      '下载完成: $filename',
      name: 'downloadComplete',
      desc: '',
      args: [filename],
    );
  }

  /// `打开`
  String get open {
    return Intl.message('打开', name: 'open', desc: '', args: []);
  }

  /// `下载已取消: {url}`
  String downloadCancelled(String url) {
    return Intl.message(
      '下载已取消: $url',
      name: 'downloadCancelled',
      desc: '',
      args: [url],
    );
  }

  /// `下载失败: {filename}`
  String downloadFailedWithError(String filename) {
    return Intl.message(
      '下载失败: $filename',
      name: 'downloadFailedWithError',
      desc: '',
      args: [filename],
    );
  }

  /// `用户取消下载`
  String get userCancelledDownload {
    return Intl.message(
      '用户取消下载',
      name: 'userCancelledDownload',
      desc: '',
      args: [],
    );
  }

  /// `无法获取基础下载目录`
  String get cannotGetBaseDownloadDirectory {
    return Intl.message(
      '无法获取基础下载目录',
      name: 'cannotGetBaseDownloadDirectory',
      desc: '',
      args: [],
    );
  }

  /// `创建OpenList下载目录: {path}`
  String createOpenListDownloadDirectory(String path) {
    return Intl.message(
      '创建OpenList下载目录: $path',
      name: 'createOpenListDownloadDirectory',
      desc: '',
      args: [path],
    );
  }

  /// `创建OpenList目录失败: {error}`
  String createOpenListDirectoryFailed(String error) {
    return Intl.message(
      '创建OpenList目录失败: $error',
      name: 'createOpenListDirectoryFailed',
      desc: '',
      args: [error],
    );
  }

  /// `OpenList下载目录: {path}`
  String openListDownloadDirectory(String path) {
    return Intl.message(
      'OpenList下载目录: $path',
      name: 'openListDownloadDirectory',
      desc: '',
      args: [path],
    );
  }

  /// `获取下载目录失败: {error}`
  String getDownloadDirectoryFailed(String error) {
    return Intl.message(
      '获取下载目录失败: $error',
      name: 'getDownloadDirectoryFailed',
      desc: '',
      args: [error],
    );
  }

  /// `解析文件名失败: {error}`
  String parseFilenameFailed(String error) {
    return Intl.message(
      '解析文件名失败: $error',
      name: 'parseFilenameFailed',
      desc: '',
      args: [error],
    );
  }

  /// `需要安装权限`
  String get needInstallPermission {
    return Intl.message(
      '需要安装权限',
      name: 'needInstallPermission',
      desc: '',
      args: [],
    );
  }

  /// `为了安装 APK 文件，需要授予安装权限。请在设置中手动开启。`
  String get needInstallPermissionDesc {
    return Intl.message(
      '为了安装 APK 文件，需要授予安装权限。请在设置中手动开启。',
      name: 'needInstallPermissionDesc',
      desc: '',
      args: [],
    );
  }

  /// `去设置`
  String get goToSettings {
    return Intl.message('去设置', name: 'goToSettings', desc: '', args: []);
  }

  /// `需要安装权限才能安装 APK 文件`
  String get needInstallPermissionToInstallApk {
    return Intl.message(
      '需要安装权限才能安装 APK 文件',
      name: 'needInstallPermissionToInstallApk',
      desc: '',
      args: [],
    );
  }

  /// `检查安装权限失败: {error}`
  String checkInstallPermissionFailed(String error) {
    return Intl.message(
      '检查安装权限失败: $error',
      name: 'checkInstallPermissionFailed',
      desc: '',
      args: [error],
    );
  }

  /// `尝试打开文件: {path}`
  String tryToOpenFile(String path) {
    return Intl.message(
      '尝试打开文件: $path',
      name: 'tryToOpenFile',
      desc: '',
      args: [path],
    );
  }

  /// `打开文件结果: {type} - {message}`
  String openFileResult(String type, String message) {
    return Intl.message(
      '打开文件结果: $type - $message',
      name: 'openFileResult',
      desc: '',
      args: [type, message],
    );
  }

  /// `无法安装 APK 文件，可能需要在设置中开启"允许安装未知来源应用"`
  String get cannotInstallApkFile {
    return Intl.message(
      '无法安装 APK 文件，可能需要在设置中开启"允许安装未知来源应用"',
      name: 'cannotInstallApkFile',
      desc: '',
      args: [],
    );
  }

  /// `没有权限安装 APK 文件，请在设置中开启安装权限`
  String get noPermissionToInstallApk {
    return Intl.message(
      '没有权限安装 APK 文件，请在设置中开启安装权限',
      name: 'noPermissionToInstallApk',
      desc: '',
      args: [],
    );
  }

  /// `打开文件异常: {error}`
  String openFileException(String error) {
    return Intl.message(
      '打开文件异常: $error',
      name: 'openFileException',
      desc: '',
      args: [error],
    );
  }

  /// `获取下载文件列表失败: {error}`
  String getDownloadFileListFailed(String error) {
    return Intl.message(
      '获取下载文件列表失败: $error',
      name: 'getDownloadFileListFailed',
      desc: '',
      args: [error],
    );
  }

  /// `已清理下载目录`
  String get downloadDirectoryCleared {
    return Intl.message(
      '已清理下载目录',
      name: 'downloadDirectoryCleared',
      desc: '',
      args: [],
    );
  }

  /// `清理下载目录失败: {error}`
  String clearDownloadDirectoryFailed(String error) {
    return Intl.message(
      '清理下载目录失败: $error',
      name: 'clearDownloadDirectoryFailed',
      desc: '',
      args: [error],
    );
  }

  /// `已删除文件: {filename}`
  String fileDeletedLog(String filename) {
    return Intl.message(
      '已删除文件: $filename',
      name: 'fileDeletedLog',
      desc: '',
      args: [filename],
    );
  }

  /// `删除文件失败: {error}`
  String deleteFileFailedLog(String error) {
    return Intl.message(
      '删除文件失败: $error',
      name: 'deleteFileFailedLog',
      desc: '',
      args: [error],
    );
  }

  /// `准备下载...`
  String get preparingDownload {
    return Intl.message(
      '准备下载...',
      name: 'preparingDownload',
      desc: '',
      args: [],
    );
  }

  /// `下载已取消`
  String get downloadCancelledStatus {
    return Intl.message(
      '下载已取消',
      name: 'downloadCancelledStatus',
      desc: '',
      args: [],
    );
  }

  /// `通知管理器初始化成功`
  String get notificationManagerInitialized {
    return Intl.message(
      '通知管理器初始化成功',
      name: 'notificationManagerInitialized',
      desc: '',
      args: [],
    );
  }

  /// `通知管理器初始化失败: {error}`
  String notificationManagerInitFailed(String error) {
    return Intl.message(
      '通知管理器初始化失败: $error',
      name: 'notificationManagerInitFailed',
      desc: '',
      args: [error],
    );
  }

  /// `通知被点击: {payload}`
  String notificationClicked(String payload) {
    return Intl.message(
      '通知被点击: $payload',
      name: 'notificationClicked',
      desc: '',
      args: [payload],
    );
  }

  /// `当前有 {count} 个文件在下载`
  String currentDownloadingFiles(int count) {
    return Intl.message(
      '当前有 $count 个文件在下载',
      name: 'currentDownloadingFiles',
      desc: '',
      args: [count],
    );
  }

  /// `显示文件下载进度`
  String get downloadProgressDesc {
    return Intl.message(
      '显示文件下载进度',
      name: 'downloadProgressDesc',
      desc: '',
      args: [],
    );
  }

  /// `查看下载`
  String get viewDownloads {
    return Intl.message('查看下载', name: 'viewDownloads', desc: '', args: []);
  }

  /// `显示下载进度通知失败: {error}`
  String showDownloadProgressNotificationFailed(String error) {
    return Intl.message(
      '显示下载进度通知失败: $error',
      name: 'showDownloadProgressNotificationFailed',
      desc: '',
      args: [error],
    );
  }

  /// `{filename} 下载完毕`
  String downloadCompleteNotificationTitle(String filename) {
    return Intl.message(
      '$filename 下载完毕',
      name: 'downloadCompleteNotificationTitle',
      desc: '',
      args: [filename],
    );
  }

  /// `点击跳转到下载管理`
  String get clickToJumpToDownloadManager {
    return Intl.message(
      '点击跳转到下载管理',
      name: 'clickToJumpToDownloadManager',
      desc: '',
      args: [],
    );
  }

  /// `下载完成`
  String get downloadCompleteTitle {
    return Intl.message(
      '下载完成',
      name: 'downloadCompleteTitle',
      desc: '',
      args: [],
    );
  }

  /// `{count} 个文件已完成，点击跳转到下载管理`
  String multipleFilesCompleted(int count) {
    return Intl.message(
      '$count 个文件已完成，点击跳转到下载管理',
      name: 'multipleFilesCompleted',
      desc: '',
      args: [count],
    );
  }

  /// `下载完成`
  String get downloadCompleteChannel {
    return Intl.message(
      '下载完成',
      name: 'downloadCompleteChannel',
      desc: '',
      args: [],
    );
  }

  /// `文件下载完成通知`
  String get downloadCompleteChannelDesc {
    return Intl.message(
      '文件下载完成通知',
      name: 'downloadCompleteChannelDesc',
      desc: '',
      args: [],
    );
  }

  /// `打开下载管理`
  String get openDownloadManager {
    return Intl.message(
      '打开下载管理',
      name: 'openDownloadManager',
      desc: '',
      args: [],
    );
  }

  /// `显示下载完成通知失败: {error}`
  String showDownloadCompleteNotificationFailed(String error) {
    return Intl.message(
      '显示下载完成通知失败: $error',
      name: 'showDownloadCompleteNotificationFailed',
      desc: '',
      args: [error],
    );
  }

  /// `显示单个文件下载完成通知失败: {error}`
  String showSingleFileCompleteNotificationFailed(String error) {
    return Intl.message(
      '显示单个文件下载完成通知失败: $error',
      name: 'showSingleFileCompleteNotificationFailed',
      desc: '',
      args: [error],
    );
  }

  /// `取消下载通知失败: {error}`
  String cancelDownloadNotificationFailed(String error) {
    return Intl.message(
      '取消下载通知失败: $error',
      name: 'cancelDownloadNotificationFailed',
      desc: '',
      args: [error],
    );
  }

  /// `取消所有通知失败: {error}`
  String cancelAllNotificationsFailed(String error) {
    return Intl.message(
      '取消所有通知失败: $error',
      name: 'cancelAllNotificationsFailed',
      desc: '',
      args: [error],
    );
  }

  /// `在文件管理器中显示`
  String get showInFileManager {
    return Intl.message(
      '在文件管理器中显示',
      name: 'showInFileManager',
      desc: '',
      args: [],
    );
  }

  /// `大小: {size}`
  String fileSize(String size) {
    return Intl.message('大小: $size', name: 'fileSize', desc: '', args: [size]);
  }

  /// `时间: {time}`
  String fileTime(String time) {
    return Intl.message('时间: $time', name: 'fileTime', desc: '', args: [time]);
  }

  /// `确定`
  String get ok {
    return Intl.message('确定', name: 'ok', desc: '', args: []);
  }

  /// `打开文件管理器`
  String get openFileManager {
    return Intl.message('打开文件管理器', name: 'openFileManager', desc: '', args: []);
  }

  /// `已打开文件管理器`
  String get fileManagerOpened {
    return Intl.message(
      '已打开文件管理器',
      name: 'fileManagerOpened',
      desc: '',
      args: [],
    );
  }

  /// `打开文件管理器失败: {error}`
  String openFileManagerFailed(String error) {
    return Intl.message(
      '打开文件管理器失败: $error',
      name: 'openFileManagerFailed',
      desc: '',
      args: [error],
    );
  }

  /// `已打开下载目录`
  String get downloadDirectoryOpened {
    return Intl.message(
      '已打开下载目录',
      name: 'downloadDirectoryOpened',
      desc: '',
      args: [],
    );
  }

  /// `打开下载目录失败: {error}`
  String openDownloadDirectoryFailed(String error) {
    return Intl.message(
      '打开下载目录失败: $error',
      name: 'openDownloadDirectoryFailed',
      desc: '',
      args: [error],
    );
  }

  /// `下载目录路径未知`
  String get downloadDirectoryPathUnknown {
    return Intl.message(
      '下载目录路径未知',
      name: 'downloadDirectoryPathUnknown',
      desc: '',
      args: [],
    );
  }

  /// `无法获取下载目录`
  String get cannotGetDownloadDirectoryError {
    return Intl.message(
      '无法获取下载目录',
      name: 'cannotGetDownloadDirectoryError',
      desc: '',
      args: [],
    );
  }

  /// `开始下载: {filename}`
  String startDownloadFile(String filename) {
    return Intl.message(
      '开始下载: $filename',
      name: 'startDownloadFile',
      desc: '',
      args: [filename],
    );
  }

  /// `下载完成: {filename}`
  String downloadCompleteFile(String filename) {
    return Intl.message(
      '下载完成: $filename',
      name: 'downloadCompleteFile',
      desc: '',
      args: [filename],
    );
  }

  /// `下载失败: {filename}`
  String downloadFailedFile(String filename) {
    return Intl.message(
      '下载失败: $filename',
      name: 'downloadFailedFile',
      desc: '',
      args: [filename],
    );
  }

  /// `用户取消下载`
  String get userCancelledDownloadError {
    return Intl.message(
      '用户取消下载',
      name: 'userCancelledDownloadError',
      desc: '',
      args: [],
    );
  }

  /// `无法安装 APK 文件，可能需要在设置中开启"允许安装未知来源应用"`
  String get cannotInstallApkNeedPermission {
    return Intl.message(
      '无法安装 APK 文件，可能需要在设置中开启"允许安装未知来源应用"',
      name: 'cannotInstallApkNeedPermission',
      desc: '',
      args: [],
    );
  }

  /// `没有权限安装 APK 文件，请在设置中开启安装权限`
  String get noPermissionToInstallApkFile {
    return Intl.message(
      '没有权限安装 APK 文件，请在设置中开启安装权限',
      name: 'noPermissionToInstallApkFile',
      desc: '',
      args: [],
    );
  }

  /// `准备下载...`
  String get preparingDownloadStatus {
    return Intl.message(
      '准备下载...',
      name: 'preparingDownloadStatus',
      desc: '',
      args: [],
    );
  }

  /// `下载已取消`
  String get downloadCancelledText {
    return Intl.message(
      '下载已取消',
      name: 'downloadCancelledText',
      desc: '',
      args: [],
    );
  }

  /// `语言`
  String get language {
    return Intl.message('语言', name: 'language', desc: '', args: []);
  }

  /// `语言设置`
  String get languageSettings {
    return Intl.message('语言设置', name: 'languageSettings', desc: '', args: []);
  }

  /// `选择应用显示语言`
  String get languageSettingsDesc {
    return Intl.message(
      '选择应用显示语言',
      name: 'languageSettingsDesc',
      desc: '',
      args: [],
    );
  }

  /// `跟随系统`
  String get followSystem {
    return Intl.message('跟随系统', name: 'followSystem', desc: '', args: []);
  }

  /// `简体中文`
  String get simplifiedChinese {
    return Intl.message('简体中文', name: 'simplifiedChinese', desc: '', args: []);
  }

  /// `English`
  String get english {
    return Intl.message('English', name: 'english', desc: '', args: []);
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'zh'),
      Locale.fromSubtags(languageCode: 'en'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
