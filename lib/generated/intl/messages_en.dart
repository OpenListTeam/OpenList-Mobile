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

  static String m0(count) => "Rename ${count} selected items";

  static String m1(error) => "Failed to cancel all notifications: ${error}";

  static String m2(error) => "Failed to cancel download notification: ${error}";

  static String m3(error) => "Failed to check install permission: ${error}";

  static String m4(error) => "Failed to clear download directory: ${error}";

  static String m5(filename) =>
      "Are you sure you want to cancel downloading \"${filename}\"?";

  static String m6(filename) =>
      "Are you sure you want to delete file \"${filename}\"? This action cannot be undone.";

  static String m7(names) => "Delete ${names}?";

  static String m8(filename) =>
      "Are you sure you want to delete the download record of \"${filename}\"?";

  static String m9(name) => "Delete storage ${name}?";

  static String m10(name) => "Delete user ${name}?";

  static String m11(error) => "Failed to create OpenList directory: ${error}";

  static String m12(path) => "Create OpenList download directory: ${path}";

  static String m13(count) => "Currently ${count} files are downloading";

  static String m14(error) => "Failed to delete file: ${error}";

  static String m15(count) => "Delete ${count} item(s)?";

  static String m16(name) => "Delete storage \"${name}\"?";

  static String m17(url) => "Download cancelled: ${url}";

  static String m18(filename) => "Download complete: ${filename}";

  static String m19(filename) => "Download complete: ${filename}";

  static String m20(filename) => "${filename} download completed";

  static String m21(filename) => "Download failed: ${filename}";

  static String m22(filename) => "Download failed: ${filename}";

  static String m23(count) => "Download (${count})";

  static String m24(progress) => "Download progress: ${progress}%";

  static String m25(current, total) => "Downloading file ${current}/${total}";

  static String m26(error) => "Failed to copy: ${error}";

  static String m27(error) => "Failed to create folder: ${error}";

  static String m28(error) => "Failed to delete: ${error}";

  static String m29(error) => "Failed to delete storage: ${error}";

  static String m30(error) => "Failed to move: ${error}";

  static String m31(error) => "Failed to toggle storage: ${error}";

  static String m32(filename) => "File deleted: ${filename}";

  static String m33(index) => "File ${index} download failed";

  static String m34(size) => "Size: ${size}";

  static String m35(time) => "Time: ${time}";

  static String m36(error) => "Failed to get download directory: ${error}";

  static String m37(error) => "Failed to get download file list: ${error}";

  static String m38(line, error) =>
      "Invalid JSON format at line ${line}: ${error}";

  static String m39(error) => "Load failed: ${error}";

  static String m40(error) => "Failed to change mode: ${error}";

  static String m41(count) =>
      "${count} files completed, click to jump to download manager";

  static String m42(payload) => "Notification clicked: ${payload}";

  static String m43(error) =>
      "Failed to initialize notification manager: ${error}";

  static String m44(error) => "Failed to open download directory: ${error}";

  static String m45(error) => "Open file exception: ${error}";

  static String m46(error) => "Failed to open file: ${error}";

  static String m47(error) => "Failed to open file manager: ${error}";

  static String m48(type, message) => "Open file result: ${type} - ${message}";

  static String m49(path) => "OpenList download directory: ${path}";

  static String m50(error) => "Failed to parse filename: ${error}";

  static String m51(error) => "Restore backup failed: ${error}";

  static String m52(error) => "Save failed: ${error}";

  static String m53(count) => "${count} selected";

  static String m54(error) =>
      "Failed to show download complete notification: ${error}";

  static String m55(error) =>
      "Failed to show download progress notification: ${error}";

  static String m56(error) =>
      "Failed to show single file complete notification: ${error}";

  static String m57(filename) => "Start download: ${filename}";

  static String m58(filename) => "Start download: ${filename}";

  static String m59(action) => "Storage ${action}";

  static String m60(path) => "Trying to open file: ${path}";

  static String m61(name) => "Uploading ${name}";

  static String m62(count) => "${count} uploads in progress";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("About"),
    "aboutOpenList": MessageLookupByLibrary.simpleMessage("About OpenList"),
    "account": MessageLookupByLibrary.simpleMessage("Account"),
    "addMediaFavorite": MessageLookupByLibrary.simpleMessage(
      "Add to favorites",
    ),
    "addStorage": MessageLookupByLibrary.simpleMessage("Add storage"),
    "addUser": MessageLookupByLibrary.simpleMessage("Add user"),
    "addresses": MessageLookupByLibrary.simpleMessage("Addresses"),
    "adminOnly": MessageLookupByLibrary.simpleMessage(
      "Admin permission required",
    ),
    "adminPasswordHint": MessageLookupByLibrary.simpleMessage("Admin password"),
    "adminPasswordSetupMessage": MessageLookupByLibrary.simpleMessage(
      "The local core created the admin account with a random password. Set your own password to sign in from the web interface or other devices.",
    ),
    "adminPasswordSetupTitle": MessageLookupByLibrary.simpleMessage(
      "Set the admin password",
    ),
    "adminPasswordUpdated": MessageLookupByLibrary.simpleMessage(
      "Admin password updated",
    ),
    "administration": MessageLookupByLibrary.simpleMessage("Administration"),
    "administrator": MessageLookupByLibrary.simpleMessage("Administrator"),
    "allSystemsOperational": MessageLookupByLibrary.simpleMessage(
      "All systems operational",
    ),
    "apiToken": MessageLookupByLibrary.simpleMessage("API token"),
    "apkDownloadCompleteMessage": MessageLookupByLibrary.simpleMessage(
      "APK file download completed, do you want to install?",
    ),
    "appDetails": MessageLookupByLibrary.simpleMessage("App details"),
    "appName": MessageLookupByLibrary.simpleMessage("OpenList"),
    "appearance": MessageLookupByLibrary.simpleMessage("Appearance"),
    "archiveExtractionUnavailable": MessageLookupByLibrary.simpleMessage(
      "Archive extraction URL unavailable",
    ),
    "askForDownloadDirectory": MessageLookupByLibrary.simpleMessage(
      "Choose save location for every download",
    ),
    "askForDownloadDirectoryDesc": MessageLookupByLibrary.simpleMessage(
      "Ask where to save each downloaded file",
    ),
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
    "autoStartSettings": MessageLookupByLibrary.simpleMessage(
      "Auto-start settings",
    ),
    "autoStartSettingsDesc": MessageLookupByLibrary.simpleMessage(
      "Some vendors stop background apps unless auto-start is allowed.",
    ),
    "autoStartWebPage": MessageLookupByLibrary.simpleMessage(
      "Set web page as startup page",
    ),
    "autoStartWebPageDesc": MessageLookupByLibrary.simpleMessage(
      "Default page when opening main interface",
    ),
    "back": MessageLookupByLibrary.simpleMessage("Back"),
    "backgroundRestricted": MessageLookupByLibrary.simpleMessage(
      "Background activity is restricted by the system",
    ),
    "backgroundRunning": MessageLookupByLibrary.simpleMessage(
      "Background running",
    ),
    "backupRestored": MessageLookupByLibrary.simpleMessage(
      "Backup restored successfully",
    ),
    "basePath": MessageLookupByLibrary.simpleMessage("Base path"),
    "batchDownloadComplete": MessageLookupByLibrary.simpleMessage(
      "Batch download complete",
    ),
    "batchRename": MessageLookupByLibrary.simpleMessage("Batch rename"),
    "batchRenameDesc": m0,
    "batteryOptimization": MessageLookupByLibrary.simpleMessage(
      "Battery optimization",
    ),
    "batteryOptimizationActive": MessageLookupByLibrary.simpleMessage(
      "Restricted. The system may stop the server.",
    ),
    "batteryOptimizationIgnored": MessageLookupByLibrary.simpleMessage(
      "Not restricted",
    ),
    "bootAutoStartService": MessageLookupByLibrary.simpleMessage(
      "Boot auto-start service",
    ),
    "bootAutoStartServiceDesc": MessageLookupByLibrary.simpleMessage(
      "Automatically start OpenList service after boot. (Please make sure to grant auto-start permission)",
    ),
    "browseFiles": MessageLookupByLibrary.simpleMessage("Browse Files"),
    "browseFunctionalityComingSoon": MessageLookupByLibrary.simpleMessage(
      "Browse functionality coming soon",
    ),
    "browserDownload": MessageLookupByLibrary.simpleMessage("Browser Download"),
    "browserDownloadMethod": MessageLookupByLibrary.simpleMessage(
      "Browser Download",
    ),
    "browserDownloadMethodDesc": MessageLookupByLibrary.simpleMessage(
      "Use system browser",
    ),
    "cache": MessageLookupByLibrary.simpleMessage("Cache"),
    "cacheCleared": MessageLookupByLibrary.simpleMessage("Cache cleared"),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "cancelAllNotificationsFailed": m1,
    "cancelDownload": MessageLookupByLibrary.simpleMessage("Cancel Download"),
    "cancelDownloadNotificationFailed": m2,
    "canceled": MessageLookupByLibrary.simpleMessage("Canceled"),
    "cancelled": MessageLookupByLibrary.simpleMessage("Cancelled"),
    "cancelling": MessageLookupByLibrary.simpleMessage("Cancelling"),
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
    "certFile": MessageLookupByLibrary.simpleMessage("Certificate (PEM)"),
    "changeAdminPassword": MessageLookupByLibrary.simpleMessage(
      "Change Admin Password",
    ),
    "changeAdminPasswordDesc": MessageLookupByLibrary.simpleMessage(
      "Update server admin password",
    ),
    "checkAdmin2fa": MessageLookupByLibrary.simpleMessage(
      "Admin two-factor authentication",
    ),
    "checkDownloadManagerForFiles": MessageLookupByLibrary.simpleMessage(
      "Please check download manager via bottom navigation bar to view download files",
    ),
    "checkForUpdates": MessageLookupByLibrary.simpleMessage(
      "Check for updates",
    ),
    "checkForceHttps": MessageLookupByLibrary.simpleMessage(
      "HTTP disabled or redirected to HTTPS",
    ),
    "checkFtpPlaintext": MessageLookupByLibrary.simpleMessage(
      "FTP sends credentials in plain text",
    ),
    "checkGuestDisabled": MessageLookupByLibrary.simpleMessage(
      "Guest account disabled",
    ),
    "checkImageInDownloadFolder": MessageLookupByLibrary.simpleMessage(
      "Please check image in download folder",
    ),
    "checkInstallPermissionFailed": m3,
    "checkNotInitialized": MessageLookupByLibrary.simpleMessage(
      "Server not initialized",
    ),
    "checkS3Tls": MessageLookupByLibrary.simpleMessage("S3 server uses TLS"),
    "checkTls": MessageLookupByLibrary.simpleMessage("Valid TLS certificate"),
    "chooseFile": MessageLookupByLibrary.simpleMessage("Choose file"),
    "clear": MessageLookupByLibrary.simpleMessage("Clear"),
    "clearAll": MessageLookupByLibrary.simpleMessage("Clear All"),
    "clearCache": MessageLookupByLibrary.simpleMessage("Clear Cache"),
    "clearCacheDesc": MessageLookupByLibrary.simpleMessage(
      "Free up storage space",
    ),
    "clearCompleted": MessageLookupByLibrary.simpleMessage("Clear Completed"),
    "clearDownloadDirectoryFailed": m4,
    "clearFailed": MessageLookupByLibrary.simpleMessage("Clear failed"),
    "clearFinished": MessageLookupByLibrary.simpleMessage("Clear finished"),
    "clearRecords": MessageLookupByLibrary.simpleMessage("Clear Records"),
    "clearSucceeded": MessageLookupByLibrary.simpleMessage("Clear succeeded"),
    "cleared": MessageLookupByLibrary.simpleMessage(
      "Download directory cleared",
    ),
    "clickToJumpToDownloadManager": MessageLookupByLibrary.simpleMessage(
      "Tap to view downloads",
    ),
    "completed": MessageLookupByLibrary.simpleMessage("Completed"),
    "completedTime": MessageLookupByLibrary.simpleMessage("Completed time"),
    "configSavedRestartRequired": MessageLookupByLibrary.simpleMessage(
      "Config saved. Please restart OpenList service to take effect.",
    ),
    "configuration": MessageLookupByLibrary.simpleMessage("Configuration"),
    "confirm": MessageLookupByLibrary.simpleMessage("OK"),
    "confirmCancelDownload": m5,
    "confirmClear": MessageLookupByLibrary.simpleMessage("Confirm Clear"),
    "confirmClearAllFiles": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to clear all files managed by OpenList? This action cannot be undone.",
    ),
    "confirmDelete": MessageLookupByLibrary.simpleMessage("Confirm Delete"),
    "confirmDeleteFile": m6,
    "confirmDeleteItems": m7,
    "confirmDeleteRecord": m8,
    "confirmDeleteStorage": m9,
    "confirmDeleteUser": m10,
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
    "connectFailed": MessageLookupByLibrary.simpleMessage("Connection failed"),
    "connectToServer": MessageLookupByLibrary.simpleMessage(
      "Connect to Server",
    ),
    "connectedToServer": MessageLookupByLibrary.simpleMessage(
      "Connected to server",
    ),
    "connection": MessageLookupByLibrary.simpleMessage("Connection"),
    "connectionUrls": MessageLookupByLibrary.simpleMessage("Connection URLs"),
    "continueDownload": MessageLookupByLibrary.simpleMessage(
      "Continue Download",
    ),
    "copiedToClipboard": MessageLookupByLibrary.simpleMessage(
      "Copied to clipboard",
    ),
    "copy": MessageLookupByLibrary.simpleMessage("Copy"),
    "copyFunctionalityComingSoon": MessageLookupByLibrary.simpleMessage(
      "Copy functionality coming soon",
    ),
    "copyLink": MessageLookupByLibrary.simpleMessage("Copy link"),
    "copyTo": MessageLookupByLibrary.simpleMessage("Copy to"),
    "copying": MessageLookupByLibrary.simpleMessage("Copying files..."),
    "coreSettings": MessageLookupByLibrary.simpleMessage("Core settings"),
    "coreSettingsDesc": MessageLookupByLibrary.simpleMessage(
      "Configure OpenList Core without the web interface",
    ),
    "couldNotOpenUrl": MessageLookupByLibrary.simpleMessage(
      "Could not open URL",
    ),
    "cpuTime": MessageLookupByLibrary.simpleMessage("CPU time"),
    "create": MessageLookupByLibrary.simpleMessage("Create"),
    "createOpenListDirectoryFailed": m11,
    "createOpenListDownloadDirectory": m12,
    "currentDownloadingFiles": m13,
    "currentIsLatestVersion": MessageLookupByLibrary.simpleMessage(
      "Current is latest version",
    ),
    "currentlyDownloading": MessageLookupByLibrary.simpleMessage("Downloading"),
    "dataDirectory": MessageLookupByLibrary.simpleMessage("Data directory"),
    "dataDirectoryChangeWarning": MessageLookupByLibrary.simpleMessage(
      "The server will use the selected directory without moving existing data. Select only an accessible local folder.",
    ),
    "databaseNotSavedIssue": MessageLookupByLibrary.simpleMessage(
      "Database Not Saved Issue",
    ),
    "databaseNotSavedIssueDesc": MessageLookupByLibrary.simpleMessage(
      "If you don\'t manually close OpenList, the database may not be saved to the corresponding db file. If you encounter this issue, please manually close the app to resolve it. (The switch is located in the main program menu on the OpenList interface, as well as in the notification bar)",
    ),
    "defaultDirectory": MessageLookupByLibrary.simpleMessage(
      "Default directory",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "deleteFailed": MessageLookupByLibrary.simpleMessage("Delete failed"),
    "deleteFile": MessageLookupByLibrary.simpleMessage("Delete file"),
    "deleteFileFailedLog": m14,
    "deleteFiles": MessageLookupByLibrary.simpleMessage("Delete Files"),
    "deleteItemsConfirm": m15,
    "deletePolicy": MessageLookupByLibrary.simpleMessage("Delete policy"),
    "deleteRecord": MessageLookupByLibrary.simpleMessage("Delete record"),
    "deleteStorage": MessageLookupByLibrary.simpleMessage("Delete Storage"),
    "deleteStorageMessage": m16,
    "deleteStorageTitle": MessageLookupByLibrary.simpleMessage(
      "Delete Storage",
    ),
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
    "disable": MessageLookupByLibrary.simpleMessage("Disable"),
    "disableStorage": MessageLookupByLibrary.simpleMessage("Disable Storage"),
    "disabled": MessageLookupByLibrary.simpleMessage("disabled"),
    "download": MessageLookupByLibrary.simpleMessage("download"),
    "downloadApk": MessageLookupByLibrary.simpleMessage("Download APK"),
    "downloadCancelled": m17,
    "downloadCancelledStatus": MessageLookupByLibrary.simpleMessage(
      "Download cancelled",
    ),
    "downloadCancelledText": MessageLookupByLibrary.simpleMessage(
      "Download cancelled",
    ),
    "downloadComplete": m18,
    "downloadCompleteChannel": MessageLookupByLibrary.simpleMessage(
      "Download Complete",
    ),
    "downloadCompleteChannelDesc": MessageLookupByLibrary.simpleMessage(
      "File download complete notification",
    ),
    "downloadCompleteFile": m19,
    "downloadCompleteNotificationTitle": m20,
    "downloadCompleteTitle": MessageLookupByLibrary.simpleMessage(
      "Download Complete",
    ),
    "downloadDirectory": MessageLookupByLibrary.simpleMessage(
      "Download Directory",
    ),
    "downloadDirectoryCleared": MessageLookupByLibrary.simpleMessage(
      "Download directory cleared",
    ),
    "downloadDirectoryNotWritable": MessageLookupByLibrary.simpleMessage(
      "The selected directory is not writable by OpenList",
    ),
    "downloadDirectoryOpened": MessageLookupByLibrary.simpleMessage(
      "Download directory opened",
    ),
    "downloadDirectoryPathUnknown": MessageLookupByLibrary.simpleMessage(
      "Download directory path unknown",
    ),
    "downloadFailed": MessageLookupByLibrary.simpleMessage("Download failed"),
    "downloadFailedFile": m21,
    "downloadFailedWithError": m22,
    "downloadFunctionTest": MessageLookupByLibrary.simpleMessage(
      "Download Function Test",
    ),
    "downloadInstructions": MessageLookupByLibrary.simpleMessage(
      "• Files will be downloaded to system download directory\\n• Download progress will show notifications\\n• You can choose to open file after download completes\\n• If filename exists, a number will be added automatically\\n• Please check download manager via bottom navigation bar to view files",
    ),
    "downloadManager": MessageLookupByLibrary.simpleMessage("Download"),
    "downloadManagerWithCount": m23,
    "downloadProgress": m24,
    "downloadProgressChannel": MessageLookupByLibrary.simpleMessage(
      "Download Progress",
    ),
    "downloadProgressDesc": MessageLookupByLibrary.simpleMessage(
      "Show file download progress",
    ),
    "downloadRecordsCleared": MessageLookupByLibrary.simpleMessage(
      "Download records cleared",
    ),
    "downloadStarted": MessageLookupByLibrary.simpleMessage("Download started"),
    "downloadThisFile": MessageLookupByLibrary.simpleMessage(
      "Download this file？",
    ),
    "downloadedFilesWillAppearHere": MessageLookupByLibrary.simpleMessage(
      "Downloaded files will appear here",
    ),
    "downloading": MessageLookupByLibrary.simpleMessage("Downloading"),
    "downloadingFileProgress": m25,
    "downloadingImage": MessageLookupByLibrary.simpleMessage(
      "Downloading image...",
    ),
    "downloads": MessageLookupByLibrary.simpleMessage("Downloads"),
    "driver": MessageLookupByLibrary.simpleMessage("Driver"),
    "driverNoUpload": MessageLookupByLibrary.simpleMessage(
      "This driver does not support uploads",
    ),
    "edit": MessageLookupByLibrary.simpleMessage("Edit"),
    "editOpenListConfig": MessageLookupByLibrary.simpleMessage(
      "Edit OpenList Config",
    ),
    "editStorage": MessageLookupByLibrary.simpleMessage("Edit Storage"),
    "editUser": MessageLookupByLibrary.simpleMessage("Edit user"),
    "emptyFolder": MessageLookupByLibrary.simpleMessage("This folder is empty"),
    "emptyInput": MessageLookupByLibrary.simpleMessage(
      "The input cannot be empty",
    ),
    "enable": MessageLookupByLibrary.simpleMessage("Enable"),
    "enableStorage": MessageLookupByLibrary.simpleMessage("Enable Storage"),
    "enableWebBrowser": MessageLookupByLibrary.simpleMessage(
      "Enable embedded web browser",
    ),
    "enableWebBrowserDesc": MessageLookupByLibrary.simpleMessage(
      "Allow the Web page to run the embedded browser",
    ),
    "enabled": MessageLookupByLibrary.simpleMessage("enabled"),
    "english": MessageLookupByLibrary.simpleMessage("English"),
    "enterFileName": MessageLookupByLibrary.simpleMessage("Enter file name"),
    "enterFolderName": MessageLookupByLibrary.simpleMessage(
      "Enter folder name",
    ),
    "error": MessageLookupByLibrary.simpleMessage("Error"),
    "exposureMode": MessageLookupByLibrary.simpleMessage("Access mode"),
    "failed": MessageLookupByLibrary.simpleMessage("Failed"),
    "failedToConnectToServer": MessageLookupByLibrary.simpleMessage(
      "Failed to connect to server",
    ),
    "failedToCopy": m26,
    "failedToCreateFolder": m27,
    "failedToDelete": m28,
    "failedToDeleteStorage": m29,
    "failedToLoadFiles": MessageLookupByLibrary.simpleMessage(
      "Failed to load files",
    ),
    "failedToMove": m30,
    "failedToToggleStorage": m31,
    "favorites": MessageLookupByLibrary.simpleMessage("Favorites"),
    "fileDeleted": MessageLookupByLibrary.simpleMessage("File deleted"),
    "fileDeletedLog": m32,
    "fileDownloadFailed": m33,
    "fileInfo": MessageLookupByLibrary.simpleMessage("File info"),
    "fileLocation": MessageLookupByLibrary.simpleMessage("File Location"),
    "fileLocationTip": MessageLookupByLibrary.simpleMessage(
      "You can use a file manager to find this file, or try installing the appropriate app to open it.",
    ),
    "fileManagerOpened": MessageLookupByLibrary.simpleMessage(
      "File manager opened",
    ),
    "fileName": MessageLookupByLibrary.simpleMessage("File Name"),
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
    "fileSize": m34,
    "fileTime": m35,
    "files": MessageLookupByLibrary.simpleMessage("Files"),
    "findApkInDownloadFolder": MessageLookupByLibrary.simpleMessage(
      "Please find APK file in download folder to install",
    ),
    "findReplace": MessageLookupByLibrary.simpleMessage("Find & replace"),
    "folderName": MessageLookupByLibrary.simpleMessage("Folder Name"),
    "folderPassword": MessageLookupByLibrary.simpleMessage("Folder password"),
    "followSystem": MessageLookupByLibrary.simpleMessage("Follow System"),
    "forceHttps": MessageLookupByLibrary.simpleMessage("Force HTTPS"),
    "fullscreen": MessageLookupByLibrary.simpleMessage("Fullscreen"),
    "general": MessageLookupByLibrary.simpleMessage("General"),
    "getDownloadDirectoryFailed": m36,
    "getDownloadFileListFailed": m37,
    "getDownloadPathFailed": MessageLookupByLibrary.simpleMessage(
      "Failed to get",
    ),
    "githubRepo": MessageLookupByLibrary.simpleMessage("GitHub Repository"),
    "goTo": MessageLookupByLibrary.simpleMessage("GO"),
    "goToSettings": MessageLookupByLibrary.simpleMessage("Go to Settings"),
    "goroutines": MessageLookupByLibrary.simpleMessage("Goroutines"),
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
    "groupFtp": MessageLookupByLibrary.simpleMessage("FTP"),
    "groupGlobal": MessageLookupByLibrary.simpleMessage("Global"),
    "groupIndex": MessageLookupByLibrary.simpleMessage("Index"),
    "groupLdap": MessageLookupByLibrary.simpleMessage("LDAP"),
    "groupMedia": MessageLookupByLibrary.simpleMessage("Media"),
    "groupOfflineDownload": MessageLookupByLibrary.simpleMessage(
      "Offline download",
    ),
    "groupPreview": MessageLookupByLibrary.simpleMessage("Preview"),
    "groupS3": MessageLookupByLibrary.simpleMessage("S3"),
    "groupSite": MessageLookupByLibrary.simpleMessage("Site"),
    "groupSso": MessageLookupByLibrary.simpleMessage("SSO"),
    "groupStyle": MessageLookupByLibrary.simpleMessage("Style"),
    "groupTraffic": MessageLookupByLibrary.simpleMessage("Traffic"),
    "groupTranscode": MessageLookupByLibrary.simpleMessage("Transcode"),
    "home": MessageLookupByLibrary.simpleMessage("Home"),
    "httpPort": MessageLookupByLibrary.simpleMessage("HTTP Port"),
    "httpsPort": MessageLookupByLibrary.simpleMessage("HTTPS Port"),
    "imageDownloadSuccess": MessageLookupByLibrary.simpleMessage(
      "Image download success",
    ),
    "importantSettings": MessageLookupByLibrary.simpleMessage(
      "Important settings",
    ),
    "inProgress": MessageLookupByLibrary.simpleMessage("In Progress"),
    "info": MessageLookupByLibrary.simpleMessage("Info"),
    "initializingNotificationManager": MessageLookupByLibrary.simpleMessage(
      "Initializing notification manager",
    ),
    "installNow": MessageLookupByLibrary.simpleMessage("Install Now"),
    "invalidFilenameChars": MessageLookupByLibrary.simpleMessage(
      "The name contains invalid characters",
    ),
    "invalidJsonFormat": m38,
    "invalidPem": MessageLookupByLibrary.simpleMessage(
      "The file is not a PEM certificate or private key",
    ),
    "invalidPort": MessageLookupByLibrary.simpleMessage(
      "Enter a port from 1 to 65535, or -1 to disable",
    ),
    "invalidRegex": MessageLookupByLibrary.simpleMessage(
      "The pattern is not a valid regular expression",
    ),
    "iosBackgroundNote": MessageLookupByLibrary.simpleMessage(
      "iOS only keeps the server running while the app is in the foreground or briefly after it leaves.",
    ),
    "jumpToOtherApp": MessageLookupByLibrary.simpleMessage(
      "Jump to other app？",
    ),
    "keyFile": MessageLookupByLibrary.simpleMessage("Private key (PEM)"),
    "language": MessageLookupByLibrary.simpleMessage("Language"),
    "languageSettings": MessageLookupByLibrary.simpleMessage(
      "Language Settings",
    ),
    "languageSettingsDesc": MessageLookupByLibrary.simpleMessage(
      "Select app display language",
    ),
    "lastError": MessageLookupByLibrary.simpleMessage("Last error"),
    "later": MessageLookupByLibrary.simpleMessage("Later"),
    "laterInstall": MessageLookupByLibrary.simpleMessage("Install Later"),
    "loadDownloadFilesFailed": MessageLookupByLibrary.simpleMessage(
      "Failed to load download files",
    ),
    "loadFailed": m39,
    "loadStoragesFailed": MessageLookupByLibrary.simpleMessage(
      "Failed to load storages",
    ),
    "loadingStorages": MessageLookupByLibrary.simpleMessage("Loading..."),
    "localServer": MessageLookupByLibrary.simpleMessage("Local server"),
    "login": MessageLookupByLibrary.simpleMessage("Sign in"),
    "logout": MessageLookupByLibrary.simpleMessage("Sign out"),
    "manageStorages": MessageLookupByLibrary.simpleMessage("Manage Storages"),
    "manageStoragesDesc": MessageLookupByLibrary.simpleMessage(
      "Add, edit, or remove storage locations",
    ),
    "mediaFavoriteAdded": MessageLookupByLibrary.simpleMessage(
      "Added to favorites",
    ),
    "mediaLibraryUnavailable": MessageLookupByLibrary.simpleMessage(
      "Media library is not enabled",
    ),
    "mediaPlaybackInterrupted": MessageLookupByLibrary.simpleMessage(
      "Playback stopped. Check the file format or connection.",
    ),
    "mediaPlaybackUnavailable": MessageLookupByLibrary.simpleMessage(
      "Media playback is unavailable on this device",
    ),
    "memory": MessageLookupByLibrary.simpleMessage("Memory"),
    "mode": MessageLookupByLibrary.simpleMessage("Mode"),
    "modeChangeFailed": m40,
    "modeChangeRestart": MessageLookupByLibrary.simpleMessage(
      "The new mode takes effect after the server restarts.",
    ),
    "modeChangedRestart": MessageLookupByLibrary.simpleMessage(
      "Mode changed. Restart server to apply.",
    ),
    "modeLan": MessageLookupByLibrary.simpleMessage("Local network"),
    "modeLanDesc": MessageLookupByLibrary.simpleMessage(
      "Listens on all interfaces. Devices on the same network can connect.",
    ),
    "modeLocal": MessageLookupByLibrary.simpleMessage("This device only"),
    "modeLocalDesc": MessageLookupByLibrary.simpleMessage(
      "Listens on 127.0.0.1. Other devices cannot connect.",
    ),
    "modePublic": MessageLookupByLibrary.simpleMessage("Public"),
    "modePublicDesc": MessageLookupByLibrary.simpleMessage(
      "Reachable from the internet. Requires TLS, forced HTTPS and a disabled guest account.",
    ),
    "modifiedTime": MessageLookupByLibrary.simpleMessage("Modified time"),
    "modifyAdminPassword": MessageLookupByLibrary.simpleMessage(
      "Modify Admin Password",
    ),
    "moreOptions": MessageLookupByLibrary.simpleMessage("More options"),
    "move": MessageLookupByLibrary.simpleMessage("Move"),
    "moveFunctionalityComingSoon": MessageLookupByLibrary.simpleMessage(
      "Move functionality coming soon",
    ),
    "moveTo": MessageLookupByLibrary.simpleMessage("Move to"),
    "moving": MessageLookupByLibrary.simpleMessage("Moving files..."),
    "multipleFilesCompleted": m41,
    "myStorages": MessageLookupByLibrary.simpleMessage("My Storages"),
    "nativeFiles": MessageLookupByLibrary.simpleMessage("Files"),
    "needInstallPermission": MessageLookupByLibrary.simpleMessage(
      "Install Permission Required",
    ),
    "needInstallPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "To install APK files, install permission is required. Please enable it manually in settings.",
    ),
    "needInstallPermissionToInstallApk": MessageLookupByLibrary.simpleMessage(
      "Install permission is required to install APK files",
    ),
    "networkMode": MessageLookupByLibrary.simpleMessage("Network Mode"),
    "newFile": MessageLookupByLibrary.simpleMessage("New File"),
    "newFolder": MessageLookupByLibrary.simpleMessage("New Folder"),
    "newName": MessageLookupByLibrary.simpleMessage("New name"),
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
    "noChanges": MessageLookupByLibrary.simpleMessage("No changes"),
    "noCompletedDownloads": MessageLookupByLibrary.simpleMessage(
      "No completed downloads",
    ),
    "noDownloads": MessageLookupByLibrary.simpleMessage("No downloads"),
    "noFilesHere": MessageLookupByLibrary.simpleMessage("No files here"),
    "noMediaItems": MessageLookupByLibrary.simpleMessage("No media items"),
    "noOfflineTools": MessageLookupByLibrary.simpleMessage(
      "No offline download tool is configured on the server",
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
    "noRecentFiles": MessageLookupByLibrary.simpleMessage("No recent files"),
    "noSearchResults": MessageLookupByLibrary.simpleMessage("No results"),
    "noStorages": MessageLookupByLibrary.simpleMessage("No storages"),
    "noStoragesConfigured": MessageLookupByLibrary.simpleMessage(
      "No storages configured",
    ),
    "noStoragesDesc": MessageLookupByLibrary.simpleMessage(
      "Add a storage to get started with OpenList",
    ),
    "noTasks": MessageLookupByLibrary.simpleMessage("No tasks"),
    "noUploads": MessageLookupByLibrary.simpleMessage("No uploads"),
    "notConfigured": MessageLookupByLibrary.simpleMessage("Not configured"),
    "notConnected": MessageLookupByLibrary.simpleMessage("Not Connected"),
    "notificationClicked": m42,
    "notificationManagerInitFailed": m43,
    "notificationManagerInitialized": MessageLookupByLibrary.simpleMessage(
      "Notification manager initialized successfully",
    ),
    "notificationsDisabled": MessageLookupByLibrary.simpleMessage(
      "Notifications are off, so the server status notification is hidden",
    ),
    "offlineAdded": MessageLookupByLibrary.simpleMessage(
      "Offline download task added",
    ),
    "offlineDownload": MessageLookupByLibrary.simpleMessage("Offline download"),
    "offlineTool": MessageLookupByLibrary.simpleMessage("Tool"),
    "offlineUrls": MessageLookupByLibrary.simpleMessage("URLs, one per line"),
    "ok": MessageLookupByLibrary.simpleMessage("OK"),
    "open": MessageLookupByLibrary.simpleMessage("Open"),
    "openDirectory": MessageLookupByLibrary.simpleMessage("Open Directory"),
    "openDownloadDirectoryFailed": m44,
    "openDownloadManager": MessageLookupByLibrary.simpleMessage(
      "Open Downloads",
    ),
    "openDownloadTestPage": MessageLookupByLibrary.simpleMessage(
      "Do you want to open download test page?",
    ),
    "openFile": MessageLookupByLibrary.simpleMessage("Open file"),
    "openFileException": m45,
    "openFileFailed": m46,
    "openFileManager": MessageLookupByLibrary.simpleMessage(
      "Open File Manager",
    ),
    "openFileManagerFailed": m47,
    "openFileResult": m48,
    "openListDownloadDirectory": m49,
    "openSourceLicenses": MessageLookupByLibrary.simpleMessage(
      "Open Source Licenses",
    ),
    "openWebInterface": MessageLookupByLibrary.simpleMessage(
      "Open web interface",
    ),
    "openlist": MessageLookupByLibrary.simpleMessage("OpenList"),
    "openlistMobile": MessageLookupByLibrary.simpleMessage("OpenList Mobile"),
    "operationDone": MessageLookupByLibrary.simpleMessage("Done"),
    "operationFailed": MessageLookupByLibrary.simpleMessage("Operation failed"),
    "otpCode": MessageLookupByLibrary.simpleMessage("2FA code (optional)"),
    "parseFilenameFailed": m50,
    "password": MessageLookupByLibrary.simpleMessage("Password"),
    "passwordKeepHint": MessageLookupByLibrary.simpleMessage(
      "Leave empty to keep the current password",
    ),
    "pause": MessageLookupByLibrary.simpleMessage("Pause"),
    "pauseIndividualTransfers": MessageLookupByLibrary.simpleMessage(
      "Pause individual transfers",
    ),
    "paused": MessageLookupByLibrary.simpleMessage("Paused"),
    "pending": MessageLookupByLibrary.simpleMessage("Pending"),
    "permAccessWithoutPassword": MessageLookupByLibrary.simpleMessage(
      "Access without password",
    ),
    "permCopy": MessageLookupByLibrary.simpleMessage("Copy"),
    "permCustomShareId": MessageLookupByLibrary.simpleMessage(
      "Custom share ID",
    ),
    "permDecompress": MessageLookupByLibrary.simpleMessage(
      "Decompress archives",
    ),
    "permFtpAccess": MessageLookupByLibrary.simpleMessage("FTP/SFTP read"),
    "permFtpManage": MessageLookupByLibrary.simpleMessage("FTP/SFTP write"),
    "permMove": MessageLookupByLibrary.simpleMessage("Move"),
    "permOfflineDownload": MessageLookupByLibrary.simpleMessage(
      "Add offline downloads",
    ),
    "permReadArchives": MessageLookupByLibrary.simpleMessage("Read archives"),
    "permRemove": MessageLookupByLibrary.simpleMessage("Delete"),
    "permRename": MessageLookupByLibrary.simpleMessage("Rename"),
    "permSeeHides": MessageLookupByLibrary.simpleMessage("See hidden files"),
    "permShare": MessageLookupByLibrary.simpleMessage("Create shares"),
    "permWebdavManage": MessageLookupByLibrary.simpleMessage("WebDAV write"),
    "permWebdavRead": MessageLookupByLibrary.simpleMessage("WebDAV read"),
    "permWrite": MessageLookupByLibrary.simpleMessage(
      "Create folders and upload",
    ),
    "permissions": MessageLookupByLibrary.simpleMessage("Permissions"),
    "photos": MessageLookupByLibrary.simpleMessage("Photos"),
    "play": MessageLookupByLibrary.simpleMessage("Play"),
    "policyDeleteAlways": MessageLookupByLibrary.simpleMessage("Always delete"),
    "policyDeleteNever": MessageLookupByLibrary.simpleMessage("Never delete"),
    "policyDeleteOnUploadFailed": MessageLookupByLibrary.simpleMessage(
      "Delete after upload fails",
    ),
    "policyDeleteOnUploadSucceed": MessageLookupByLibrary.simpleMessage(
      "Delete after upload succeeds",
    ),
    "policyUploadDownloadStream": MessageLookupByLibrary.simpleMessage(
      "Upload while downloading",
    ),
    "preparingDownload": MessageLookupByLibrary.simpleMessage(
      "Preparing download...",
    ),
    "preparingDownloadStatus": MessageLookupByLibrary.simpleMessage(
      "Preparing download...",
    ),
    "preview": MessageLookupByLibrary.simpleMessage("Preview"),
    "previewNotSupported": MessageLookupByLibrary.simpleMessage(
      "Preview is not supported for this file type",
    ),
    "processMemory": MessageLookupByLibrary.simpleMessage(
      "Process memory (PSS)",
    ),
    "publicBlocked": MessageLookupByLibrary.simpleMessage(
      "Public mode stays blocked until every required check passes.",
    ),
    "publicModeWarning": MessageLookupByLibrary.simpleMessage(
      "Exposing the server to the internet lets anyone reach it. Make sure the admin password is strong and 2FA is enabled.",
    ),
    "quickAccess": MessageLookupByLibrary.simpleMessage("Quick Access"),
    "recentFiles": MessageLookupByLibrary.simpleMessage("Recent Files"),
    "refresh": MessageLookupByLibrary.simpleMessage("Refresh"),
    "regexRename": MessageLookupByLibrary.simpleMessage("Regex"),
    "releasePage": MessageLookupByLibrary.simpleMessage("Release Page"),
    "reloadAll": MessageLookupByLibrary.simpleMessage("Reload all"),
    "remark": MessageLookupByLibrary.simpleMessage("Remark"),
    "remoteServer": MessageLookupByLibrary.simpleMessage("Remote server"),
    "remove": MessageLookupByLibrary.simpleMessage("Remove"),
    "removeMediaFavorite": MessageLookupByLibrary.simpleMessage(
      "Remove from favorites",
    ),
    "rename": MessageLookupByLibrary.simpleMessage("Rename"),
    "renameNoMatch": MessageLookupByLibrary.simpleMessage(
      "No items match the pattern",
    ),
    "renamePaddingZeros": MessageLookupByLibrary.simpleMessage("Zero padding"),
    "renamePattern": MessageLookupByLibrary.simpleMessage(
      "Pattern (regular expression)",
    ),
    "renameReplacement": MessageLookupByLibrary.simpleMessage("Replacement"),
    "renameSearchText": MessageLookupByLibrary.simpleMessage("Text to find"),
    "renameStartNumber": MessageLookupByLibrary.simpleMessage("Start number"),
    "requestIgnoreBattery": MessageLookupByLibrary.simpleMessage(
      "Allow running in background",
    ),
    "requiredField": MessageLookupByLibrary.simpleMessage("Required"),
    "reset2fa": MessageLookupByLibrary.simpleMessage("Reset 2FA"),
    "resetToken": MessageLookupByLibrary.simpleMessage("Reset API token"),
    "resetTokenConfirm": MessageLookupByLibrary.simpleMessage(
      "Resetting the API token invalidates clients using the current token. Continue?",
    ),
    "resetTokenSuccess": MessageLookupByLibrary.simpleMessage(
      "API token reset",
    ),
    "restartServer": MessageLookupByLibrary.simpleMessage("Restart server"),
    "restartingService": MessageLookupByLibrary.simpleMessage(
      "Restarting OpenList service...",
    ),
    "restoreBackup": MessageLookupByLibrary.simpleMessage("Restore Backup"),
    "restoreBackupFailed": m51,
    "resume": MessageLookupByLibrary.simpleMessage("Resume"),
    "retry": MessageLookupByLibrary.simpleMessage("Retry"),
    "retryFailed": MessageLookupByLibrary.simpleMessage("Retry Failed"),
    "role": MessageLookupByLibrary.simpleMessage("Role"),
    "roleAdmin": MessageLookupByLibrary.simpleMessage("Admin"),
    "roleGeneral": MessageLookupByLibrary.simpleMessage("General"),
    "roleGuest": MessageLookupByLibrary.simpleMessage("Guest"),
    "running": MessageLookupByLibrary.simpleMessage("Running"),
    "runtimeStatistics": MessageLookupByLibrary.simpleMessage(
      "Runtime Statistics",
    ),
    "runtimeStatus": MessageLookupByLibrary.simpleMessage("Runtime"),
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "saveAndRestart": MessageLookupByLibrary.simpleMessage("Save and Restart"),
    "saveFailed": m52,
    "saveOnly": MessageLookupByLibrary.simpleMessage("Save Only"),
    "saved": MessageLookupByLibrary.simpleMessage("Saved"),
    "search": MessageLookupByLibrary.simpleMessage("Search"),
    "searchAll": MessageLookupByLibrary.simpleMessage("All"),
    "searchFiles": MessageLookupByLibrary.simpleMessage("Files"),
    "searchFolders": MessageLookupByLibrary.simpleMessage("Folders"),
    "searchHint": MessageLookupByLibrary.simpleMessage("Keywords"),
    "securityChecks": MessageLookupByLibrary.simpleMessage("Security checks"),
    "seeAll": MessageLookupByLibrary.simpleMessage("See All"),
    "selectAppToOpen": MessageLookupByLibrary.simpleMessage(
      "Select app to open",
    ),
    "selectDownloadMethod": MessageLookupByLibrary.simpleMessage(
      "Select download method",
    ),
    "selectNetworkMode": MessageLookupByLibrary.simpleMessage(
      "Select Network Mode",
    ),
    "selectThisFolder": MessageLookupByLibrary.simpleMessage(
      "Select this folder",
    ),
    "selected": MessageLookupByLibrary.simpleMessage("selected"),
    "selectedCount": m53,
    "sequentialRename": MessageLookupByLibrary.simpleMessage("Sequential"),
    "server": MessageLookupByLibrary.simpleMessage("Server"),
    "serverDetails": MessageLookupByLibrary.simpleMessage("Server Details"),
    "serverDetailsDesc": MessageLookupByLibrary.simpleMessage(
      "View runtime info and connection details",
    ),
    "serverNotRunning": MessageLookupByLibrary.simpleMessage(
      "The local server is not running",
    ),
    "serverRunning": MessageLookupByLibrary.simpleMessage("Server Running"),
    "serverRuntime": MessageLookupByLibrary.simpleMessage("Server"),
    "serverStopped": MessageLookupByLibrary.simpleMessage("Server Stopped"),
    "serverUrl": MessageLookupByLibrary.simpleMessage("Server URL"),
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
    "showDownloadCompleteNotificationFailed": m54,
    "showDownloadProgressNotificationFailed": m55,
    "showInFileManager": MessageLookupByLibrary.simpleMessage(
      "Show in file manager",
    ),
    "showSingleFileCompleteNotificationFailed": m56,
    "signOut": MessageLookupByLibrary.simpleMessage("Sign Out"),
    "signOutConfirmMessage": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to sign out?",
    ),
    "signOutConfirmTitle": MessageLookupByLibrary.simpleMessage("Sign Out"),
    "silentJumpApp": MessageLookupByLibrary.simpleMessage("Silent jump app"),
    "silentJumpAppDesc": MessageLookupByLibrary.simpleMessage(
      "Jump to other app without prompt",
    ),
    "simplifiedChinese": MessageLookupByLibrary.simpleMessage("简体中文"),
    "siteSettings": MessageLookupByLibrary.simpleMessage("Site settings"),
    "size": MessageLookupByLibrary.simpleMessage("Size"),
    "sort": MessageLookupByLibrary.simpleMessage("Sort"),
    "sortByDate": MessageLookupByLibrary.simpleMessage("Date Modified"),
    "sortByName": MessageLookupByLibrary.simpleMessage("Name"),
    "sortBySize": MessageLookupByLibrary.simpleMessage("Size"),
    "sortByType": MessageLookupByLibrary.simpleMessage("Type"),
    "standbyBucket": MessageLookupByLibrary.simpleMessage("Standby bucket"),
    "startDownload": m57,
    "startDownloadFile": m58,
    "startServer": MessageLookupByLibrary.simpleMessage("Start server"),
    "startServerToAcceptConnections": MessageLookupByLibrary.simpleMessage(
      "Start server to accept connections",
    ),
    "startTime": MessageLookupByLibrary.simpleMessage("Start time"),
    "startWebBrowser": MessageLookupByLibrary.simpleMessage(
      "Start web browser",
    ),
    "status": MessageLookupByLibrary.simpleMessage("Status"),
    "stopServer": MessageLookupByLibrary.simpleMessage("Stop server"),
    "stopServerMessage": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to stop the server?",
    ),
    "stopServerTitle": MessageLookupByLibrary.simpleMessage("Stop Server"),
    "stopWebBrowser": MessageLookupByLibrary.simpleMessage("Stop"),
    "stopped": MessageLookupByLibrary.simpleMessage("Stopped"),
    "storage": MessageLookupByLibrary.simpleMessage("Storage"),
    "storageActions": MessageLookupByLibrary.simpleMessage("Storage Actions"),
    "storageDeleted": MessageLookupByLibrary.simpleMessage("Storage deleted"),
    "storageDisabled": MessageLookupByLibrary.simpleMessage("Disabled"),
    "storageManagement": MessageLookupByLibrary.simpleMessage(
      "Storage Management",
    ),
    "storageManagementDesc": MessageLookupByLibrary.simpleMessage(
      "Configure storage backends",
    ),
    "storageToggled": m59,
    "storages": MessageLookupByLibrary.simpleMessage("Storages"),
    "success": MessageLookupByLibrary.simpleMessage("Success"),
    "systemDefault": MessageLookupByLibrary.simpleMessage("System Default"),
    "taskDone": MessageLookupByLibrary.simpleMessage("Finished"),
    "taskGroupCopy": MessageLookupByLibrary.simpleMessage("Copy"),
    "taskGroupDecompress": MessageLookupByLibrary.simpleMessage("Decompress"),
    "taskGroupDecompressUpload": MessageLookupByLibrary.simpleMessage(
      "Decompress upload",
    ),
    "taskGroupMove": MessageLookupByLibrary.simpleMessage("Move"),
    "taskGroupOfflineDownload": MessageLookupByLibrary.simpleMessage(
      "Offline download",
    ),
    "taskGroupTransfer": MessageLookupByLibrary.simpleMessage(
      "Offline transfer",
    ),
    "taskGroupUpload": MessageLookupByLibrary.simpleMessage("Upload"),
    "taskUndone": MessageLookupByLibrary.simpleMessage("Active"),
    "tasks": MessageLookupByLibrary.simpleMessage("Tasks"),
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
    "theme": MessageLookupByLibrary.simpleMessage("Theme"),
    "themeDark": MessageLookupByLibrary.simpleMessage("Dark"),
    "themeLight": MessageLookupByLibrary.simpleMessage("Light"),
    "themeSystem": MessageLookupByLibrary.simpleMessage("System Default"),
    "tlsCertificate": MessageLookupByLibrary.simpleMessage("HTTPS certificate"),
    "tlsCertificates": MessageLookupByLibrary.simpleMessage("TLS Certificates"),
    "tlsCertificatesDesc": MessageLookupByLibrary.simpleMessage(
      "Manage SSL/TLS certificates",
    ),
    "tlsNeedsCert": MessageLookupByLibrary.simpleMessage(
      "HTTPS needs both a certificate and a private key",
    ),
    "transfers": MessageLookupByLibrary.simpleMessage("Transfers"),
    "troubleshooting": MessageLookupByLibrary.simpleMessage("Troubleshooting"),
    "troubleshootingDesc": MessageLookupByLibrary.simpleMessage(
      "Common issues and solutions",
    ),
    "tryToOpenFile": m60,
    "uiSettings": MessageLookupByLibrary.simpleMessage("UI"),
    "upload": MessageLookupByLibrary.simpleMessage("Upload"),
    "uploadCanceled": MessageLookupByLibrary.simpleMessage("Canceled"),
    "uploadDone": MessageLookupByLibrary.simpleMessage("Upload complete"),
    "uploadFailed": MessageLookupByLibrary.simpleMessage("Upload failed"),
    "uploadFailedState": MessageLookupByLibrary.simpleMessage("Failed"),
    "uploadFiles": MessageLookupByLibrary.simpleMessage("Upload Files"),
    "uploadFilesFromFilesScreen": MessageLookupByLibrary.simpleMessage(
      "Upload files from the Files screen",
    ),
    "uploadFilesOrCreateFolder": MessageLookupByLibrary.simpleMessage(
      "Upload files or create a new folder",
    ),
    "uploadFunctionalityComingSoon": MessageLookupByLibrary.simpleMessage(
      "Upload functionality coming soon",
    ),
    "uploadPhotos": MessageLookupByLibrary.simpleMessage("Upload Photos"),
    "uploadQueued": MessageLookupByLibrary.simpleMessage("Queued"),
    "uploadRunning": MessageLookupByLibrary.simpleMessage("Uploading"),
    "uploadSucceeded": MessageLookupByLibrary.simpleMessage("Done"),
    "uploadVideos": MessageLookupByLibrary.simpleMessage("Upload Videos"),
    "uploading": MessageLookupByLibrary.simpleMessage("Uploading..."),
    "uploadingFile": m61,
    "uploads": MessageLookupByLibrary.simpleMessage("Uploads"),
    "uploadsActive": m62,
    "uploadsKeepAppAlive": MessageLookupByLibrary.simpleMessage(
      "Uploads continue while the app process is alive; closing the app from recents stops them.",
    ),
    "uptime": MessageLookupByLibrary.simpleMessage("Uptime"),
    "user": MessageLookupByLibrary.simpleMessage("User"),
    "userCancelledDownload": MessageLookupByLibrary.simpleMessage(
      "User cancelled download",
    ),
    "userCancelledDownloadError": MessageLookupByLibrary.simpleMessage(
      "User cancelled download",
    ),
    "userDisabled": MessageLookupByLibrary.simpleMessage("Disabled"),
    "userManagement": MessageLookupByLibrary.simpleMessage("User Management"),
    "userManagementDesc": MessageLookupByLibrary.simpleMessage(
      "Manage users and permissions",
    ),
    "username": MessageLookupByLibrary.simpleMessage("Username"),
    "users": MessageLookupByLibrary.simpleMessage("Users"),
    "version": MessageLookupByLibrary.simpleMessage("Version"),
    "videos": MessageLookupByLibrary.simpleMessage("Videos"),
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
    "waiting": MessageLookupByLibrary.simpleMessage("Waiting"),
    "wakeLock": MessageLookupByLibrary.simpleMessage("Wake lock"),
    "wakeLockDesc": MessageLookupByLibrary.simpleMessage(
      "Prevent CPU from sleeping when screen is off. (May cause app killed in background on some devices)",
    ),
    "webBrowserDownloadInProgress": MessageLookupByLibrary.simpleMessage(
      "The browser cannot stop while a download is in progress",
    ),
    "webBrowserStatus": MessageLookupByLibrary.simpleMessage(
      "Embedded web browser",
    ),
    "webBrowserStopped": MessageLookupByLibrary.simpleMessage(
      "The embedded web browser is stopped",
    ),
    "webPage": MessageLookupByLibrary.simpleMessage("Web Page"),
  };
}
