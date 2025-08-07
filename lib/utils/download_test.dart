import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'download_manager.dart';

/// 下载功能测试页面
class DownloadTestPage extends StatelessWidget {
  const DownloadTestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('下载功能测试'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '测试直接下载功能',
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
              child: const Text('测试下载JSON文件'),
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
              child: const Text('测试下载PNG图片'),
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
              child: const Text('测试下载大文件(1MB)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // 提示用户通过底部导航栏查看下载文件
                Get.showSnackbar(const GetSnackBar(
                  message: '请通过底部导航栏的"下载管理"查看下载文件',
                  duration: Duration(seconds: 2),
                ));
              },
              child: const Text('查看下载文件'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                // 显示下载目录路径
                String? path = await DownloadManager.getDownloadDirectoryPath();
                Get.dialog(
                  AlertDialog(
                    title: const Text('下载目录'),
                    content: SelectableText(path ?? '获取失败'),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('确定'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('查看下载目录'),
            ),
            const SizedBox(height: 20),
            Text(
              '说明：',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '• 文件将下载到系统下载目录\n'
              '• 下载过程会显示进度通知\n'
              '• 下载完成后可以选择打开文件\n'
              '• 如果文件名重复会自动添加序号\n'
              '• 请通过底部导航栏的"下载管理"查看下载文件\n'
              '• 新增：支持厂商定制文件管理器选择',
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
        title: const Text('下载功能测试'),
        content: const Text('是否要打开下载测试页面？'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.to(() => const DownloadTestPage());
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}