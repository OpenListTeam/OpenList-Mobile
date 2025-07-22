import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'download_manager.dart';

/// 下载功能使用示例
class DownloadExamples {
  
  /// 示例1: 简单文件下载
  static Future<void> downloadSimpleFile() async {
    await DownloadManager.downloadFileInBackground(
      url: 'https://example.com/document.pdf',
      filename: 'my_document.pdf',
    );
  }

  /// 示例2: 带进度的下载
  static Future<void> downloadWithProgress() async {
    await DownloadManager.downloadFileWithProgress(
      url: 'https://example.com/large_file.zip',
      filename: 'large_file.zip',
    );
  }

  /// 示例3: 自定义进度回调
  static Future<void> downloadWithCustomProgress() async {
    await DownloadManager.downloadFileWithProgress(
      url: 'https://example.com/video.mp4',
      filename: 'video.mp4',
    );
  }

  /// 示例4: 批量下载
  static Future<void> downloadMultipleFiles(List<String> urls) async {
    for (int i = 0; i < urls.length; i++) {
      String url = urls[i];
      String filename = 'file_${i + 1}_${DateTime.now().millisecondsSinceEpoch}';
      
      Get.showSnackbar(GetSnackBar(
        message: '正在下载第 ${i + 1}/${urls.length} 个文件',
        duration: Duration(seconds: 2),
      ));
      
      bool success = await DownloadManager.downloadFileInBackground(
        url: url,
        filename: filename,
      );
      
      if (!success) {
        Get.showSnackbar(GetSnackBar(
          message: '第 ${i + 1} 个文件下载失败',
          duration: Duration(seconds: 3),
        ));
        break;
      }
    }
    
    Get.showSnackbar(GetSnackBar(
      message: '批量下载完成',
      duration: Duration(seconds: 3),
    ));
  }

  /// 示例5: 下载并显示自定义对话框
  static Future<void> downloadWithCustomDialog(BuildContext context) async {
    // 显示确认对话框
    bool? shouldDownload = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认下载'),
        content: Text('是否要下载这个文件？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('下载'),
          ),
        ],
      ),
    );

    if (shouldDownload == true) {
      await DownloadManager.downloadFileWithProgress(
        url: 'https://example.com/important_file.pdf',
        filename: 'important_file.pdf',
      );
    }
  }

  /// 示例6: 下载图片并显示预览
  static Future<void> downloadImageWithPreview(String imageUrl) async {
    // 先显示加载提示
    Get.dialog(
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在下载图片...'),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    bool success = await DownloadManager.downloadFileInBackground(
      url: imageUrl,
      filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    Get.back(); // 关闭加载对话框

    if (success) {
      Get.showSnackbar(GetSnackBar(
        message: '图片下载成功',
        duration: Duration(seconds: 3),
        mainButton: TextButton(
          onPressed: () {
            // 可以在这里添加打开图片的逻辑
            Get.showSnackbar(GetSnackBar(
              message: '请在下载目录查看图片',
              duration: Duration(seconds: 2),
            ));
          },
          child: Text('查看'),
        ),
      ));
    }
  }

  /// 示例7: 下载APK并提示安装
  static Future<void> downloadApkAndInstall(String apkUrl, String version) async {
    bool success = await DownloadManager.downloadFileWithProgress(
      url: apkUrl,
      filename: 'app_update_v$version.apk',
    );

    if (success) {
      Get.dialog(
        AlertDialog(
          title: Text('下载完成'),
          content: Text('APK文件已下载完成，是否要安装？'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('稍后安装'),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                // 这里可以添加安装APK的逻辑
                Get.showSnackbar(GetSnackBar(
                  message: '请在下载目录找到APK文件进行安装',
                  duration: Duration(seconds: 5),
                ));
              },
              child: Text('立即安装'),
            ),
          ],
        ),
      );
    }
  }
}

/// 下载工具类 - 提供一些便捷方法
class DownloadUtils {
  
  /// 检查URL是否为下载链接
  static bool isDownloadUrl(String url) {
    final downloadExtensions = [
      '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
      '.zip', '.rar', '.7z', '.tar', '.gz',
      '.mp3', '.mp4', '.avi', '.mkv', '.mov',
      '.jpg', '.jpeg', '.png', '.gif', '.bmp',
      '.apk', '.exe', '.dmg', '.deb', '.rpm'
    ];
    
    String lowerUrl = url.toLowerCase();
    return downloadExtensions.any((ext) => lowerUrl.contains(ext));
  }

  /// 从URL获取文件扩展名
  static String getFileExtension(String url) {
    try {
      Uri uri = Uri.parse(url);
      String path = uri.path;
      if (path.contains('.')) {
        return path.split('.').last.toLowerCase();
      }
    } catch (e) {
      print('获取文件扩展名失败: $e');
    }
    return '';
  }

  /// 格式化文件大小
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// 显示下载选择对话框
  static void showDownloadOptions(BuildContext context, String url, {String? filename}) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '选择下载方式',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.download),
              title: Text('直接下载'),
              subtitle: Text('使用应用内下载器'),
              onTap: () {
                Navigator.pop(context);
                DownloadManager.downloadFileWithProgress(
                  url: url,
                  filename: filename,
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.open_in_browser),
              title: Text('浏览器下载'),
              subtitle: Text('使用系统浏览器'),
              onTap: () {
                Navigator.pop(context);
                // 这里可以调用原有的Intent方式
              },
            ),
            ListTile(
              leading: Icon(Icons.share),
              title: Text('分享链接'),
              subtitle: Text('分享下载链接'),
              onTap: () {
                Navigator.pop(context);
                // 这里可以添加分享功能
              },
            ),
          ],
        ),
      ),
    );
  }
}