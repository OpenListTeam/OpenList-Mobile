import 'package:android_intent_plus/android_intent.dart';

class IntentUtils {
  static AndroidIntent getUrlIntent(String url) {
    return AndroidIntent(action: "action_view", data: url);
  }

  /// Create an Intent to open file manager for a specific directory
  static AndroidIntent getFileManagerIntent(String directoryPath) {
    return AndroidIntent(
      action: "action_view",
      data: "file://$directoryPath",
      type: "resource/folder",
    );
  }

  /// Create an Intent to show file in file manager
  static AndroidIntent getShowFileInManagerIntent(String filePath) {
    return AndroidIntent(
      action: "action_view",
      data: "file://$filePath",
      type: _getMimeTypeFromPath(filePath),
    );
  }

  /// Get MIME type from file path
  static String _getMimeTypeFromPath(String filePath) {
    String extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'apk':
        return 'application/vnd.android.package-archive';
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }

  /// Create Intent for Huawei file manager
  static AndroidIntent getHuaweiFileManagerIntent(String directoryPath) {
    return AndroidIntent(
      package: 'com.huawei.hidisk',
      action: 'action_view',
      data: "file://$directoryPath",
    );
  }

  /// Create Intent for Xiaomi file manager
  static AndroidIntent getXiaomiFileManagerIntent(String directoryPath) {
    return AndroidIntent(
      package: 'com.mi.android.globalFileexplorer',
      action: 'action_view', 
      data: "file://$directoryPath",
    );
  }

  /// Create Intent for OPPO file manager
  static AndroidIntent getOppoFileManagerIntent(String directoryPath) {
    return AndroidIntent(
      package: 'com.coloros.filemanager',
      action: 'action_view',
      data: "file://$directoryPath",
    );
  }

  /// Create Intent for Vivo file manager
  static AndroidIntent getVivoFileManagerIntent(String directoryPath) {
    return AndroidIntent(
      package: 'com.vivo.filemanager',
      action: 'action_view',
      data: "file://$directoryPath",
    );
  }

  /// Create Intent for Samsung file manager
  static AndroidIntent getSamsungFileManagerIntent(String directoryPath) {
    return AndroidIntent(
      package: 'com.sec.android.app.myfiles',
      action: 'action_view',
      data: "file://$directoryPath",
    );
  }

  /// Create Intent for ES File Explorer
  static AndroidIntent getESFileExplorerIntent(String directoryPath) {
    return AndroidIntent(
      package: 'com.estrongs.android.pop',
      action: 'action_view',
      data: "file://$directoryPath",
    );
  }

  /// Create Intent for Solid Explorer
  static AndroidIntent getSolidExplorerIntent(String directoryPath) {
    return AndroidIntent(
      package: 'pl.solidexplorer2',
      action: 'action_view',
      data: "file://$directoryPath",
    );
  }

  /// Get all supported vendor file manager Intent options
  static List<Map<String, dynamic>> getAllFileManagerIntents(String directoryPath) {
    return [
      {
        'name': '系统默认',
        'icon': '📁',
        'intent': getFileManagerIntent(directoryPath),
        'isDefault': true,
      },
      {
        'name': '华为文件管理',
        'icon': '🇨🇳',
        'intent': getHuaweiFileManagerIntent(directoryPath),
        'isDefault': false,
      },
      {
        'name': '小米文件管理',
        'icon': '🇨🇳', 
        'intent': getXiaomiFileManagerIntent(directoryPath),
        'isDefault': false,
      },
      {
        'name': 'OPPO文件管理',
        'icon': '🇨🇳',
        'intent': getOppoFileManagerIntent(directoryPath),
        'isDefault': false,
      },
      {
        'name': 'Vivo文件管理',
        'icon': '🇨🇳',
        'intent': getVivoFileManagerIntent(directoryPath),
        'isDefault': false,
      },
      {
        'name': '三星文件管理',
        'icon': '🇰🇷',
        'intent': getSamsungFileManagerIntent(directoryPath),
        'isDefault': false,
      },
      {
        'name': 'ES文件浏览器',
        'icon': '📂',
        'intent': getESFileExplorerIntent(directoryPath),
        'isDefault': false,
      },
      {
        'name': 'Solid Explorer',
        'icon': '📱',
        'intent': getSolidExplorerIntent(directoryPath),
        'isDefault': false,
      },
    ];
  }

  /// Get generic file manager Intent (let system choose)
  static AndroidIntent getGenericFileManagerIntent(String directoryPath) {
    return AndroidIntent(
      action: "action_view",
      data: "file://$directoryPath",
    );
  }
}
