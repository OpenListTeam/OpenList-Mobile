import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openlist_mobile/generated/l10n.dart';
import 'package:openlist_mobile/pages/native/common.dart';
import 'package:openlist_mobile/pages/native/file_preview_page.dart';
import 'package:openlist_mobile/utils/recent_files.dart';
import 'package:openlist_mobile/widgets/file_items.dart';

class RecentFilesPage extends StatefulWidget {
  const RecentFilesPage({super.key});

  @override
  State<RecentFilesPage> createState() => _RecentFilesPageState();
}

class _RecentFilesPageState extends State<RecentFilesPage> {
  List<RecentFile> _files = const [];
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _files = await RecentFiles.list();
    } catch (error) {
      _error = error;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.current.recentFiles)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? StateMessage(
              icon: Icons.error_outline,
              text: errorText(_error!),
              action: S.current.retry,
              onAction: _load,
            )
          : _files.isEmpty
          ? StateMessage(icon: Icons.history, text: S.current.noRecentFiles)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                itemCount: _files.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final file = _files[index];
                  return FileListItem(
                    name: file.name,
                    isDirectory: false,
                    size: file.size,
                    onTap: () => Get.to(() => FilePreviewPage(path: file.path)),
                  );
                },
              ),
            ),
    );
  }
}
