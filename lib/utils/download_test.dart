import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'download_manager.dart';
import '../generated/l10n.dart';

/// 下载功能测试页面
class DownloadTestPage extends StatelessWidget {
  const DownloadTestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.current.downloadFunctionTest),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              S.current.testDirectDownloadFunction,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // 测试下载一个小文件
                await DownloadManager.downloadFileWithProgress(
                  url: 'https://httpbin.org/json',
                  filename: 'test.json',
                );
              },
              child: Text(S.current.testDownloadJsonFile),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                // 测试下载图片
                await DownloadManager.downloadFileWithProgress(
                  url: 'https://httpbin.org/image/png',
                  filename: 'test_image.png',
                );
              },
              child: Text(S.current.testDownloadPngImage),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                // 测试下载较大文件
                await DownloadManager.downloadFileWithProgress(
                  url: 'https://httpbin.org/drip?duration=5&numbytes=1024000',
                  filename: 'large_test.bin',
                );
              },
              child: Text(S.current.testDownloadLargeFile),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // 提示用户通过底部导航栏查看下载文件
                Get.showSnackbar(GetSnackBar(
                  message: S.current.checkDownloadManagerForFiles,
                  duration: const Duration(seconds: 2),
                ));
              },
              child: Text(S.current.viewDownloadFiles),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                // 显示下载目录路径
                String? path = await DownloadManager.getDownloadDirectoryPath();
                Get.dialog(
                  AlertDialog(
                    title: Text(S.current.downloadDirectory),
                    content: SelectableText(path ?? S.current.getDownloadPathFailed),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text(S.current.ok),
                      ),
                    ],
                  ),
                );
              },
              child: Text(S.current.viewDownloadDirectory),
            ),
            const SizedBox(height: 20),
            Text(
              S.current.description,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              S.current.downloadInstructions,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// 在主应用中添加测试入口的辅助方法
class DownloadTestHelper {
  static void showTestDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text(S.current.downloadFunctionTest),
        content: Text(S.current.openDownloadTestPage),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(S.current.cancel),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.to(() => const DownloadTestPage());
            },
            child: Text(S.current.ok),
          ),
        ],
      ),
    );
  }
}