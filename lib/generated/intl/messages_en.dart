// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
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
  String get localeName => 'en';

  static String m0(error) => "Failed to cancel all notifications: ${error}";

  static String m1(error) => "Failed to cancel download notification: ${error}";

  static String m2(error) => "Failed to check install permission: ${error}";

  static String m3(error) => "Failed to clear download directory: ${error}";

  static String m4(filename) =>
      "Are you sure you want to cancel downloading \"${filename}\"?";

  static String m5(filename) =>
      "Are you sure you want to delete file \"${filename}\"? This action cannot be undone.";

  static String m6(filename) =>
      "Are you sure you want to delete the download record of \"${filename}\"?";

  static String m7(error) => "Failed to create OpenList directory: ${error}";

  static String m8(path) => "Create OpenList download directory: ${path}";

  static String m9(count) => "Currently ${count} files are downloading";

  static String m10(error) => "Failed to delete file: ${error}";

  static String m11(url) => "Download cancelled: ${url}";

  static String m12(filename) => "Download complete: ${filename}";

  static String m13(filename) => "Download complete: ${filename}";

  static String m14(filename) => "${filename} download completed";

  static String m15(filename) => "Download failed: ${filename}";

  static String m16(filename) => "Download failed: ${filename}";

  static String m17(count) => "Download (${count})";

  static String m18(progress) => "Download progress: ${progress}%";

  static String m19(filename) => "File deleted: ${filename}";

  static String m20(size) => "Size: ${size}";

  static String m21(time) => "Time: ${time}";

  static String m22(error) => "Failed to get download directory: ${error}";

  static String m23(error) => "Failed to get download file list: ${error}";

  static String m24(count) =>
      "${count} files completed, click to jump to download manager";

  static String m25(payload) => "Notification clicked: ${payload}";

  static String m26(error) =>
      "Failed to initialize notification manager: ${error}";

  static String m27(error) => "Failed to open download directory: ${error}";

  static String m28(error) => "Open file exception: ${error}";

  static String m29(error) => "Failed to open file: ${error}";

  static String m30(error) => "Failed to open file manager: ${error}";

  static String m31(type, message) => "Open file result: ${type} - ${message}";

  static String m32(path) => "OpenList download directory: ${path}";

  static String m33(error) => "Failed to parse filename: ${error}";

  static String m34(error) =>
      "Failed to show download complete notification: ${error}";

  static String m35(error) =>
      "Failed to show download progress notification: ${error}";

  static String m36(error) =>
      "Failed to show single file complete notification: ${error}";

  static String m37(filename) => "Start download: ${filename}";

  static String m38(filename) => "Start download: ${filename}";

  static String m39(path) => "Trying to open file: ${path}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("About"),
    "appName": MessageLookupByLibrary.simpleMessage("OpenList"),
    "autoCheckForUpdates": MessageLookupByLibrary.simpleMessage(
      "Auto check for updates",
    ),
    "autoCheckForUpdatesDesc": MessageLookupByLibrary.simpleMessage(
      "Check for updates when app starts",
    ),
    "autoStartWebPage": MessageLookupByLibrary.simpleMessage(
      "Set web page as startup page",
    ),
    "autoStartWebPageDesc": MessageLookupByLibrary.simpleMessage(
      "Default page when opening main interface",
    ),
    "bootAutoStartService": MessageLookupByLibrary.simpleMessage(
      "Boot auto-start service",
    ),
    "bootAutoStartServiceDesc": MessageLookupByLibrary.simpleMessage(
      "Automatically start OpenList service after boot. (Please make sure to grant auto-start permission)",
    ),
    "browserDownload": MessageLookupByLibrary.simpleMessage("Browser Download"),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "cancelAllNotificationsFailed": m0,
    "cancelDownload": MessageLookupByLibrary.simpleMessage("Cancel Download"),
    "cancelDownloadNotificationFailed": m1,
    "cancelled": MessageLookupByLibrary.simpleMessage("Cancelled"),
    "cannotGetBaseDownloadDirectory": MessageLookupByLibrary.simpleMessage(
      "Cannot get base download directory",
    ),
    "cannotGetDownloadDirectory": MessageLookupByLibrary.simpleMessage(
      "Cannot get download directory",
    ),
    "cannotGetDownloadDirectoryError": MessageLookupByLibrary.simpleMessage(
      "Cannot get download directory",
    ),
    "cannotInstallApkFile": MessageLookupByLibrary.simpleMessage(
      "Cannot install APK file, you may need to enable \\\"Install unknown apps\\\" in settings",
    ),
    "cannotInstallApkNeedPermission": MessageLookupByLibrary.simpleMessage(
      "Cannot install APK file, you may need to enable \\\"Install unknown apps\\\" in settings",
    ),
    "checkForUpdates": MessageLookupByLibrary.simpleMessage(
      "Check for updates",
    ),
    "checkInstallPermissionFailed": m2,
    "clear": MessageLookupByLibrary.simpleMessage("Clear"),
    "clearAll": MessageLookupByLibrary.simpleMessage("Clear All"),
    "clearDownloadDirectoryFailed": m3,
    "clearFailed": MessageLookupByLibrary.simpleMessage("Clear failed"),
    "clearRecords": MessageLookupByLibrary.simpleMessage("Clear Records"),
    "cleared": MessageLookupByLibrary.simpleMessage(
      "Download directory cleared",
    ),
    "clickToJumpToDownloadManager": MessageLookupByLibrary.simpleMessage(
      "Click to jump to download manager",
    ),
    "completed": MessageLookupByLibrary.simpleMessage("Completed"),
    "completedTime": MessageLookupByLibrary.simpleMessage("Completed time"),
    "confirm": MessageLookupByLibrary.simpleMessage("OK"),
    "confirmCancelDownload": m4,
    "confirmClear": MessageLookupByLibrary.simpleMessage("Confirm Clear"),
    "confirmClearAllFiles": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to clear all download files? This action cannot be undone.",
    ),
    "confirmDelete": MessageLookupByLibrary.simpleMessage("Confirm Delete"),
    "confirmDeleteFile": m5,
    "confirmDeleteRecord": m6,
    "continueDownload": MessageLookupByLibrary.simpleMessage(
      "Continue Download",
    ),
    "copiedToClipboard": MessageLookupByLibrary.simpleMessage(
      "Copied to clipboard",
    ),
    "createOpenListDirectoryFailed": m7,
    "createOpenListDownloadDirectory": m8,
    "currentDownloadingFiles": m9,
    "currentIsLatestVersion": MessageLookupByLibrary.simpleMessage(
      "Current is latest version",
    ),
    "dataDirectory": MessageLookupByLibrary.simpleMessage("data Directory"),
    "delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "deleteFailed": MessageLookupByLibrary.simpleMessage("Delete failed"),
    "deleteFile": MessageLookupByLibrary.simpleMessage("Delete file"),
    "deleteFileFailedLog": m10,
    "deleteRecord": MessageLookupByLibrary.simpleMessage("Delete record"),
    "desktopShortcut": MessageLookupByLibrary.simpleMessage("Desktop shortcut"),
    "directDownload": MessageLookupByLibrary.simpleMessage("Direct Download"),
    "directDownloadApk": MessageLookupByLibrary.simpleMessage(
      "Direct Download APK",
    ),
    "download": MessageLookupByLibrary.simpleMessage("download"),
    "downloadApk": MessageLookupByLibrary.simpleMessage("Download APK"),
    "downloadCancelled": m11,
    "downloadCancelledStatus": MessageLookupByLibrary.simpleMessage(
      "Download cancelled",
    ),
    "downloadCancelledText": MessageLookupByLibrary.simpleMessage(
      "Download cancelled",
    ),
    "downloadComplete": m12,
    "downloadCompleteChannel": MessageLookupByLibrary.simpleMessage(
      "Download Complete",
    ),
    "downloadCompleteChannelDesc": MessageLookupByLibrary.simpleMessage(
      "File download complete notification",
    ),
    "downloadCompleteFile": m13,
    "downloadCompleteNotificationTitle": m14,
    "downloadCompleteTitle": MessageLookupByLibrary.simpleMessage(
      "Download Complete",
    ),
    "downloadDirectory": MessageLookupByLibrary.simpleMessage(
      "Download Directory",
    ),
    "downloadDirectoryCleared": MessageLookupByLibrary.simpleMessage(
      "Download directory cleared",
    ),
    "downloadDirectoryOpened": MessageLookupByLibrary.simpleMessage(
      "Download directory opened",
    ),
    "downloadDirectoryPathUnknown": MessageLookupByLibrary.simpleMessage(
      "Download directory path unknown",
    ),
    "downloadFailed": MessageLookupByLibrary.simpleMessage("Download failed"),
    "downloadFailedFile": m15,
    "downloadFailedWithError": m16,
    "downloadManager": MessageLookupByLibrary.simpleMessage("Download"),
    "downloadManagerWithCount": m17,
    "downloadProgress": m18,
    "downloadProgressDesc": MessageLookupByLibrary.simpleMessage(
      "Show file download progress",
    ),
    "downloadRecordsCleared": MessageLookupByLibrary.simpleMessage(
      "Download records cleared",
    ),
    "downloadThisFile": MessageLookupByLibrary.simpleMessage(
      "Download this file？",
    ),
    "downloading": MessageLookupByLibrary.simpleMessage("Downloading"),
    "english": MessageLookupByLibrary.simpleMessage("English"),
    "failed": MessageLookupByLibrary.simpleMessage("Failed"),
    "fileDeleted": MessageLookupByLibrary.simpleMessage("File deleted"),
    "fileDeletedLog": m19,
    "fileInfo": MessageLookupByLibrary.simpleMessage("File info"),
    "fileLocation": MessageLookupByLibrary.simpleMessage("File Location"),
    "fileLocationTip": MessageLookupByLibrary.simpleMessage(
      "You can use a file manager to find this file, or try installing the appropriate app to open it.",
    ),
    "fileManagerOpened": MessageLookupByLibrary.simpleMessage(
      "File manager opened",
    ),
    "fileName": MessageLookupByLibrary.simpleMessage("File name"),
    "fileNotFound": MessageLookupByLibrary.simpleMessage(
      "File not found or has been deleted",
    ),
    "filePath": MessageLookupByLibrary.simpleMessage("Path"),
    "fileSavedTo": MessageLookupByLibrary.simpleMessage("File saved to:"),
    "fileSize": m20,
    "fileTime": m21,
    "followSystem": MessageLookupByLibrary.simpleMessage("Follow System"),
    "general": MessageLookupByLibrary.simpleMessage("General"),
    "getDownloadDirectoryFailed": m22,
    "getDownloadFileListFailed": m23,
    "goTo": MessageLookupByLibrary.simpleMessage("GO"),
    "goToSettings": MessageLookupByLibrary.simpleMessage("Go to Settings"),
    "grantManagerStoragePermission": MessageLookupByLibrary.simpleMessage(
      "Grant 【Manage external storage】 permission",
    ),
    "grantNotificationPermission": MessageLookupByLibrary.simpleMessage(
      "Grant 【Notification】 permission",
    ),
    "grantNotificationPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "Used for foreground service keep alive",
    ),
    "grantStoragePermission": MessageLookupByLibrary.simpleMessage(
      "Grant 【external storage】 permission",
    ),
    "grantStoragePermissionDesc": MessageLookupByLibrary.simpleMessage(
      "Mounting local storage is a must, otherwise no permission to read and write files",
    ),
    "importantSettings": MessageLookupByLibrary.simpleMessage(
      "Important settings",
    ),
    "inProgress": MessageLookupByLibrary.simpleMessage("In Progress"),
    "initializingNotificationManager": MessageLookupByLibrary.simpleMessage(
      "Initializing notification manager",
    ),
    "jumpToOtherApp": MessageLookupByLibrary.simpleMessage(
      "Jump to other app？",
    ),
    "language": MessageLookupByLibrary.simpleMessage("Language"),
    "languageSettings": MessageLookupByLibrary.simpleMessage(
      "Language Settings",
    ),
    "languageSettingsDesc": MessageLookupByLibrary.simpleMessage(
      "Select app display language",
    ),
    "loadDownloadFilesFailed": MessageLookupByLibrary.simpleMessage(
      "Failed to load download files",
    ),
    "modifiedTime": MessageLookupByLibrary.simpleMessage("Modified time"),
    "modifyAdminPassword": MessageLookupByLibrary.simpleMessage(
      "Modify Admin Password",
    ),
    "moreOptions": MessageLookupByLibrary.simpleMessage("More options"),
    "multipleFilesCompleted": m24,
    "needInstallPermission": MessageLookupByLibrary.simpleMessage(
      "Install Permission Required",
    ),
    "needInstallPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "To install APK files, install permission is required. Please enable it manually in settings.",
    ),
    "needInstallPermissionToInstallApk": MessageLookupByLibrary.simpleMessage(
      "Install permission is required to install APK files",
    ),
    "newVersionFound": MessageLookupByLibrary.simpleMessage(
      "New Version Found",
    ),
    "noActiveDownloads": MessageLookupByLibrary.simpleMessage(
      "No active downloads",
    ),
    "noAppToOpenFile": MessageLookupByLibrary.simpleMessage(
      "No app found to open this file",
    ),
    "noCompletedDownloads": MessageLookupByLibrary.simpleMessage(
      "No completed downloads",
    ),
    "noPermissionToInstallApk": MessageLookupByLibrary.simpleMessage(
      "No permission to install APK file, please enable install permission in settings",
    ),
    "noPermissionToInstallApkFile": MessageLookupByLibrary.simpleMessage(
      "No permission to install APK file, please enable install permission in settings",
    ),
    "noPermissionToOpenFile": MessageLookupByLibrary.simpleMessage(
      "No permission to open this file",
    ),
    "notificationClicked": m25,
    "notificationManagerInitFailed": m26,
    "notificationManagerInitialized": MessageLookupByLibrary.simpleMessage(
      "Notification manager initialized successfully",
    ),
    "ok": MessageLookupByLibrary.simpleMessage("OK"),
    "open": MessageLookupByLibrary.simpleMessage("Open"),
    "openDirectory": MessageLookupByLibrary.simpleMessage("Open Directory"),
    "openDownloadDirectoryFailed": m27,
    "openDownloadManager": MessageLookupByLibrary.simpleMessage(
      "Open Download Manager",
    ),
    "openFile": MessageLookupByLibrary.simpleMessage("Open file"),
    "openFileException": m28,
    "openFileFailed": m29,
    "openFileManager": MessageLookupByLibrary.simpleMessage(
      "Open File Manager",
    ),
    "openFileManagerFailed": m30,
    "openFileResult": m31,
    "openListDownloadDirectory": m32,
    "parseFilenameFailed": m33,
    "pending": MessageLookupByLibrary.simpleMessage("Pending"),
    "preparingDownload": MessageLookupByLibrary.simpleMessage(
      "Preparing download...",
    ),
    "preparingDownloadStatus": MessageLookupByLibrary.simpleMessage(
      "Preparing download...",
    ),
    "refresh": MessageLookupByLibrary.simpleMessage("Refresh"),
    "releasePage": MessageLookupByLibrary.simpleMessage("Release Page"),
    "selectAppToOpen": MessageLookupByLibrary.simpleMessage(
      "Select app to open",
    ),
    "setAdminPassword": MessageLookupByLibrary.simpleMessage(
      "Set admin password",
    ),
    "setDefaultDirectory": MessageLookupByLibrary.simpleMessage(
      "Set as default directory?",
    ),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "shareFeatureNotImplemented": MessageLookupByLibrary.simpleMessage(
      "Share feature not implemented yet",
    ),
    "shareFile": MessageLookupByLibrary.simpleMessage("Share file"),
    "showDownloadCompleteNotificationFailed": m34,
    "showDownloadProgressNotificationFailed": m35,
    "showInFileManager": MessageLookupByLibrary.simpleMessage(
      "Show in file manager",
    ),
    "showSingleFileCompleteNotificationFailed": m36,
    "silentJumpApp": MessageLookupByLibrary.simpleMessage("Silent jump app"),
    "silentJumpAppDesc": MessageLookupByLibrary.simpleMessage(
      "Jump to other app without prompt",
    ),
    "simplifiedChinese": MessageLookupByLibrary.simpleMessage("简体中文"),
    "size": MessageLookupByLibrary.simpleMessage("Size"),
    "startDownload": m37,
    "startDownloadFile": m38,
    "startTime": MessageLookupByLibrary.simpleMessage("Start time"),
    "tryToOpenFile": m39,
    "uiSettings": MessageLookupByLibrary.simpleMessage("UI"),
    "userCancelledDownload": MessageLookupByLibrary.simpleMessage(
      "User cancelled download",
    ),
    "userCancelledDownloadError": MessageLookupByLibrary.simpleMessage(
      "User cancelled download",
    ),
    "viewDownloads": MessageLookupByLibrary.simpleMessage("View Downloads"),
    "viewLocation": MessageLookupByLibrary.simpleMessage("View Location"),
    "wakeLock": MessageLookupByLibrary.simpleMessage("Wake lock"),
    "wakeLockDesc": MessageLookupByLibrary.simpleMessage(
      "Prevent CPU from sleeping when screen is off. (May cause app killed in background on some devices)",
    ),
    "webPage": MessageLookupByLibrary.simpleMessage("Web Page"),
  };
}
