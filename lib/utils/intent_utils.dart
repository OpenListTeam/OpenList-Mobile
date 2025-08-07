import 'package:android_intent_plus/android_intent.dart';

class IntentUtils {
  static AndroidIntent getUrlIntent(String url) {
    return AndroidIntent(action: "action_view", data: url);
  }

  /// Create an Intent to open file manager for a specific directory
  static AndroidIntent getFileManagerIntent(String directoryPath) {
    return AndroidIntent(
      action: "action_main",
      category: "android.intent.category.APP_FILES",
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

  /// Get generic file manager Intent (let system choose)
  static AndroidIntent getGenericFileManagerIntent(String directoryPath) {
    return AndroidIntent(
      action: "action_get_content",
      type: "*/*",
      arguments: {
        'android.intent.extra.LOCAL_ONLY': true,
        'android.intent.extra.ALLOW_MULTIPLE': false,
      },
    );
  }
}
