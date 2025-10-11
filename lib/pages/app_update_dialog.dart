import 'package:flutter/material.dart';

import '../generated/l10n.dart';
import '../utils/update_checker.dart';
import '../utils/intent_utils.dart';
import '../utils/download_manager.dart';

class AppUpdateDialog extends StatelessWidget {
  final String content;
  final String apkUrl;
  final String htmlUrl;
  final String version;

  const AppUpdateDialog(
      {super.key,
      required this.content,
      required this.apkUrl,
      required this.version,
      required this.htmlUrl});

  static checkUpdateAndShowDialog(
      BuildContext context, ValueChanged<bool>? checkFinished) async {
    final checker = UpdateChecker(owner: "openlistteam", repo: "OpenList-Mobile");
    await checker.downloadData();
    final hasNewVersion = await checker.hasNewVersion();
    
    checkFinished?.call(hasNewVersion);
    
    if (hasNewVersion) {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (context) {
          return AppUpdateDialog(
            content: checker.getUpdateContent(),
            apkUrl: checker.getApkDownloadUrl(),
            htmlUrl: checker.getHtmlUrl(),
            version: checker.getTag(),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.system_update,
            color: theme.colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(S.of(context).newVersionFound),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                version,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  content,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            Text(
              S.of(context).selectDownloadMethod,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(
                  Icons.download,
                  color: theme.colorScheme.primary,
                ),
                title: Text(S.of(context).directDownloadApk),
                subtitle: Text(S.of(context).directDownloadMethodDesc),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(context);
                  DownloadManager.downloadFileInBackground(
                    url: apkUrl,
                    filename: 'OpenList_$version.apk',
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(
                  Icons.open_in_browser,
                  color: theme.colorScheme.secondary,
                ),
                title: Text(S.of(context).downloadApk),
                subtitle: Text(S.of(context).browserDownloadMethodDesc),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  IntentUtils.getUrlIntent(apkUrl)
                      .launchChooser(S.of(context).downloadApk);
                },
              ),
            ),
            const SizedBox(height: 8),

            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(
                  Icons.article_outlined,
                  color: theme.colorScheme.tertiary,
                ),
                title: Text(S.of(context).releasePage),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  IntentUtils.getUrlIntent(htmlUrl)
                      .launchChooser(S.of(context).releasePage);
                },
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(S.of(context).cancel),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
