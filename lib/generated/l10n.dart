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

  /// `设置Admin密码`
  String get setAdminPassword {
    return Intl.message(
      '设置Admin密码',
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

  /// `内置网页浏览器`
  String get webBrowserStatus {
    return Intl.message(
      '内置网页浏览器',
      name: 'webBrowserStatus',
      desc: '',
      args: [],
    );
  }

  /// `运行中`
  String get running {
    return Intl.message('运行中', name: 'running', desc: '', args: []);
  }

  /// `已停止`
  String get stopped {
    return Intl.message('已停止', name: 'stopped', desc: '', args: []);
  }

  /// `停止`
  String get stopWebBrowser {
    return Intl.message('停止', name: 'stopWebBrowser', desc: '', args: []);
  }

  /// `启用内置网页浏览器`
  String get enableWebBrowser {
    return Intl.message(
      '启用内置网页浏览器',
      name: 'enableWebBrowser',
      desc: '',
      args: [],
    );
  }

  /// `允许网页页面运行内置浏览器`
  String get enableWebBrowserDesc {
    return Intl.message(
      '允许网页页面运行内置浏览器',
      name: 'enableWebBrowserDesc',
      desc: '',
      args: [],
    );
  }

  /// `内置网页浏览器已停止`
  String get webBrowserStopped {
    return Intl.message(
      '内置网页浏览器已停止',
      name: 'webBrowserStopped',
      desc: '',
      args: [],
    );
  }

  /// `启动网页浏览器`
  String get startWebBrowser {
    return Intl.message('启动网页浏览器', name: 'startWebBrowser', desc: '', args: []);
  }

  /// `下载进行中，无法停止浏览器`
  String get webBrowserDownloadInProgress {
    return Intl.message(
      '下载进行中，无法停止浏览器',
      name: 'webBrowserDownloadInProgress',
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

  /// `服务将直接使用所选目录，不会迁移现有数据。请只选择应用可访问的本地目录。`
  String get dataDirectoryChangeWarning {
    return Intl.message(
      '服务将直接使用所选目录，不会迁移现有数据。请只选择应用可访问的本地目录。',
      name: 'dataDirectoryChangeWarning',
      desc: '',
      args: [],
    );
  }

  /// `默认目录`
  String get defaultDirectory {
    return Intl.message('默认目录', name: 'defaultDirectory', desc: '', args: []);
  }

  /// `每次下载选择保存位置`
  String get askForDownloadDirectory {
    return Intl.message(
      '每次下载选择保存位置',
      name: 'askForDownloadDirectory',
      desc: '',
      args: [],
    );
  }

  /// `每次下载前询问文件保存位置`
  String get askForDownloadDirectoryDesc {
    return Intl.message(
      '每次下载前询问文件保存位置',
      name: 'askForDownloadDirectoryDesc',
      desc: '',
      args: [],
    );
  }

  /// `OpenList 无法写入所选目录`
  String get downloadDirectoryNotWritable {
    return Intl.message(
      'OpenList 无法写入所选目录',
      name: 'downloadDirectoryNotWritable',
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

  /// `修改Admin密码`
  String get modifyAdminPassword {
    return Intl.message(
      '修改Admin密码',
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

  /// `下载已开始`
  String get downloadStarted {
    return Intl.message('下载已开始', name: 'downloadStarted', desc: '', args: []);
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

  /// `确定要清空 OpenList 管理的所有文件吗？此操作不可撤销。`
  String get confirmClearAllFiles {
    return Intl.message(
      '确定要清空 OpenList 管理的所有文件吗？此操作不可撤销。',
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

  /// `文件名称`
  String get fileName {
    return Intl.message('文件名称', name: 'fileName', desc: '', args: []);
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

  /// `点击查看下载`
  String get clickToJumpToDownloadManager {
    return Intl.message(
      '点击查看下载',
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

  /// `打开下载`
  String get openDownloadManager {
    return Intl.message(
      '打开下载',
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

  /// `疑难解答`
  String get troubleshooting {
    return Intl.message('疑难解答', name: 'troubleshooting', desc: '', args: []);
  }

  /// `常见问题与解决方案`
  String get troubleshootingDesc {
    return Intl.message(
      '常见问题与解决方案',
      name: 'troubleshootingDesc',
      desc: '',
      args: [],
    );
  }

  /// `数据库未保存问题`
  String get databaseNotSavedIssue {
    return Intl.message(
      '数据库未保存问题',
      name: 'databaseNotSavedIssue',
      desc: '',
      args: [],
    );
  }

  /// `如不手动关闭OpenList，则数据库可能不会被保存到对应的db文件中，如遇到此问题，请手动关闭以解决此问题。（开关位于主程序菜单OpenList界面，以及通知栏的通知上）`
  String get databaseNotSavedIssueDesc {
    return Intl.message(
      '如不手动关闭OpenList，则数据库可能不会被保存到对应的db文件中，如遇到此问题，请手动关闭以解决此问题。（开关位于主程序菜单OpenList界面，以及通知栏的通知上）',
      name: 'databaseNotSavedIssueDesc',
      desc: '',
      args: [],
    );
  }

  /// `自启动相关说明`
  String get autoStartIssue {
    return Intl.message('自启动相关说明', name: 'autoStartIssue', desc: '', args: []);
  }

  /// `设置自启动时建议把app的电池优化一并关闭，当前在开启自启动后，系统重启时服务会自动在后台启动，但可能不会在通知栏弹出通知。请放心，服务已正常运行，您可以在通知栏快捷开关查看服务状态，或回到主界面查看服务开关确认服务是否已启动。`
  String get autoStartIssueDesc {
    return Intl.message(
      '设置自启动时建议把app的电池优化一并关闭，当前在开启自启动后，系统重启时服务会自动在后台启动，但可能不会在通知栏弹出通知。请放心，服务已正常运行，您可以在通知栏快捷开关查看服务状态，或回到主界面查看服务开关确认服务是否已启动。',
      name: 'autoStartIssueDesc',
      desc: '',
      args: [],
    );
  }

  /// `正在下载`
  String get currentlyDownloading {
    return Intl.message(
      '正在下载',
      name: 'currentlyDownloading',
      desc: '',
      args: [],
    );
  }

  /// `下载进度`
  String get downloadProgressChannel {
    return Intl.message(
      '下载进度',
      name: 'downloadProgressChannel',
      desc: '',
      args: [],
    );
  }

  /// `确认下载`
  String get confirmDownload {
    return Intl.message('确认下载', name: 'confirmDownload', desc: '', args: []);
  }

  /// `是否要下载这个文件？`
  String get confirmDownloadMessage {
    return Intl.message(
      '是否要下载这个文件？',
      name: 'confirmDownloadMessage',
      desc: '',
      args: [],
    );
  }

  /// `正在下载图片...`
  String get downloadingImage {
    return Intl.message(
      '正在下载图片...',
      name: 'downloadingImage',
      desc: '',
      args: [],
    );
  }

  /// `稍后安装`
  String get laterInstall {
    return Intl.message('稍后安装', name: 'laterInstall', desc: '', args: []);
  }

  /// `立即安装`
  String get installNow {
    return Intl.message('立即安装', name: 'installNow', desc: '', args: []);
  }

  /// `直接下载`
  String get directDownloadMethod {
    return Intl.message(
      '直接下载',
      name: 'directDownloadMethod',
      desc: '',
      args: [],
    );
  }

  /// `使用应用内下载器`
  String get directDownloadMethodDesc {
    return Intl.message(
      '使用应用内下载器',
      name: 'directDownloadMethodDesc',
      desc: '',
      args: [],
    );
  }

  /// `浏览器下载`
  String get browserDownloadMethod {
    return Intl.message(
      '浏览器下载',
      name: 'browserDownloadMethod',
      desc: '',
      args: [],
    );
  }

  /// `使用系统浏览器`
  String get browserDownloadMethodDesc {
    return Intl.message(
      '使用系统浏览器',
      name: 'browserDownloadMethodDesc',
      desc: '',
      args: [],
    );
  }

  /// `分享链接`
  String get shareLink {
    return Intl.message('分享链接', name: 'shareLink', desc: '', args: []);
  }

  /// `分享下载链接`
  String get shareLinkDesc {
    return Intl.message('分享下载链接', name: 'shareLinkDesc', desc: '', args: []);
  }

  /// `查看`
  String get view {
    return Intl.message('查看', name: 'view', desc: '', args: []);
  }

  /// `下载功能测试`
  String get downloadFunctionTest {
    return Intl.message(
      '下载功能测试',
      name: 'downloadFunctionTest',
      desc: '',
      args: [],
    );
  }

  /// `测试直接下载功能`
  String get testDirectDownloadFunction {
    return Intl.message(
      '测试直接下载功能',
      name: 'testDirectDownloadFunction',
      desc: '',
      args: [],
    );
  }

  /// `测试下载JSON文件`
  String get testDownloadJsonFile {
    return Intl.message(
      '测试下载JSON文件',
      name: 'testDownloadJsonFile',
      desc: '',
      args: [],
    );
  }

  /// `测试下载PNG图片`
  String get testDownloadPngImage {
    return Intl.message(
      '测试下载PNG图片',
      name: 'testDownloadPngImage',
      desc: '',
      args: [],
    );
  }

  /// `测试下载大文件(1MB)`
  String get testDownloadLargeFile {
    return Intl.message(
      '测试下载大文件(1MB)',
      name: 'testDownloadLargeFile',
      desc: '',
      args: [],
    );
  }

  /// `查看下载文件`
  String get viewDownloadFiles {
    return Intl.message(
      '查看下载文件',
      name: 'viewDownloadFiles',
      desc: '',
      args: [],
    );
  }

  /// `请通过底部导航栏的"下载管理"查看下载文件`
  String get checkDownloadManagerForFiles {
    return Intl.message(
      '请通过底部导航栏的"下载管理"查看下载文件',
      name: 'checkDownloadManagerForFiles',
      desc: '',
      args: [],
    );
  }

  /// `查看下载目录`
  String get viewDownloadDirectory {
    return Intl.message(
      '查看下载目录',
      name: 'viewDownloadDirectory',
      desc: '',
      args: [],
    );
  }

  /// `获取失败`
  String get getDownloadPathFailed {
    return Intl.message(
      '获取失败',
      name: 'getDownloadPathFailed',
      desc: '',
      args: [],
    );
  }

  /// `是否要打开下载测试页面？`
  String get openDownloadTestPage {
    return Intl.message(
      '是否要打开下载测试页面？',
      name: 'openDownloadTestPage',
      desc: '',
      args: [],
    );
  }

  /// `说明：`
  String get description {
    return Intl.message('说明：', name: 'description', desc: '', args: []);
  }

  /// `• 文件将下载到系统下载目录\n• 下载过程会显示进度通知\n• 下载完成后可以选择打开文件\n• 如果文件名重复会自动添加序号\n• 请通过底部导航栏的\"下载管理\"查看下载文件`
  String get downloadInstructions {
    return Intl.message(
      '• 文件将下载到系统下载目录\\n• 下载过程会显示进度通知\\n• 下载完成后可以选择打开文件\\n• 如果文件名重复会自动添加序号\\n• 请通过底部导航栏的\\"下载管理\\"查看下载文件',
      name: 'downloadInstructions',
      desc: '',
      args: [],
    );
  }

  /// `选择下载方式`
  String get selectDownloadMethod {
    return Intl.message(
      '选择下载方式',
      name: 'selectDownloadMethod',
      desc: '',
      args: [],
    );
  }

  /// `批量下载完成`
  String get batchDownloadComplete {
    return Intl.message(
      '批量下载完成',
      name: 'batchDownloadComplete',
      desc: '',
      args: [],
    );
  }

  /// `图片下载成功`
  String get imageDownloadSuccess {
    return Intl.message(
      '图片下载成功',
      name: 'imageDownloadSuccess',
      desc: '',
      args: [],
    );
  }

  /// `请在下载目录查看图片`
  String get checkImageInDownloadFolder {
    return Intl.message(
      '请在下载目录查看图片',
      name: 'checkImageInDownloadFolder',
      desc: '',
      args: [],
    );
  }

  /// `请在下载目录找到APK文件进行安装`
  String get findApkInDownloadFolder {
    return Intl.message(
      '请在下载目录找到APK文件进行安装',
      name: 'findApkInDownloadFolder',
      desc: '',
      args: [],
    );
  }

  /// `正在下载第 {current}/{total} 个文件`
  String downloadingFileProgress(int current, int total) {
    return Intl.message(
      '正在下载第 $current/$total 个文件',
      name: 'downloadingFileProgress',
      desc: '',
      args: [current, total],
    );
  }

  /// `第 {index} 个文件下载失败`
  String fileDownloadFailed(int index) {
    return Intl.message(
      '第 $index 个文件下载失败',
      name: 'fileDownloadFailed',
      desc: '',
      args: [index],
    );
  }

  /// `APK文件已下载完成，是否要安装？`
  String get apkDownloadCompleteMessage {
    return Intl.message(
      'APK文件已下载完成，是否要安装？',
      name: 'apkDownloadCompleteMessage',
      desc: '',
      args: [],
    );
  }

  /// `OpenList`
  String get openlist {
    return Intl.message('OpenList', name: 'openlist', desc: '', args: []);
  }

  /// `OpenList Mobile`
  String get openlistMobile {
    return Intl.message(
      'OpenList Mobile',
      name: 'openlistMobile',
      desc: '',
      args: [],
    );
  }

  /// `开源许可证`
  String get openSourceLicenses {
    return Intl.message(
      '开源许可证',
      name: 'openSourceLicenses',
      desc: '',
      args: [],
    );
  }

  /// `查看第三方许可证`
  String get viewThirdPartyLicenses {
    return Intl.message(
      '查看第三方许可证',
      name: 'viewThirdPartyLicenses',
      desc: '',
      args: [],
    );
  }

  /// `修改OpenList配置文件`
  String get editOpenListConfig {
    return Intl.message(
      '修改OpenList配置文件',
      name: 'editOpenListConfig',
      desc: '',
      args: [],
    );
  }

  /// `保存`
  String get save {
    return Intl.message('保存', name: 'save', desc: '', args: []);
  }

  /// `已保存`
  String get saved {
    return Intl.message('已保存', name: 'saved', desc: '', args: []);
  }

  /// `编辑`
  String get edit {
    return Intl.message('编辑', name: 'edit', desc: '', args: []);
  }

  /// `预览`
  String get preview {
    return Intl.message('预览', name: 'preview', desc: '', args: []);
  }

  /// `文件不存在,保存时将创建`
  String get fileNotFoundWillCreateOnSave {
    return Intl.message(
      '文件不存在,保存时将创建',
      name: 'fileNotFoundWillCreateOnSave',
      desc: '',
      args: [],
    );
  }

  /// `加载失败:{error}`
  String loadFailed(String error) {
    return Intl.message(
      '加载失败:$error',
      name: 'loadFailed',
      desc: '',
      args: [error],
    );
  }

  /// `保存失败:{error}`
  String saveFailed(String error) {
    return Intl.message(
      '保存失败:$error',
      name: 'saveFailed',
      desc: '',
      args: [error],
    );
  }

  /// `JSON格式错误,第{line}行:{error}`
  String invalidJsonFormat(int line, String error) {
    return Intl.message(
      'JSON格式错误,第$line行:$error',
      name: 'invalidJsonFormat',
      desc: '',
      args: [line, error],
    );
  }

  /// `文件权限被拒绝,请检查应用权限`
  String get filePermissionDenied {
    return Intl.message(
      '文件权限被拒绝,请检查应用权限',
      name: 'filePermissionDenied',
      desc: '',
      args: [],
    );
  }

  /// `配置已保存,请重启OpenList服务以生效`
  String get configSavedRestartRequired {
    return Intl.message(
      '配置已保存,请重启OpenList服务以生效',
      name: 'configSavedRestartRequired',
      desc: '',
      args: [],
    );
  }

  /// `确认保存`
  String get confirmSaveConfigTitle {
    return Intl.message(
      '确认保存',
      name: 'confirmSaveConfigTitle',
      desc: '',
      args: [],
    );
  }

  /// `修改配置可能导致服务不可用,确定保存吗?`
  String get confirmSaveConfigMessage {
    return Intl.message(
      '修改配置可能导致服务不可用,确定保存吗?',
      name: 'confirmSaveConfigMessage',
      desc: '',
      args: [],
    );
  }

  /// `保存并重启`
  String get saveAndRestart {
    return Intl.message('保存并重启', name: 'saveAndRestart', desc: '', args: []);
  }

  /// `仅保存`
  String get saveOnly {
    return Intl.message('仅保存', name: 'saveOnly', desc: '', args: []);
  }

  /// `恢复备份`
  String get restoreBackup {
    return Intl.message('恢复备份', name: 'restoreBackup', desc: '', args: []);
  }

  /// `备份已恢复`
  String get backupRestored {
    return Intl.message('备份已恢复', name: 'backupRestored', desc: '', args: []);
  }

  /// `未找到备份文件`
  String get noBackupFound {
    return Intl.message('未找到备份文件', name: 'noBackupFound', desc: '', args: []);
  }

  /// `恢复备份失败:{error}`
  String restoreBackupFailed(String error) {
    return Intl.message(
      '恢复备份失败:$error',
      name: 'restoreBackupFailed',
      desc: '',
      args: [error],
    );
  }

  /// `正在重启OpenList服务...`
  String get restartingService {
    return Intl.message(
      '正在重启OpenList服务...',
      name: 'restartingService',
      desc: '',
      args: [],
    );
  }

  /// `服务重启成功`
  String get serviceRestartSuccess {
    return Intl.message(
      '服务重启成功',
      name: 'serviceRestartSuccess',
      desc: '',
      args: [],
    );
  }

  /// `服务重启失败,请手动重启`
  String get serviceRestartFailed {
    return Intl.message(
      '服务重启失败,请手动重启',
      name: 'serviceRestartFailed',
      desc: '',
      args: [],
    );
  }

  /// `服务重启仅支持Android系统`
  String get serviceRestartOnlyAndroid {
    return Intl.message(
      '服务重启仅支持Android系统',
      name: 'serviceRestartOnlyAndroid',
      desc: '',
      args: [],
    );
  }

  /// `文件`
  String get nativeFiles {
    return Intl.message('文件', name: 'nativeFiles', desc: '', args: []);
  }

  /// `存储`
  String get storages {
    return Intl.message('存储', name: 'storages', desc: '', args: []);
  }

  /// `任务`
  String get tasks {
    return Intl.message('任务', name: 'tasks', desc: '', args: []);
  }

  /// `服务器`
  String get serverRuntime {
    return Intl.message('服务器', name: 'serverRuntime', desc: '', args: []);
  }

  /// `连接`
  String get connection {
    return Intl.message('连接', name: 'connection', desc: '', args: []);
  }

  /// `本机服务器`
  String get localServer {
    return Intl.message('本机服务器', name: 'localServer', desc: '', args: []);
  }

  /// `远程服务器`
  String get remoteServer {
    return Intl.message('远程服务器', name: 'remoteServer', desc: '', args: []);
  }

  /// `服务器地址`
  String get serverUrl {
    return Intl.message('服务器地址', name: 'serverUrl', desc: '', args: []);
  }

  /// `用户名`
  String get username {
    return Intl.message('用户名', name: 'username', desc: '', args: []);
  }

  /// `密码`
  String get password {
    return Intl.message('密码', name: 'password', desc: '', args: []);
  }

  /// `两步验证码（可选）`
  String get otpCode {
    return Intl.message('两步验证码（可选）', name: 'otpCode', desc: '', args: []);
  }

  /// `登录`
  String get login {
    return Intl.message('登录', name: 'login', desc: '', args: []);
  }

  /// `退出登录`
  String get logout {
    return Intl.message('退出登录', name: 'logout', desc: '', args: []);
  }

  /// `连接失败`
  String get connectFailed {
    return Intl.message('连接失败', name: 'connectFailed', desc: '', args: []);
  }

  /// `本机服务器未运行`
  String get serverNotRunning {
    return Intl.message(
      '本机服务器未运行',
      name: 'serverNotRunning',
      desc: '',
      args: [],
    );
  }

  /// `启动服务器`
  String get startServer {
    return Intl.message('启动服务器', name: 'startServer', desc: '', args: []);
  }

  /// `停止服务器`
  String get stopServer {
    return Intl.message('停止服务器', name: 'stopServer', desc: '', args: []);
  }

  /// `重启服务器`
  String get restartServer {
    return Intl.message('重启服务器', name: 'restartServer', desc: '', args: []);
  }

  /// `重试`
  String get retry {
    return Intl.message('重试', name: 'retry', desc: '', args: []);
  }

  /// `文件夹为空`
  String get emptyFolder {
    return Intl.message('文件夹为空', name: 'emptyFolder', desc: '', args: []);
  }

  /// `新建文件夹`
  String get newFolder {
    return Intl.message('新建文件夹', name: 'newFolder', desc: '', args: []);
  }

  /// `文件夹名称`
  String get folderName {
    return Intl.message('文件夹名称', name: 'folderName', desc: '', args: []);
  }

  /// `重命名`
  String get rename {
    return Intl.message('重命名', name: 'rename', desc: '', args: []);
  }

  /// `新名称`
  String get newName {
    return Intl.message('新名称', name: 'newName', desc: '', args: []);
  }

  /// `移动到`
  String get moveTo {
    return Intl.message('移动到', name: 'moveTo', desc: '', args: []);
  }

  /// `复制到`
  String get copyTo {
    return Intl.message('复制到', name: 'copyTo', desc: '', args: []);
  }

  /// `选择此文件夹`
  String get selectThisFolder {
    return Intl.message('选择此文件夹', name: 'selectThisFolder', desc: '', args: []);
  }

  /// `上传`
  String get upload {
    return Intl.message('上传', name: 'upload', desc: '', args: []);
  }

  /// `正在上传 {name}`
  String uploadingFile(String name) {
    return Intl.message(
      '正在上传 $name',
      name: 'uploadingFile',
      desc: '',
      args: [name],
    );
  }

  /// `上传完成`
  String get uploadDone {
    return Intl.message('上传完成', name: 'uploadDone', desc: '', args: []);
  }

  /// `上传失败`
  String get uploadFailed {
    return Intl.message('上传失败', name: 'uploadFailed', desc: '', args: []);
  }

  /// `完成`
  String get operationDone {
    return Intl.message('完成', name: 'operationDone', desc: '', args: []);
  }

  /// `操作失败`
  String get operationFailed {
    return Intl.message('操作失败', name: 'operationFailed', desc: '', args: []);
  }

  /// `确定删除 {names}？`
  String confirmDeleteItems(String names) {
    return Intl.message(
      '确定删除 $names？',
      name: 'confirmDeleteItems',
      desc: '',
      args: [names],
    );
  }

  /// `文件夹密码`
  String get folderPassword {
    return Intl.message('文件夹密码', name: 'folderPassword', desc: '', args: []);
  }

  /// `不支持预览该类型文件`
  String get previewNotSupported {
    return Intl.message(
      '不支持预览该类型文件',
      name: 'previewNotSupported',
      desc: '',
      args: [],
    );
  }

  /// `复制链接`
  String get copyLink {
    return Intl.message('复制链接', name: 'copyLink', desc: '', args: []);
  }

  /// `打开网页界面`
  String get openWebInterface {
    return Intl.message('打开网页界面', name: 'openWebInterface', desc: '', args: []);
  }

  /// `已禁用`
  String get storageDisabled {
    return Intl.message('已禁用', name: 'storageDisabled', desc: '', args: []);
  }

  /// `启用`
  String get enable {
    return Intl.message('启用', name: 'enable', desc: '', args: []);
  }

  /// `禁用`
  String get disable {
    return Intl.message('禁用', name: 'disable', desc: '', args: []);
  }

  /// `添加存储`
  String get addStorage {
    return Intl.message('添加存储', name: 'addStorage', desc: '', args: []);
  }

  /// `编辑存储`
  String get editStorage {
    return Intl.message('编辑存储', name: 'editStorage', desc: '', args: []);
  }

  /// `驱动`
  String get driver {
    return Intl.message('驱动', name: 'driver', desc: '', args: []);
  }

  /// `全部重新加载`
  String get reloadAll {
    return Intl.message('全部重新加载', name: 'reloadAll', desc: '', args: []);
  }

  /// `确定删除存储 {name}？`
  String confirmDeleteStorage(String name) {
    return Intl.message(
      '确定删除存储 $name？',
      name: 'confirmDeleteStorage',
      desc: '',
      args: [name],
    );
  }

  /// `必填`
  String get requiredField {
    return Intl.message('必填', name: 'requiredField', desc: '', args: []);
  }

  /// `需要管理员权限`
  String get adminOnly {
    return Intl.message('需要管理员权限', name: 'adminOnly', desc: '', args: []);
  }

  /// `进行中`
  String get taskUndone {
    return Intl.message('进行中', name: 'taskUndone', desc: '', args: []);
  }

  /// `已结束`
  String get taskDone {
    return Intl.message('已结束', name: 'taskDone', desc: '', args: []);
  }

  /// `上传`
  String get taskGroupUpload {
    return Intl.message('上传', name: 'taskGroupUpload', desc: '', args: []);
  }

  /// `复制`
  String get taskGroupCopy {
    return Intl.message('复制', name: 'taskGroupCopy', desc: '', args: []);
  }

  /// `移动`
  String get taskGroupMove {
    return Intl.message('移动', name: 'taskGroupMove', desc: '', args: []);
  }

  /// `离线下载`
  String get taskGroupOfflineDownload {
    return Intl.message(
      '离线下载',
      name: 'taskGroupOfflineDownload',
      desc: '',
      args: [],
    );
  }

  /// `离线转存`
  String get taskGroupTransfer {
    return Intl.message('离线转存', name: 'taskGroupTransfer', desc: '', args: []);
  }

  /// `解压`
  String get taskGroupDecompress {
    return Intl.message('解压', name: 'taskGroupDecompress', desc: '', args: []);
  }

  /// `解压上传`
  String get taskGroupDecompressUpload {
    return Intl.message(
      '解压上传',
      name: 'taskGroupDecompressUpload',
      desc: '',
      args: [],
    );
  }

  /// `清除已成功`
  String get clearSucceeded {
    return Intl.message('清除已成功', name: 'clearSucceeded', desc: '', args: []);
  }

  /// `清除已结束`
  String get clearFinished {
    return Intl.message('清除已结束', name: 'clearFinished', desc: '', args: []);
  }

  /// `暂无任务`
  String get noTasks {
    return Intl.message('暂无任务', name: 'noTasks', desc: '', args: []);
  }

  /// `访问模式`
  String get exposureMode {
    return Intl.message('访问模式', name: 'exposureMode', desc: '', args: []);
  }

  /// `仅本机`
  String get modeLocal {
    return Intl.message('仅本机', name: 'modeLocal', desc: '', args: []);
  }

  /// `仅监听 127.0.0.1，其他设备无法访问。`
  String get modeLocalDesc {
    return Intl.message(
      '仅监听 127.0.0.1，其他设备无法访问。',
      name: 'modeLocalDesc',
      desc: '',
      args: [],
    );
  }

  /// `局域网`
  String get modeLan {
    return Intl.message('局域网', name: 'modeLan', desc: '', args: []);
  }

  /// `监听所有网卡，同一网络中的设备可以访问。`
  String get modeLanDesc {
    return Intl.message(
      '监听所有网卡，同一网络中的设备可以访问。',
      name: 'modeLanDesc',
      desc: '',
      args: [],
    );
  }

  /// `公网`
  String get modePublic {
    return Intl.message('公网', name: 'modePublic', desc: '', args: []);
  }

  /// `可从互联网访问。需要 TLS、强制 HTTPS 并禁用游客账户。`
  String get modePublicDesc {
    return Intl.message(
      '可从互联网访问。需要 TLS、强制 HTTPS 并禁用游客账户。',
      name: 'modePublicDesc',
      desc: '',
      args: [],
    );
  }

  /// `新模式在服务器重启后生效。`
  String get modeChangeRestart {
    return Intl.message(
      '新模式在服务器重启后生效。',
      name: 'modeChangeRestart',
      desc: '',
      args: [],
    );
  }

  /// `将服务器暴露到公网后任何人都可以访问。请确保管理员密码足够强并开启两步验证。`
  String get publicModeWarning {
    return Intl.message(
      '将服务器暴露到公网后任何人都可以访问。请确保管理员密码足够强并开启两步验证。',
      name: 'publicModeWarning',
      desc: '',
      args: [],
    );
  }

  /// `安全检查`
  String get securityChecks {
    return Intl.message('安全检查', name: 'securityChecks', desc: '', args: []);
  }

  /// `在所有必需检查通过之前无法启用公网模式。`
  String get publicBlocked {
    return Intl.message(
      '在所有必需检查通过之前无法启用公网模式。',
      name: 'publicBlocked',
      desc: '',
      args: [],
    );
  }

  /// `有效的 TLS 证书`
  String get checkTls {
    return Intl.message('有效的 TLS 证书', name: 'checkTls', desc: '', args: []);
  }

  /// `禁用 HTTP 或强制跳转 HTTPS`
  String get checkForceHttps {
    return Intl.message(
      '禁用 HTTP 或强制跳转 HTTPS',
      name: 'checkForceHttps',
      desc: '',
      args: [],
    );
  }

  /// `游客账户已禁用`
  String get checkGuestDisabled {
    return Intl.message(
      '游客账户已禁用',
      name: 'checkGuestDisabled',
      desc: '',
      args: [],
    );
  }

  /// `S3 服务使用 TLS`
  String get checkS3Tls {
    return Intl.message('S3 服务使用 TLS', name: 'checkS3Tls', desc: '', args: []);
  }

  /// `FTP 以明文传输凭据`
  String get checkFtpPlaintext {
    return Intl.message(
      'FTP 以明文传输凭据',
      name: 'checkFtpPlaintext',
      desc: '',
      args: [],
    );
  }

  /// `管理员两步验证`
  String get checkAdmin2fa {
    return Intl.message('管理员两步验证', name: 'checkAdmin2fa', desc: '', args: []);
  }

  /// `服务器尚未初始化`
  String get checkNotInitialized {
    return Intl.message(
      '服务器尚未初始化',
      name: 'checkNotInitialized',
      desc: '',
      args: [],
    );
  }

  /// `访问地址`
  String get addresses {
    return Intl.message('访问地址', name: 'addresses', desc: '', args: []);
  }

  /// `运行状态`
  String get runtimeStatus {
    return Intl.message('运行状态', name: 'runtimeStatus', desc: '', args: []);
  }

  /// `运行时间`
  String get uptime {
    return Intl.message('运行时间', name: 'uptime', desc: '', args: []);
  }

  /// `协程数`
  String get goroutines {
    return Intl.message('协程数', name: 'goroutines', desc: '', args: []);
  }

  /// `内存`
  String get memory {
    return Intl.message('内存', name: 'memory', desc: '', args: []);
  }

  /// `进程内存 (PSS)`
  String get processMemory {
    return Intl.message(
      '进程内存 (PSS)',
      name: 'processMemory',
      desc: '',
      args: [],
    );
  }

  /// `CPU 时间`
  String get cpuTime {
    return Intl.message('CPU 时间', name: 'cpuTime', desc: '', args: []);
  }

  /// `最近错误`
  String get lastError {
    return Intl.message('最近错误', name: 'lastError', desc: '', args: []);
  }

  /// `后台运行`
  String get backgroundRunning {
    return Intl.message('后台运行', name: 'backgroundRunning', desc: '', args: []);
  }

  /// `电池优化`
  String get batteryOptimization {
    return Intl.message(
      '电池优化',
      name: 'batteryOptimization',
      desc: '',
      args: [],
    );
  }

  /// `未限制`
  String get batteryOptimizationIgnored {
    return Intl.message(
      '未限制',
      name: 'batteryOptimizationIgnored',
      desc: '',
      args: [],
    );
  }

  /// `受限制，系统可能会停止服务器。`
  String get batteryOptimizationActive {
    return Intl.message(
      '受限制，系统可能会停止服务器。',
      name: 'batteryOptimizationActive',
      desc: '',
      args: [],
    );
  }

  /// `允许后台运行`
  String get requestIgnoreBattery {
    return Intl.message(
      '允许后台运行',
      name: 'requestIgnoreBattery',
      desc: '',
      args: [],
    );
  }

  /// `自启动设置`
  String get autoStartSettings {
    return Intl.message('自启动设置', name: 'autoStartSettings', desc: '', args: []);
  }

  /// `部分厂商系统需要允许自启动，否则会停止后台应用。`
  String get autoStartSettingsDesc {
    return Intl.message(
      '部分厂商系统需要允许自启动，否则会停止后台应用。',
      name: 'autoStartSettingsDesc',
      desc: '',
      args: [],
    );
  }

  /// `系统限制了后台活动`
  String get backgroundRestricted {
    return Intl.message(
      '系统限制了后台活动',
      name: 'backgroundRestricted',
      desc: '',
      args: [],
    );
  }

  /// `通知已关闭，服务器状态通知不会显示`
  String get notificationsDisabled {
    return Intl.message(
      '通知已关闭，服务器状态通知不会显示',
      name: 'notificationsDisabled',
      desc: '',
      args: [],
    );
  }

  /// `待机分组`
  String get standbyBucket {
    return Intl.message('待机分组', name: 'standbyBucket', desc: '', args: []);
  }

  /// `应用详情`
  String get appDetails {
    return Intl.message('应用详情', name: 'appDetails', desc: '', args: []);
  }

  /// `iOS 仅在应用处于前台或刚切到后台的短时间内保持服务器运行。`
  String get iosBackgroundNote {
    return Intl.message(
      'iOS 仅在应用处于前台或刚切到后台的短时间内保持服务器运行。',
      name: 'iosBackgroundNote',
      desc: '',
      args: [],
    );
  }

  /// `搜索`
  String get search {
    return Intl.message('搜索', name: 'search', desc: '', args: []);
  }

  /// `关键词`
  String get searchHint {
    return Intl.message('关键词', name: 'searchHint', desc: '', args: []);
  }

  /// `全部`
  String get searchAll {
    return Intl.message('全部', name: 'searchAll', desc: '', args: []);
  }

  /// `文件夹`
  String get searchFolders {
    return Intl.message('文件夹', name: 'searchFolders', desc: '', args: []);
  }

  /// `文件`
  String get searchFiles {
    return Intl.message('文件', name: 'searchFiles', desc: '', args: []);
  }

  /// `没有结果`
  String get noSearchResults {
    return Intl.message('没有结果', name: 'noSearchResults', desc: '', args: []);
  }

  /// `离线下载`
  String get offlineDownload {
    return Intl.message('离线下载', name: 'offlineDownload', desc: '', args: []);
  }

  /// `链接（每行一个）`
  String get offlineUrls {
    return Intl.message('链接（每行一个）', name: 'offlineUrls', desc: '', args: []);
  }

  /// `工具`
  String get offlineTool {
    return Intl.message('工具', name: 'offlineTool', desc: '', args: []);
  }

  /// `删除策略`
  String get deletePolicy {
    return Intl.message('删除策略', name: 'deletePolicy', desc: '', args: []);
  }

  /// `服务器未配置离线下载工具`
  String get noOfflineTools {
    return Intl.message(
      '服务器未配置离线下载工具',
      name: 'noOfflineTools',
      desc: '',
      args: [],
    );
  }

  /// `已添加离线下载任务`
  String get offlineAdded {
    return Intl.message('已添加离线下载任务', name: 'offlineAdded', desc: '', args: []);
  }

  /// `上传成功后删除`
  String get policyDeleteOnUploadSucceed {
    return Intl.message(
      '上传成功后删除',
      name: 'policyDeleteOnUploadSucceed',
      desc: '',
      args: [],
    );
  }

  /// `上传失败后删除`
  String get policyDeleteOnUploadFailed {
    return Intl.message(
      '上传失败后删除',
      name: 'policyDeleteOnUploadFailed',
      desc: '',
      args: [],
    );
  }

  /// `从不删除`
  String get policyDeleteNever {
    return Intl.message('从不删除', name: 'policyDeleteNever', desc: '', args: []);
  }

  /// `总是删除`
  String get policyDeleteAlways {
    return Intl.message('总是删除', name: 'policyDeleteAlways', desc: '', args: []);
  }

  /// `边下载边上传`
  String get policyUploadDownloadStream {
    return Intl.message(
      '边下载边上传',
      name: 'policyUploadDownloadStream',
      desc: '',
      args: [],
    );
  }

  /// `用户`
  String get users {
    return Intl.message('用户', name: 'users', desc: '', args: []);
  }

  /// `添加用户`
  String get addUser {
    return Intl.message('添加用户', name: 'addUser', desc: '', args: []);
  }

  /// `编辑用户`
  String get editUser {
    return Intl.message('编辑用户', name: 'editUser', desc: '', args: []);
  }

  /// `基础路径`
  String get basePath {
    return Intl.message('基础路径', name: 'basePath', desc: '', args: []);
  }

  /// `角色`
  String get role {
    return Intl.message('角色', name: 'role', desc: '', args: []);
  }

  /// `普通用户`
  String get roleGeneral {
    return Intl.message('普通用户', name: 'roleGeneral', desc: '', args: []);
  }

  /// `访客`
  String get roleGuest {
    return Intl.message('访客', name: 'roleGuest', desc: '', args: []);
  }

  /// `管理员`
  String get roleAdmin {
    return Intl.message('管理员', name: 'roleAdmin', desc: '', args: []);
  }

  /// `权限`
  String get permissions {
    return Intl.message('权限', name: 'permissions', desc: '', args: []);
  }

  /// `已禁用`
  String get userDisabled {
    return Intl.message('已禁用', name: 'userDisabled', desc: '', args: []);
  }

  /// `留空则保持当前密码`
  String get passwordKeepHint {
    return Intl.message(
      '留空则保持当前密码',
      name: 'passwordKeepHint',
      desc: '',
      args: [],
    );
  }

  /// `重置两步验证`
  String get reset2fa {
    return Intl.message('重置两步验证', name: 'reset2fa', desc: '', args: []);
  }

  /// `查看隐藏文件`
  String get permSeeHides {
    return Intl.message('查看隐藏文件', name: 'permSeeHides', desc: '', args: []);
  }

  /// `无需密码访问`
  String get permAccessWithoutPassword {
    return Intl.message(
      '无需密码访问',
      name: 'permAccessWithoutPassword',
      desc: '',
      args: [],
    );
  }

  /// `添加离线下载`
  String get permOfflineDownload {
    return Intl.message(
      '添加离线下载',
      name: 'permOfflineDownload',
      desc: '',
      args: [],
    );
  }

  /// `创建文件夹和上传`
  String get permWrite {
    return Intl.message('创建文件夹和上传', name: 'permWrite', desc: '', args: []);
  }

  /// `重命名`
  String get permRename {
    return Intl.message('重命名', name: 'permRename', desc: '', args: []);
  }

  /// `移动`
  String get permMove {
    return Intl.message('移动', name: 'permMove', desc: '', args: []);
  }

  /// `复制`
  String get permCopy {
    return Intl.message('复制', name: 'permCopy', desc: '', args: []);
  }

  /// `删除`
  String get permRemove {
    return Intl.message('删除', name: 'permRemove', desc: '', args: []);
  }

  /// `WebDAV 读取`
  String get permWebdavRead {
    return Intl.message(
      'WebDAV 读取',
      name: 'permWebdavRead',
      desc: '',
      args: [],
    );
  }

  /// `WebDAV 写入`
  String get permWebdavManage {
    return Intl.message(
      'WebDAV 写入',
      name: 'permWebdavManage',
      desc: '',
      args: [],
    );
  }

  /// `FTP/SFTP 读取`
  String get permFtpAccess {
    return Intl.message(
      'FTP/SFTP 读取',
      name: 'permFtpAccess',
      desc: '',
      args: [],
    );
  }

  /// `FTP/SFTP 写入`
  String get permFtpManage {
    return Intl.message(
      'FTP/SFTP 写入',
      name: 'permFtpManage',
      desc: '',
      args: [],
    );
  }

  /// `读取压缩包`
  String get permReadArchives {
    return Intl.message('读取压缩包', name: 'permReadArchives', desc: '', args: []);
  }

  /// `解压压缩包`
  String get permDecompress {
    return Intl.message('解压压缩包', name: 'permDecompress', desc: '', args: []);
  }

  /// `创建分享`
  String get permShare {
    return Intl.message('创建分享', name: 'permShare', desc: '', args: []);
  }

  /// `自定义分享 ID`
  String get permCustomShareId {
    return Intl.message(
      '自定义分享 ID',
      name: 'permCustomShareId',
      desc: '',
      args: [],
    );
  }

  /// `站点设置`
  String get siteSettings {
    return Intl.message('站点设置', name: 'siteSettings', desc: '', args: []);
  }

  /// `API 令牌`
  String get apiToken {
    return Intl.message('API 令牌', name: 'apiToken', desc: '', args: []);
  }

  /// `重置 API 令牌`
  String get resetToken {
    return Intl.message('重置 API 令牌', name: 'resetToken', desc: '', args: []);
  }

  /// `重置 API 令牌会使使用当前令牌的客户端失效，是否继续？`
  String get resetTokenConfirm {
    return Intl.message(
      '重置 API 令牌会使使用当前令牌的客户端失效，是否继续？',
      name: 'resetTokenConfirm',
      desc: '',
      args: [],
    );
  }

  /// `API 令牌已重置`
  String get resetTokenSuccess {
    return Intl.message(
      'API 令牌已重置',
      name: 'resetTokenSuccess',
      desc: '',
      args: [],
    );
  }

  /// `站点`
  String get groupSite {
    return Intl.message('站点', name: 'groupSite', desc: '', args: []);
  }

  /// `样式`
  String get groupStyle {
    return Intl.message('样式', name: 'groupStyle', desc: '', args: []);
  }

  /// `预览`
  String get groupPreview {
    return Intl.message('预览', name: 'groupPreview', desc: '', args: []);
  }

  /// `全局`
  String get groupGlobal {
    return Intl.message('全局', name: 'groupGlobal', desc: '', args: []);
  }

  /// `离线下载`
  String get groupOfflineDownload {
    return Intl.message(
      '离线下载',
      name: 'groupOfflineDownload',
      desc: '',
      args: [],
    );
  }

  /// `索引`
  String get groupIndex {
    return Intl.message('索引', name: 'groupIndex', desc: '', args: []);
  }

  /// `单点登录`
  String get groupSso {
    return Intl.message('单点登录', name: 'groupSso', desc: '', args: []);
  }

  /// `LDAP`
  String get groupLdap {
    return Intl.message('LDAP', name: 'groupLdap', desc: '', args: []);
  }

  /// `S3`
  String get groupS3 {
    return Intl.message('S3', name: 'groupS3', desc: '', args: []);
  }

  /// `FTP`
  String get groupFtp {
    return Intl.message('FTP', name: 'groupFtp', desc: '', args: []);
  }

  /// `流量`
  String get groupTraffic {
    return Intl.message('流量', name: 'groupTraffic', desc: '', args: []);
  }

  /// `媒体`
  String get groupMedia {
    return Intl.message('媒体', name: 'groupMedia', desc: '', args: []);
  }

  /// `转码`
  String get groupTranscode {
    return Intl.message('转码', name: 'groupTranscode', desc: '', args: []);
  }

  /// `没有修改`
  String get noChanges {
    return Intl.message('没有修改', name: 'noChanges', desc: '', args: []);
  }

  /// `上传`
  String get uploads {
    return Intl.message('上传', name: 'uploads', desc: '', args: []);
  }

  /// `排队中`
  String get uploadQueued {
    return Intl.message('排队中', name: 'uploadQueued', desc: '', args: []);
  }

  /// `上传中`
  String get uploadRunning {
    return Intl.message('上传中', name: 'uploadRunning', desc: '', args: []);
  }

  /// `已完成`
  String get uploadSucceeded {
    return Intl.message('已完成', name: 'uploadSucceeded', desc: '', args: []);
  }

  /// `失败`
  String get uploadFailedState {
    return Intl.message('失败', name: 'uploadFailedState', desc: '', args: []);
  }

  /// `已取消`
  String get uploadCanceled {
    return Intl.message('已取消', name: 'uploadCanceled', desc: '', args: []);
  }

  /// `没有上传`
  String get noUploads {
    return Intl.message('没有上传', name: 'noUploads', desc: '', args: []);
  }

  /// `上传会在应用进程存活期间继续；从最近任务中划掉应用会中止上传。`
  String get uploadsKeepAppAlive {
    return Intl.message(
      '上传会在应用进程存活期间继续；从最近任务中划掉应用会中止上传。',
      name: 'uploadsKeepAppAlive',
      desc: '',
      args: [],
    );
  }

  /// `HTTPS 证书`
  String get tlsCertificate {
    return Intl.message('HTTPS 证书', name: 'tlsCertificate', desc: '', args: []);
  }

  /// `证书（PEM）`
  String get certFile {
    return Intl.message('证书（PEM）', name: 'certFile', desc: '', args: []);
  }

  /// `私钥（PEM）`
  String get keyFile {
    return Intl.message('私钥（PEM）', name: 'keyFile', desc: '', args: []);
  }

  /// `HTTPS 端口`
  String get httpsPort {
    return Intl.message('HTTPS 端口', name: 'httpsPort', desc: '', args: []);
  }

  /// `强制 HTTPS`
  String get forceHttps {
    return Intl.message('强制 HTTPS', name: 'forceHttps', desc: '', args: []);
  }

  /// `选择文件`
  String get chooseFile {
    return Intl.message('选择文件', name: 'chooseFile', desc: '', args: []);
  }

  /// `未配置`
  String get notConfigured {
    return Intl.message('未配置', name: 'notConfigured', desc: '', args: []);
  }

  /// `该文件不是 PEM 格式的证书或私钥`
  String get invalidPem {
    return Intl.message(
      '该文件不是 PEM 格式的证书或私钥',
      name: 'invalidPem',
      desc: '',
      args: [],
    );
  }

  /// `请输入 1 到 65535 的端口，或 -1 表示禁用`
  String get invalidPort {
    return Intl.message(
      '请输入 1 到 65535 的端口，或 -1 表示禁用',
      name: 'invalidPort',
      desc: '',
      args: [],
    );
  }

  /// `启用 HTTPS 需要同时提供证书和私钥`
  String get tlsNeedsCert {
    return Intl.message(
      '启用 HTTPS 需要同时提供证书和私钥',
      name: 'tlsNeedsCert',
      desc: '',
      args: [],
    );
  }

  /// `该驱动不支持上传`
  String get driverNoUpload {
    return Intl.message('该驱动不支持上传', name: 'driverNoUpload', desc: '', args: []);
  }

  /// `{count} 个上传进行中`
  String uploadsActive(int count) {
    return Intl.message(
      '$count 个上传进行中',
      name: 'uploadsActive',
      desc: '',
      args: [count],
    );
  }

  /// `删除用户 {name}？`
  String confirmDeleteUser(String name) {
    return Intl.message(
      '删除用户 $name？',
      name: 'confirmDeleteUser',
      desc: '',
      args: [name],
    );
  }

  /// `设置管理员密码`
  String get adminPasswordSetupTitle {
    return Intl.message(
      '设置管理员密码',
      name: 'adminPasswordSetupTitle',
      desc: '',
      args: [],
    );
  }

  /// `本地核心已为 admin 账户生成随机密码。请设置你自己的密码，以便通过网页端或其他设备登录。`
  String get adminPasswordSetupMessage {
    return Intl.message(
      '本地核心已为 admin 账户生成随机密码。请设置你自己的密码，以便通过网页端或其他设备登录。',
      name: 'adminPasswordSetupMessage',
      desc: '',
      args: [],
    );
  }

  /// `admin 密码`
  String get adminPasswordHint {
    return Intl.message(
      'admin 密码',
      name: 'adminPasswordHint',
      desc: '',
      args: [],
    );
  }

  /// `admin 密码已更新`
  String get adminPasswordUpdated {
    return Intl.message(
      'admin 密码已更新',
      name: 'adminPasswordUpdated',
      desc: '',
      args: [],
    );
  }

  /// `稍后`
  String get later {
    return Intl.message('稍后', name: 'later', desc: '', args: []);
  }

  /// `主页`
  String get home {
    return Intl.message('主页', name: 'home', desc: '', args: []);
  }

  /// `快速访问`
  String get quickAccess {
    return Intl.message('快速访问', name: 'quickAccess', desc: '', args: []);
  }

  /// `最近文件`
  String get recentFiles {
    return Intl.message('最近文件', name: 'recentFiles', desc: '', args: []);
  }

  /// `收藏`
  String get favorites {
    return Intl.message('收藏', name: 'favorites', desc: '', args: []);
  }

  /// `照片`
  String get photos {
    return Intl.message('照片', name: 'photos', desc: '', args: []);
  }

  /// `视频`
  String get videos {
    return Intl.message('视频', name: 'videos', desc: '', args: []);
  }

  /// `我的存储`
  String get myStorages {
    return Intl.message('我的存储', name: 'myStorages', desc: '', args: []);
  }

  /// `未配置存储`
  String get noStoragesConfigured {
    return Intl.message(
      '未配置存储',
      name: 'noStoragesConfigured',
      desc: '',
      args: [],
    );
  }

  /// `添加存储以开始使用 OpenList`
  String get noStoragesDesc {
    return Intl.message(
      '添加存储以开始使用 OpenList',
      name: 'noStoragesDesc',
      desc: '',
      args: [],
    );
  }

  /// `查看全部`
  String get seeAll {
    return Intl.message('查看全部', name: 'seeAll', desc: '', args: []);
  }

  /// `账户`
  String get account {
    return Intl.message('账户', name: 'account', desc: '', args: []);
  }

  /// `管理员`
  String get administrator {
    return Intl.message('管理员', name: 'administrator', desc: '', args: []);
  }

  /// `用户`
  String get user {
    return Intl.message('用户', name: 'user', desc: '', args: []);
  }

  /// `退出登录`
  String get signOut {
    return Intl.message('退出登录', name: 'signOut', desc: '', args: []);
  }

  /// `退出登录`
  String get signOutConfirmTitle {
    return Intl.message(
      '退出登录',
      name: 'signOutConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `确定要退出登录吗？`
  String get signOutConfirmMessage {
    return Intl.message(
      '确定要退出登录吗？',
      name: 'signOutConfirmMessage',
      desc: '',
      args: [],
    );
  }

  /// `服务器`
  String get server {
    return Intl.message('服务器', name: 'server', desc: '', args: []);
  }

  /// `服务器详情`
  String get serverDetails {
    return Intl.message('服务器详情', name: 'serverDetails', desc: '', args: []);
  }

  /// `查看运行信息和连接详情`
  String get serverDetailsDesc {
    return Intl.message(
      '查看运行信息和连接详情',
      name: 'serverDetailsDesc',
      desc: '',
      args: [],
    );
  }

  /// `存储`
  String get storage {
    return Intl.message('存储', name: 'storage', desc: '', args: []);
  }

  /// `管理存储`
  String get manageStorages {
    return Intl.message('管理存储', name: 'manageStorages', desc: '', args: []);
  }

  /// `添加、编辑或删除存储位置`
  String get manageStoragesDesc {
    return Intl.message(
      '添加、编辑或删除存储位置',
      name: 'manageStoragesDesc',
      desc: '',
      args: [],
    );
  }

  /// `外观`
  String get appearance {
    return Intl.message('外观', name: 'appearance', desc: '', args: []);
  }

  /// `主题`
  String get theme {
    return Intl.message('主题', name: 'theme', desc: '', args: []);
  }

  /// `跟随系统`
  String get themeSystem {
    return Intl.message('跟随系统', name: 'themeSystem', desc: '', args: []);
  }

  /// `浅色`
  String get themeLight {
    return Intl.message('浅色', name: 'themeLight', desc: '', args: []);
  }

  /// `深色`
  String get themeDark {
    return Intl.message('深色', name: 'themeDark', desc: '', args: []);
  }

  /// `管理`
  String get administration {
    return Intl.message('管理', name: 'administration', desc: '', args: []);
  }

  /// `用户管理`
  String get userManagement {
    return Intl.message('用户管理', name: 'userManagement', desc: '', args: []);
  }

  /// `管理用户和权限`
  String get userManagementDesc {
    return Intl.message(
      '管理用户和权限',
      name: 'userManagementDesc',
      desc: '',
      args: [],
    );
  }

  /// `存储管理`
  String get storageManagement {
    return Intl.message('存储管理', name: 'storageManagement', desc: '', args: []);
  }

  /// `配置存储后端`
  String get storageManagementDesc {
    return Intl.message(
      '配置存储后端',
      name: 'storageManagementDesc',
      desc: '',
      args: [],
    );
  }

  /// `TLS 证书`
  String get tlsCertificates {
    return Intl.message('TLS 证书', name: 'tlsCertificates', desc: '', args: []);
  }

  /// `管理 SSL/TLS 证书`
  String get tlsCertificatesDesc {
    return Intl.message(
      '管理 SSL/TLS 证书',
      name: 'tlsCertificatesDesc',
      desc: '',
      args: [],
    );
  }

  /// `更改管理员密码`
  String get changeAdminPassword {
    return Intl.message(
      '更改管理员密码',
      name: 'changeAdminPassword',
      desc: '',
      args: [],
    );
  }

  /// `更新服务器管理员密码`
  String get changeAdminPasswordDesc {
    return Intl.message(
      '更新服务器管理员密码',
      name: 'changeAdminPasswordDesc',
      desc: '',
      args: [],
    );
  }

  /// `缓存`
  String get cache {
    return Intl.message('缓存', name: 'cache', desc: '', args: []);
  }

  /// `清除缓存`
  String get clearCache {
    return Intl.message('清除缓存', name: 'clearCache', desc: '', args: []);
  }

  /// `释放存储空间`
  String get clearCacheDesc {
    return Intl.message('释放存储空间', name: 'clearCacheDesc', desc: '', args: []);
  }

  /// `关于 OpenList`
  String get aboutOpenList {
    return Intl.message(
      '关于 OpenList',
      name: 'aboutOpenList',
      desc: '',
      args: [],
    );
  }

  /// `版本`
  String get version {
    return Intl.message('版本', name: 'version', desc: '', args: []);
  }

  /// `GitHub 仓库`
  String get githubRepo {
    return Intl.message('GitHub 仓库', name: 'githubRepo', desc: '', args: []);
  }

  /// `停止服务器`
  String get stopServerTitle {
    return Intl.message('停止服务器', name: 'stopServerTitle', desc: '', args: []);
  }

  /// `确定要停止服务器吗？`
  String get stopServerMessage {
    return Intl.message(
      '确定要停止服务器吗？',
      name: 'stopServerMessage',
      desc: '',
      args: [],
    );
  }

  /// `模式已更改。重启服务器以应用。`
  String get modeChangedRestart {
    return Intl.message(
      '模式已更改。重启服务器以应用。',
      name: 'modeChangedRestart',
      desc: '',
      args: [],
    );
  }

  /// `更改模式失败：{error}`
  String modeChangeFailed(String error) {
    return Intl.message(
      '更改模式失败：$error',
      name: 'modeChangeFailed',
      desc: '',
      args: [error],
    );
  }

  /// `网络模式`
  String get networkMode {
    return Intl.message('网络模式', name: 'networkMode', desc: '', args: []);
  }

  /// `选择网络模式`
  String get selectNetworkMode {
    return Intl.message(
      '选择网络模式',
      name: 'selectNetworkMode',
      desc: '',
      args: [],
    );
  }

  /// `删除存储`
  String get deleteStorageTitle {
    return Intl.message('删除存储', name: 'deleteStorageTitle', desc: '', args: []);
  }

  /// `删除存储 "{name}"？`
  String deleteStorageMessage(String name) {
    return Intl.message(
      '删除存储 "$name"？',
      name: 'deleteStorageMessage',
      desc: '',
      args: [name],
    );
  }

  /// `加载中...`
  String get loadingStorages {
    return Intl.message('加载中...', name: 'loadingStorages', desc: '', args: []);
  }

  /// `加载存储失败`
  String get loadStoragesFailed {
    return Intl.message(
      '加载存储失败',
      name: 'loadStoragesFailed',
      desc: '',
      args: [],
    );
  }

  /// `没有存储`
  String get noStorages {
    return Intl.message('没有存储', name: 'noStorages', desc: '', args: []);
  }

  /// `存储操作`
  String get storageActions {
    return Intl.message('存储操作', name: 'storageActions', desc: '', args: []);
  }

  /// `浏览文件`
  String get browseFiles {
    return Intl.message('浏览文件', name: 'browseFiles', desc: '', args: []);
  }

  /// `启用存储`
  String get enableStorage {
    return Intl.message('启用存储', name: 'enableStorage', desc: '', args: []);
  }

  /// `禁用存储`
  String get disableStorage {
    return Intl.message('禁用存储', name: 'disableStorage', desc: '', args: []);
  }

  /// `删除存储`
  String get deleteStorage {
    return Intl.message('删除存储', name: 'deleteStorage', desc: '', args: []);
  }

  /// `备注`
  String get remark {
    return Intl.message('备注', name: 'remark', desc: '', args: []);
  }

  /// `系统默认`
  String get systemDefault {
    return Intl.message('系统默认', name: 'systemDefault', desc: '', args: []);
  }

  /// `文件`
  String get files {
    return Intl.message('文件', name: 'files', desc: '', args: []);
  }

  /// `排序`
  String get sort {
    return Intl.message('排序', name: 'sort', desc: '', args: []);
  }

  /// `新建文件`
  String get newFile {
    return Intl.message('新建文件', name: 'newFile', desc: '', args: []);
  }

  /// `输入文件夹名称`
  String get enterFolderName {
    return Intl.message('输入文件夹名称', name: 'enterFolderName', desc: '', args: []);
  }

  /// `输入文件名称`
  String get enterFileName {
    return Intl.message('输入文件名称', name: 'enterFileName', desc: '', args: []);
  }

  /// `创建`
  String get create {
    return Intl.message('创建', name: 'create', desc: '', args: []);
  }

  /// `上传图片`
  String get uploadPhotos {
    return Intl.message('上传图片', name: 'uploadPhotos', desc: '', args: []);
  }

  /// `上传视频`
  String get uploadVideos {
    return Intl.message('上传视频', name: 'uploadVideos', desc: '', args: []);
  }

  /// `上传文件`
  String get uploadFiles {
    return Intl.message('上传文件', name: 'uploadFiles', desc: '', args: []);
  }

  /// `连接到服务器`
  String get connectToServer {
    return Intl.message('连接到服务器', name: 'connectToServer', desc: '', args: []);
  }

  /// `删除文件`
  String get deleteFiles {
    return Intl.message('删除文件', name: 'deleteFiles', desc: '', args: []);
  }

  /// `删除 {count} 个项目？`
  String deleteItemsConfirm(int count) {
    return Intl.message(
      '删除 $count 个项目？',
      name: 'deleteItemsConfirm',
      desc: '',
      args: [count],
    );
  }

  /// `未连接`
  String get notConnected {
    return Intl.message('未连接', name: 'notConnected', desc: '', args: []);
  }

  /// `无法加载文件`
  String get failedToLoadFiles {
    return Intl.message(
      '无法加载文件',
      name: 'failedToLoadFiles',
      desc: '',
      args: [],
    );
  }

  /// `这里没有文件`
  String get noFilesHere {
    return Intl.message('这里没有文件', name: 'noFilesHere', desc: '', args: []);
  }

  /// `上传文件或创建新文件夹`
  String get uploadFilesOrCreateFolder {
    return Intl.message(
      '上传文件或创建新文件夹',
      name: 'uploadFilesOrCreateFolder',
      desc: '',
      args: [],
    );
  }

  /// `已选择`
  String get selected {
    return Intl.message('已选择', name: 'selected', desc: '', args: []);
  }

  /// `{count} 已选择`
  String selectedCount(int count) {
    return Intl.message(
      '$count 已选择',
      name: 'selectedCount',
      desc: '',
      args: [count],
    );
  }

  /// `移动`
  String get move {
    return Intl.message('移动', name: 'move', desc: '', args: []);
  }

  /// `复制`
  String get copy {
    return Intl.message('复制', name: 'copy', desc: '', args: []);
  }

  /// `名称`
  String get sortByName {
    return Intl.message('名称', name: 'sortByName', desc: '', args: []);
  }

  /// `修改日期`
  String get sortByDate {
    return Intl.message('修改日期', name: 'sortByDate', desc: '', args: []);
  }

  /// `大小`
  String get sortBySize {
    return Intl.message('大小', name: 'sortBySize', desc: '', args: []);
  }

  /// `类型`
  String get sortByType {
    return Intl.message('类型', name: 'sortByType', desc: '', args: []);
  }

  /// `错误`
  String get error {
    return Intl.message('错误', name: 'error', desc: '', args: []);
  }

  /// `创建文件夹失败：{error}`
  String failedToCreateFolder(String error) {
    return Intl.message(
      '创建文件夹失败：$error',
      name: 'failedToCreateFolder',
      desc: '',
      args: [error],
    );
  }

  /// `上传功能即将推出`
  String get uploadFunctionalityComingSoon {
    return Intl.message(
      '上传功能即将推出',
      name: 'uploadFunctionalityComingSoon',
      desc: '',
      args: [],
    );
  }

  /// `删除失败：{error}`
  String failedToDelete(String error) {
    return Intl.message(
      '删除失败：$error',
      name: 'failedToDelete',
      desc: '',
      args: [error],
    );
  }

  /// `移动功能即将推出`
  String get moveFunctionalityComingSoon {
    return Intl.message(
      '移动功能即将推出',
      name: 'moveFunctionalityComingSoon',
      desc: '',
      args: [],
    );
  }

  /// `复制功能即将推出`
  String get copyFunctionalityComingSoon {
    return Intl.message(
      '复制功能即将推出',
      name: 'copyFunctionalityComingSoon',
      desc: '',
      args: [],
    );
  }

  /// `成功`
  String get success {
    return Intl.message('成功', name: 'success', desc: '', args: []);
  }

  /// `已连接到服务器`
  String get connectedToServer {
    return Intl.message(
      '已连接到服务器',
      name: 'connectedToServer',
      desc: '',
      args: [],
    );
  }

  /// `无法连接到服务器`
  String get failedToConnectToServer {
    return Intl.message(
      '无法连接到服务器',
      name: 'failedToConnectToServer',
      desc: '',
      args: [],
    );
  }

  /// `信息`
  String get info {
    return Intl.message('信息', name: 'info', desc: '', args: []);
  }

  /// `移动中...`
  String get moving {
    return Intl.message('移动中...', name: 'moving', desc: '', args: []);
  }

  /// `复制中...`
  String get copying {
    return Intl.message('复制中...', name: 'copying', desc: '', args: []);
  }

  /// `移动失败: {error}`
  String failedToMove(String error) {
    return Intl.message(
      '移动失败: $error',
      name: 'failedToMove',
      desc: '',
      args: [error],
    );
  }

  /// `复制失败: {error}`
  String failedToCopy(String error) {
    return Intl.message(
      '复制失败: $error',
      name: 'failedToCopy',
      desc: '',
      args: [error],
    );
  }

  /// `传输`
  String get transfers {
    return Intl.message('传输', name: 'transfers', desc: '', args: []);
  }

  /// `下载`
  String get downloads {
    return Intl.message('下载', name: 'downloads', desc: '', args: []);
  }

  /// `重试失败`
  String get retryFailed {
    return Intl.message('重试失败', name: 'retryFailed', desc: '', args: []);
  }

  /// `清除已完成`
  String get clearCompleted {
    return Intl.message('清除已完成', name: 'clearCompleted', desc: '', args: []);
  }

  /// `暂停单个传输`
  String get pauseIndividualTransfers {
    return Intl.message(
      '暂停单个传输',
      name: 'pauseIndividualTransfers',
      desc: '',
      args: [],
    );
  }

  /// `从文件界面上传文件`
  String get uploadFilesFromFilesScreen {
    return Intl.message(
      '从文件界面上传文件',
      name: 'uploadFilesFromFilesScreen',
      desc: '',
      args: [],
    );
  }

  /// `没有下载`
  String get noDownloads {
    return Intl.message('没有下载', name: 'noDownloads', desc: '', args: []);
  }

  /// `下载的文件将显示在这里`
  String get downloadedFilesWillAppearHere {
    return Intl.message(
      '下载的文件将显示在这里',
      name: 'downloadedFilesWillAppearHere',
      desc: '',
      args: [],
    );
  }

  /// `等待中`
  String get waiting {
    return Intl.message('等待中', name: 'waiting', desc: '', args: []);
  }

  /// `上传中`
  String get uploading {
    return Intl.message('上传中', name: 'uploading', desc: '', args: []);
  }

  /// `已取消`
  String get canceled {
    return Intl.message('已取消', name: 'canceled', desc: '', args: []);
  }

  /// `移除`
  String get remove {
    return Intl.message('移除', name: 'remove', desc: '', args: []);
  }

  /// `状态`
  String get status {
    return Intl.message('状态', name: 'status', desc: '', args: []);
  }

  /// `服务器运行中`
  String get serverRunning {
    return Intl.message('服务器运行中', name: 'serverRunning', desc: '', args: []);
  }

  /// `服务器已停止`
  String get serverStopped {
    return Intl.message('服务器已停止', name: 'serverStopped', desc: '', args: []);
  }

  /// `所有系统正常运行`
  String get allSystemsOperational {
    return Intl.message(
      '所有系统正常运行',
      name: 'allSystemsOperational',
      desc: '',
      args: [],
    );
  }

  /// `启动服务器以接受连接`
  String get startServerToAcceptConnections {
    return Intl.message(
      '启动服务器以接受连接',
      name: 'startServerToAcceptConnections',
      desc: '',
      args: [],
    );
  }

  /// `连接 URL`
  String get connectionUrls {
    return Intl.message('连接 URL', name: 'connectionUrls', desc: '', args: []);
  }

  /// `运行时统计`
  String get runtimeStatistics {
    return Intl.message('运行时统计', name: 'runtimeStatistics', desc: '', args: []);
  }

  /// `配置`
  String get configuration {
    return Intl.message('配置', name: 'configuration', desc: '', args: []);
  }

  /// `HTTP 端口`
  String get httpPort {
    return Intl.message('HTTP 端口', name: 'httpPort', desc: '', args: []);
  }

  /// `模式`
  String get mode {
    return Intl.message('模式', name: 'mode', desc: '', args: []);
  }

  /// `存储已删除`
  String get storageDeleted {
    return Intl.message('存储已删除', name: 'storageDeleted', desc: '', args: []);
  }

  /// `删除存储失败：{error}`
  String failedToDeleteStorage(String error) {
    return Intl.message(
      '删除存储失败：$error',
      name: 'failedToDeleteStorage',
      desc: '',
      args: [error],
    );
  }

  /// `存储已{action}`
  String storageToggled(String action) {
    return Intl.message(
      '存储已$action',
      name: 'storageToggled',
      desc: '',
      args: [action],
    );
  }

  /// `启用`
  String get enabled {
    return Intl.message('启用', name: 'enabled', desc: '', args: []);
  }

  /// `禁用`
  String get disabled {
    return Intl.message('禁用', name: 'disabled', desc: '', args: []);
  }

  /// `切换存储状态失败：{error}`
  String failedToToggleStorage(String error) {
    return Intl.message(
      '切换存储状态失败：$error',
      name: 'failedToToggleStorage',
      desc: '',
      args: [error],
    );
  }

  /// `浏览功能即将推出`
  String get browseFunctionalityComingSoon {
    return Intl.message(
      '浏览功能即将推出',
      name: 'browseFunctionalityComingSoon',
      desc: '',
      args: [],
    );
  }

  /// `缓存已清除`
  String get cacheCleared {
    return Intl.message('缓存已清除', name: 'cacheCleared', desc: '', args: []);
  }

  /// `无法打开 URL`
  String get couldNotOpenUrl {
    return Intl.message(
      '无法打开 URL',
      name: 'couldNotOpenUrl',
      desc: '',
      args: [],
    );
  }

  /// `批量重命名`
  String get batchRename {
    return Intl.message('批量重命名', name: 'batchRename', desc: '', args: []);
  }

  /// `重命名选中的 {count} 个项目`
  String batchRenameDesc(int count) {
    return Intl.message(
      '重命名选中的 $count 个项目',
      name: 'batchRenameDesc',
      desc: '',
      args: [count],
    );
  }

  /// `正则表达式`
  String get regexRename {
    return Intl.message('正则表达式', name: 'regexRename', desc: '', args: []);
  }

  /// `顺序编号`
  String get sequentialRename {
    return Intl.message('顺序编号', name: 'sequentialRename', desc: '', args: []);
  }

  /// `查找替换`
  String get findReplace {
    return Intl.message('查找替换', name: 'findReplace', desc: '', args: []);
  }

  /// `匹配规则（正则表达式）`
  String get renamePattern {
    return Intl.message(
      '匹配规则（正则表达式）',
      name: 'renamePattern',
      desc: '',
      args: [],
    );
  }

  /// `查找文本`
  String get renameSearchText {
    return Intl.message('查找文本', name: 'renameSearchText', desc: '', args: []);
  }

  /// `替换为`
  String get renameReplacement {
    return Intl.message('替换为', name: 'renameReplacement', desc: '', args: []);
  }

  /// `起始编号`
  String get renameStartNumber {
    return Intl.message('起始编号', name: 'renameStartNumber', desc: '', args: []);
  }

  /// `补零位数`
  String get renamePaddingZeros {
    return Intl.message('补零位数', name: 'renamePaddingZeros', desc: '', args: []);
  }

  /// `没有匹配的项目`
  String get renameNoMatch {
    return Intl.message('没有匹配的项目', name: 'renameNoMatch', desc: '', args: []);
  }

  /// `输入不能为空`
  String get emptyInput {
    return Intl.message('输入不能为空', name: 'emptyInput', desc: '', args: []);
  }

  /// `名称包含非法字符`
  String get invalidFilenameChars {
    return Intl.message(
      '名称包含非法字符',
      name: 'invalidFilenameChars',
      desc: '',
      args: [],
    );
  }

  /// `不是有效的正则表达式`
  String get invalidRegex {
    return Intl.message('不是有效的正则表达式', name: 'invalidRegex', desc: '', args: []);
  }

  /// `返回`
  String get back {
    return Intl.message('返回', name: 'back', desc: '', args: []);
  }

  /// `该设备不支持播放此媒体`
  String get mediaPlaybackUnavailable {
    return Intl.message(
      '该设备不支持播放此媒体',
      name: 'mediaPlaybackUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `播放已中断，请检查文件格式或网络连接。`
  String get mediaPlaybackInterrupted {
    return Intl.message(
      '播放已中断，请检查文件格式或网络连接。',
      name: 'mediaPlaybackInterrupted',
      desc: '',
      args: [],
    );
  }

  /// `播放`
  String get play {
    return Intl.message('播放', name: 'play', desc: '', args: []);
  }

  /// `暂停`
  String get pause {
    return Intl.message('暂停', name: 'pause', desc: '', args: []);
  }

  /// `继续`
  String get resume {
    return Intl.message('继续', name: 'resume', desc: '', args: []);
  }

  /// `已暂停`
  String get paused {
    return Intl.message('已暂停', name: 'paused', desc: '', args: []);
  }

  /// `正在取消`
  String get cancelling {
    return Intl.message('正在取消', name: 'cancelling', desc: '', args: []);
  }

  /// `全屏`
  String get fullscreen {
    return Intl.message('全屏', name: 'fullscreen', desc: '', args: []);
  }

  /// `无法获取压缩包文件地址`
  String get archiveExtractionUnavailable {
    return Intl.message(
      '无法获取压缩包文件地址',
      name: 'archiveExtractionUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `暂无最近文件`
  String get noRecentFiles {
    return Intl.message('暂无最近文件', name: 'noRecentFiles', desc: '', args: []);
  }

  /// `媒体库未启用`
  String get mediaLibraryUnavailable {
    return Intl.message(
      '媒体库未启用',
      name: 'mediaLibraryUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `暂无媒体内容`
  String get noMediaItems {
    return Intl.message('暂无媒体内容', name: 'noMediaItems', desc: '', args: []);
  }

  /// `已添加到收藏`
  String get mediaFavoriteAdded {
    return Intl.message(
      '已添加到收藏',
      name: 'mediaFavoriteAdded',
      desc: '',
      args: [],
    );
  }

  /// `添加到收藏`
  String get addMediaFavorite {
    return Intl.message('添加到收藏', name: 'addMediaFavorite', desc: '', args: []);
  }

  /// `取消收藏`
  String get removeMediaFavorite {
    return Intl.message(
      '取消收藏',
      name: 'removeMediaFavorite',
      desc: '',
      args: [],
    );
  }

  /// `核心设置`
  String get coreSettings {
    return Intl.message('核心设置', name: 'coreSettings', desc: '', args: []);
  }

  /// `无需网页界面即可配置 OpenList Core`
  String get coreSettingsDesc {
    return Intl.message(
      '无需网页界面即可配置 OpenList Core',
      name: 'coreSettingsDesc',
      desc: '',
      args: [],
    );
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
