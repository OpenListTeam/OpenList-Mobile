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

  static String m19(current, total) => "Downloading file ${current}/${total}";

  static String m20(filename) => "File deleted: ${filename}";

  static String m21(index) => "File ${index} download failed";

  static String m22(size) => "Size: ${size}";

  static String m23(time) => "Time: ${time}";

  static String m24(error) => "Failed to get download directory: ${error}";

  static String m25(error) => "Failed to get download file list: ${error}";

  static String m26(line, error) =>
      "Invalid JSON format at line ${line}: ${error}";

  static String m27(error) => "Load failed: ${error}";

  static String m28(count) =>
      "${count} files completed, click to jump to download manager";

  static String m29(payload) => "Notification clicked: ${payload}";

  static String m30(error) =>
      "Failed to initialize notification manager: ${error}";

  static String m31(error) => "Failed to open download directory: ${error}";

  static String m32(error) => "Open file exception: ${error}";

  static String m33(error) => "Failed to open file: ${error}";

  static String m34(error) => "Failed to open file manager: ${error}";

  static String m35(type, message) => "Open file result: ${type} - ${message}";

  static String m36(path) => "OpenList download directory: ${path}";

  static String m37(error) => "Failed to parse filename: ${error}";

  static String m38(error) => "Restore backup failed: ${error}";

  static String m39(error) => "Save failed: ${error}";

  static String m40(error) =>
      "Failed to show download complete notification: ${error}";

  static String m41(error) =>
      "Failed to show download progress notification: ${error}";

  static String m42(error) =>
      "Failed to show single file complete notification: ${error}";

  static String m43(filename) => "Start download: ${filename}";

  static String m44(filename) => "Start download: ${filename}";

  static String m45(path) => "Trying to open file: ${path}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("About"),
    "apkDownloadCompleteMessage": MessageLookupByLibrary.simpleMessage(
      "APK file download completed, do you want to install?",
    ),
    "appName": MessageLookupByLibrary.simpleMessage("OpenList"),
    "autoCheckForUpdates": MessageLookupByLibrary.simpleMessage(
      "Auto check for updates",
    ),
    "autoCheckForUpdatesDesc": MessageLookupByLibrary.simpleMessage(
      "Check for updates when app starts",
    ),
    "autoStartIssue": MessageLookupByLibrary.simpleMessage(
      "Auto-Start Information",
    ),
    "autoStartIssueDesc": MessageLookupByLibrary.simpleMessage(
      "When enabling auto-start, it\'s recommended to disable battery optimization for the app. Currently, after enabling auto-start, the service will automatically start in the background after system reboot, but may not show a notification in the notification bar. Rest assured, the service is running normally. You can check the service status through the quick settings tile in the notification shade, or return to the main interface to check the service toggle to confirm if the service has started.",
    ),
    "autoStartWebPage": MessageLookupByLibrary.simpleMessage(
      "Set web page as startup page",
    ),
    "autoStartWebPageDesc": MessageLookupByLibrary.simpleMessage(
      "Default page when opening main interface",
    ),
    "backupRestored": MessageLookupByLibrary.simpleMessage(
      "Backup restored successfully",
    ),
    "batchDownloadComplete": MessageLookupByLibrary.simpleMessage(
      "Batch download complete",
    ),
    "bootAutoStartService": MessageLookupByLibrary.simpleMessage(
      "Boot auto-start service",
    ),
    "bootAutoStartServiceDesc": MessageLookupByLibrary.simpleMessage(
      "Automatically start OpenList service after boot. (Please make sure to grant auto-start permission)",
    ),
    "browserDownload": MessageLookupByLibrary.simpleMessage("Browser Download"),
    "browserDownloadMethod": MessageLookupByLibrary.simpleMessage(
      "Browser Download",
    ),
    "browserDownloadMethodDesc": MessageLookupByLibrary.simpleMessage(
      "Use system browser",
    ),
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
      "Cannot install APK file, you may need to enable \"Install unknown apps\" in settings",
    ),
    "cannotInstallApkNeedPermission": MessageLookupByLibrary.simpleMessage(
      "Cannot install APK file, you may need to enable \"Install unknown apps\" in settings",
    ),
    "checkDownloadManagerForFiles": MessageLookupByLibrary.simpleMessage(
      "Please check download manager via bottom navigation bar to view download files",
    ),
    "checkForUpdates": MessageLookupByLibrary.simpleMessage(
      "Check for updates",
    ),
    "checkImageInDownloadFolder": MessageLookupByLibrary.simpleMessage(
      "Please check image in download folder",
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
    "configSavedRestartRequired": MessageLookupByLibrary.simpleMessage(
      "Config saved. Please restart OpenList service to take effect.",
    ),
    "confirm": MessageLookupByLibrary.simpleMessage("OK"),
    "confirmCancelDownload": m4,
    "confirmClear": MessageLookupByLibrary.simpleMessage("Confirm Clear"),
    "confirmClearAllFiles": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to clear all download files? This action cannot be undone.",
    ),
    "confirmDelete": MessageLookupByLibrary.simpleMessage("Confirm Delete"),
    "confirmDeleteFile": m5,
    "confirmDeleteRecord": m6,
    "confirmDownload": MessageLookupByLibrary.simpleMessage("Confirm Download"),
    "confirmDownloadMessage": MessageLookupByLibrary.simpleMessage(
      "Do you want to download this file?",
    ),
    "confirmSaveConfigMessage": MessageLookupByLibrary.simpleMessage(
      "Modifying configuration may cause service unavailable. Are you sure to save?",
    ),
    "confirmSaveConfigTitle": MessageLookupByLibrary.simpleMessage(
      "Confirm Save",
    ),
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
    "currentlyDownloading": MessageLookupByLibrary.simpleMessage("Downloading"),
    "dataDirectory": MessageLookupByLibrary.simpleMessage("data Directory"),
    "databaseNotSavedIssue": MessageLookupByLibrary.simpleMessage(
      "Database Not Saved Issue",
    ),
    "databaseNotSavedIssueDesc": MessageLookupByLibrary.simpleMessage(
      "If you don\'t manually close OpenList, the database may not be saved to the corresponding db file. If you encounter this issue, please manually close the app to resolve it. (The switch is located in the main program menu on the OpenList interface, as well as in the notification bar)",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "deleteFailed": MessageLookupByLibrary.simpleMessage("Delete failed"),
    "deleteFile": MessageLookupByLibrary.simpleMessage("Delete file"),
    "deleteFileFailedLog": m10,
    "deleteRecord": MessageLookupByLibrary.simpleMessage("Delete record"),
    "description": MessageLookupByLibrary.simpleMessage("Description:"),
    "desktopShortcut": MessageLookupByLibrary.simpleMessage("Desktop shortcut"),
    "directDownload": MessageLookupByLibrary.simpleMessage("Direct Download"),
    "directDownloadApk": MessageLookupByLibrary.simpleMessage(
      "Direct Download APK",
    ),
    "directDownloadMethod": MessageLookupByLibrary.simpleMessage(
      "Direct Download",
    ),
    "directDownloadMethodDesc": MessageLookupByLibrary.simpleMessage(
      "Use in-app downloader",
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
    "downloadFunctionTest": MessageLookupByLibrary.simpleMessage(
      "Download Function Test",
    ),
    "downloadInstructions": MessageLookupByLibrary.simpleMessage(
      "• Files will be downloaded to system download directory\\n• Download progress will show notifications\\n• You can choose to open file after download completes\\n• If filename exists, a number will be added automatically\\n• Please check download manager via bottom navigation bar to view files",
    ),
    "downloadManager": MessageLookupByLibrary.simpleMessage("Download"),
    "downloadManagerWithCount": m17,
    "downloadProgress": m18,
    "downloadProgressChannel": MessageLookupByLibrary.simpleMessage(
      "Download Progress",
    ),
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
    "downloadingFileProgress": m19,
    "downloadingImage": MessageLookupByLibrary.simpleMessage(
      "Downloading image...",
    ),
    "edit": MessageLookupByLibrary.simpleMessage("Edit"),
    "editOpenListConfig": MessageLookupByLibrary.simpleMessage(
      "Edit OpenList Config",
    ),
    "english": MessageLookupByLibrary.simpleMessage("English"),
    "failed": MessageLookupByLibrary.simpleMessage("Failed"),
    "fileDeleted": MessageLookupByLibrary.simpleMessage("File deleted"),
    "fileDeletedLog": m20,
    "fileDownloadFailed": m21,
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
    "fileNotFoundWillCreateOnSave": MessageLookupByLibrary.simpleMessage(
      "File not found. Will create on save.",
    ),
    "filePath": MessageLookupByLibrary.simpleMessage("Path"),
    "filePermissionDenied": MessageLookupByLibrary.simpleMessage(
      "File permission denied. Please check app permissions.",
    ),
    "fileSavedTo": MessageLookupByLibrary.simpleMessage("File saved to:"),
    "fileSize": m22,
    "fileTime": m23,
    "findApkInDownloadFolder": MessageLookupByLibrary.simpleMessage(
      "Please find APK file in download folder to install",
    ),
    "followSystem": MessageLookupByLibrary.simpleMessage("Follow System"),
    "general": MessageLookupByLibrary.simpleMessage("General"),
    "getDownloadDirectoryFailed": m24,
    "getDownloadFileListFailed": m25,
    "getDownloadPathFailed": MessageLookupByLibrary.simpleMessage(
      "Failed to get",
    ),
    "goTo": MessageLookupByLibrary.simpleMessage("GO"),
    "goToSettings": MessageLookupByLibrary.simpleMessage("Go to Settings"),
    "grantManagerStoragePermission": MessageLookupByLibrary.simpleMessage(
      "Grant [Manage external storage] permission",
    ),
    "grantNotificationPermission": MessageLookupByLibrary.simpleMessage(
      "Grant [Notification] permission",
    ),
    "grantNotificationPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "Used for foreground service keep alive",
    ),
    "grantStoragePermission": MessageLookupByLibrary.simpleMessage(
      "Grant [external storage] permission",
    ),
    "grantStoragePermissionDesc": MessageLookupByLibrary.simpleMessage(
      "Mounting local storage is a must, otherwise no permission to read and write files",
    ),
    "imageDownloadSuccess": MessageLookupByLibrary.simpleMessage(
      "Image download success",
    ),
    "importantSettings": MessageLookupByLibrary.simpleMessage(
      "Important settings",
    ),
    "inProgress": MessageLookupByLibrary.simpleMessage("In Progress"),
    "initializingNotificationManager": MessageLookupByLibrary.simpleMessage(
      "Initializing notification manager",
    ),
    "installNow": MessageLookupByLibrary.simpleMessage("Install Now"),
    "invalidJsonFormat": m26,
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
    "laterInstall": MessageLookupByLibrary.simpleMessage("Install Later"),
    "loadDownloadFilesFailed": MessageLookupByLibrary.simpleMessage(
      "Failed to load download files",
    ),
    "loadFailed": m27,
    "modifiedTime": MessageLookupByLibrary.simpleMessage("Modified time"),
    "modifyAdminPassword": MessageLookupByLibrary.simpleMessage(
      "Modify Admin Password",
    ),
    "moreOptions": MessageLookupByLibrary.simpleMessage("More options"),
    "multipleFilesCompleted": m28,
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
    "noBackupFound": MessageLookupByLibrary.simpleMessage(
      "No backup file found",
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
    "notificationClicked": m29,
    "notificationManagerInitFailed": m30,
    "notificationManagerInitialized": MessageLookupByLibrary.simpleMessage(
      "Notification manager initialized successfully",
    ),
    "ok": MessageLookupByLibrary.simpleMessage("OK"),
    "open": MessageLookupByLibrary.simpleMessage("Open"),
    "openDirectory": MessageLookupByLibrary.simpleMessage("Open Directory"),
    "openDownloadDirectoryFailed": m31,
    "openDownloadManager": MessageLookupByLibrary.simpleMessage(
      "Open Download Manager",
    ),
    "openDownloadTestPage": MessageLookupByLibrary.simpleMessage(
      "Do you want to open download test page?",
    ),
    "openFile": MessageLookupByLibrary.simpleMessage("Open file"),
    "openFileException": m32,
    "openFileFailed": m33,
    "openFileManager": MessageLookupByLibrary.simpleMessage(
      "Open File Manager",
    ),
    "openFileManagerFailed": m34,
    "openFileResult": m35,
    "openListDownloadDirectory": m36,
    "openSourceLicenses": MessageLookupByLibrary.simpleMessage(
      "Open Source Licenses",
    ),
    "openlist": MessageLookupByLibrary.simpleMessage("OpenList"),
    "openlistMobile": MessageLookupByLibrary.simpleMessage("OpenList Mobile"),
    "parseFilenameFailed": m37,
    "pending": MessageLookupByLibrary.simpleMessage("Pending"),
    "preparingDownload": MessageLookupByLibrary.simpleMessage(
      "Preparing download...",
    ),
    "preparingDownloadStatus": MessageLookupByLibrary.simpleMessage(
      "Preparing download...",
    ),
    "preview": MessageLookupByLibrary.simpleMessage("Preview"),
    "refresh": MessageLookupByLibrary.simpleMessage("Refresh"),
    "releasePage": MessageLookupByLibrary.simpleMessage("Release Page"),
    "restartingService": MessageLookupByLibrary.simpleMessage(
      "Restarting OpenList service...",
    ),
    "restoreBackup": MessageLookupByLibrary.simpleMessage("Restore Backup"),
    "restoreBackupFailed": m38,
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "saveAndRestart": MessageLookupByLibrary.simpleMessage("Save and Restart"),
    "saveFailed": m39,
    "saveOnly": MessageLookupByLibrary.simpleMessage("Save Only"),
    "saved": MessageLookupByLibrary.simpleMessage("Saved"),
    "selectAppToOpen": MessageLookupByLibrary.simpleMessage(
      "Select app to open",
    ),
    "selectDownloadMethod": MessageLookupByLibrary.simpleMessage(
      "Select download method",
    ),
    "serviceRestartFailed": MessageLookupByLibrary.simpleMessage(
      "Failed to restart service. Please restart manually.",
    ),
    "serviceRestartOnlyAndroid": MessageLookupByLibrary.simpleMessage(
      "Service restart is only supported on Android",
    ),
    "serviceRestartSuccess": MessageLookupByLibrary.simpleMessage(
      "Service restarted successfully",
    ),
    "setAdminPassword": MessageLookupByLibrary.simpleMessage(
      "Set Admin password",
    ),
    "setDefaultDirectory": MessageLookupByLibrary.simpleMessage(
      "Set as default directory?",
    ),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "shareFeatureNotImplemented": MessageLookupByLibrary.simpleMessage(
      "Share feature not implemented yet",
    ),
    "shareFile": MessageLookupByLibrary.simpleMessage("Share file"),
    "shareLink": MessageLookupByLibrary.simpleMessage("Share Link"),
    "shareLinkDesc": MessageLookupByLibrary.simpleMessage(
      "Share download link",
    ),
    "showDownloadCompleteNotificationFailed": m40,
    "showDownloadProgressNotificationFailed": m41,
    "showInFileManager": MessageLookupByLibrary.simpleMessage(
      "Show in file manager",
    ),
    "showSingleFileCompleteNotificationFailed": m42,
    "silentJumpApp": MessageLookupByLibrary.simpleMessage("Silent jump app"),
    "silentJumpAppDesc": MessageLookupByLibrary.simpleMessage(
      "Jump to other app without prompt",
    ),
    "simplifiedChinese": MessageLookupByLibrary.simpleMessage("简体中文"),
    "size": MessageLookupByLibrary.simpleMessage("Size"),
    "startDownload": m43,
    "startDownloadFile": m44,
    "startTime": MessageLookupByLibrary.simpleMessage("Start time"),
    "testDirectDownloadFunction": MessageLookupByLibrary.simpleMessage(
      "Test direct download function",
    ),
    "testDownloadJsonFile": MessageLookupByLibrary.simpleMessage(
      "Test download JSON file",
    ),
    "testDownloadLargeFile": MessageLookupByLibrary.simpleMessage(
      "Test download large file (1MB)",
    ),
    "testDownloadPngImage": MessageLookupByLibrary.simpleMessage(
      "Test download PNG image",
    ),
    "troubleshooting": MessageLookupByLibrary.simpleMessage("Troubleshooting"),
    "troubleshootingDesc": MessageLookupByLibrary.simpleMessage(
      "Common issues and solutions",
    ),
    "tryToOpenFile": m45,
    "uiSettings": MessageLookupByLibrary.simpleMessage("UI"),
    "userCancelledDownload": MessageLookupByLibrary.simpleMessage(
      "User cancelled download",
    ),
    "userCancelledDownloadError": MessageLookupByLibrary.simpleMessage(
      "User cancelled download",
    ),
    "view": MessageLookupByLibrary.simpleMessage("View"),
    "viewDownloadDirectory": MessageLookupByLibrary.simpleMessage(
      "View download directory",
    ),
    "viewDownloadFiles": MessageLookupByLibrary.simpleMessage(
      "View download files",
    ),
    "viewDownloads": MessageLookupByLibrary.simpleMessage("View Downloads"),
    "viewLocation": MessageLookupByLibrary.simpleMessage("View Location"),
    "viewThirdPartyLicenses": MessageLookupByLibrary.simpleMessage(
      "View third-party licenses",
    ),
    "wakeLock": MessageLookupByLibrary.simpleMessage("Wake lock"),
    "wakeLockDesc": MessageLookupByLibrary.simpleMessage(
      "Prevent CPU from sleeping when screen is off. (May cause app killed in background on some devices)",
    ),
    "webPage": MessageLookupByLibrary.simpleMessage("Web Page"),
  };
}
