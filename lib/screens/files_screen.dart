import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openlist_mobile/api/models.dart';
import 'package:openlist_mobile/api/native_upload.dart';
import 'package:openlist_mobile/api/openlist_client.dart';
import 'package:openlist_mobile/api/session.dart';
import 'package:openlist_mobile/api/upload_queue.dart';
import 'package:openlist_mobile/design/theme.dart';
import 'package:openlist_mobile/generated/l10n.dart';
import 'package:openlist_mobile/pages/native/file_preview_page.dart';
import 'package:openlist_mobile/pages/native/folder_picker_page.dart';
import 'package:openlist_mobile/pages/native/search_page.dart';
import 'package:openlist_mobile/widgets/file_items.dart';

/// Files browser screen with list/grid view modes
class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final _controller = Get.put(_FilesController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Obx(() {
          // Show back button when not at root
          if (_controller.currentPath.value != '/') {
            return IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _controller.navigateUp,
            );
          }
          // Return empty SizedBox when at root
          return const SizedBox.shrink();
        }),
        automaticallyImplyLeading: _controller.currentPath.value != '/',
        title: Obx(() => _Breadcrumb(path: _controller.currentPath.value)),
        actions: [
          Obx(() => IconButton(
                icon: Icon(_controller.viewMode.value == _ViewMode.list
                    ? Icons.grid_view
                    : Icons.view_list),
                onPressed: _controller.toggleViewMode,
              )),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              // Navigate to search and handle result
              final result = await Get.to<String>(
                () => SearchPage(parent: _controller.currentPath.value),
              );
              // If a folder was selected from search, navigate to it
              if (result != null) {
                _controller.currentPath.value = result;
                await _controller.loadFiles();
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'sort':
                  _showSortOptions();
                  break;
                case 'refresh':
                  _controller.loadFiles();
                  break;
                case 'newfolder':
                  _showCreateFolderDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'sort', child: Text(S.current.sort)),
              PopupMenuItem(value: 'refresh', child: Text(S.current.refresh)),
              PopupMenuItem(value: 'newfolder', child: Text(S.current.newFolder)),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (_controller.isLoading.value && _controller.files.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_controller.error.value.isNotEmpty) {
          return _ErrorView(
            message: _controller.error.value,
            onRetry: _controller.loadFiles,
            onConnect: _controller.handleConnect,
          );
        }

        if (_controller.files.isEmpty) {
          return _EmptyView(
            onCreateFolder: _showCreateFolderDialog,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await _controller.loadFiles();
          },
          child: _controller.viewMode.value == _ViewMode.list
              ? _ListView(controller: _controller)
              : _GridView(controller: _controller),
        );
      }),
      floatingActionButton: Obx(() {
        if (_controller.selectedFiles.isNotEmpty) {
          return _BatchActionBar(controller: _controller);
        }
        return FloatingActionButton(
          onPressed: _showUploadOptions,
          child: const Icon(Icons.add),
        );
      }),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _SortOptionsSheet(
        currentSort: _controller.sortBy.value,
        onSelected: (sort) {
          _controller.setSortBy(sort);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showCreateFolderDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.current.newFolder),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: S.current.folderName,
            hintText: S.current.enterFolderName,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.current.cancel),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                _controller.createFolder(name);
                Navigator.pop(context);
              }
            },
            child: Text(S.current.create),
          ),
        ],
      ),
    );
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: AppDesign.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(S.current.uploadPhotos),
              onTap: () {
                Navigator.pop(context);
                _controller.pickAndUploadFiles(FilePickType.image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: Text(S.current.uploadVideos),
              onTap: () {
                Navigator.pop(context);
                _controller.pickAndUploadFiles(FilePickType.video);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: Text(S.current.uploadFiles),
              onTap: () {
                Navigator.pop(context);
                _controller.pickAndUploadFiles(FilePickType.any);
              },
            ),
            ListTile(
              leading: const Icon(Icons.create_new_folder),
              title: Text(S.current.newFolder),
              onTap: () {
                Navigator.pop(context);
                _showCreateFolderDialog();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();

    if (parts.isEmpty) {
      return Text(S.current.files);
    }

    return Text(
      parts.last,
      style: AppDesign.headline3.copyWith(fontSize: 18),
    );
  }
}

class _ListView extends StatelessWidget {
  const _ListView({required this.controller});

  final _FilesController controller;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: controller.files.length,
      itemBuilder: (context, index) {
        final file = controller.files[index];
        final isSelected = controller.selectedFiles.contains(file.name);

        return FileListItem(
          name: file.name,
          isDirectory: file.isDir,
          size: file.size,
          modified: file.modified,
          thumbnail: file.thumb,
          selected: isSelected,
          onTap: () => controller.onFileTap(file),
          onLongPress: () => controller.toggleSelection(file.name),
        );
      },
    );
  }
}

class _GridView extends StatelessWidget {
  const _GridView({required this.controller});

  final _FilesController controller;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppDesign.space16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: AppDesign.space12,
        mainAxisSpacing: AppDesign.space12,
      ),
      itemCount: controller.files.length,
      itemBuilder: (context, index) {
        final file = controller.files[index];
        final isSelected = controller.selectedFiles.contains(file.name);

        return FileGridItem(
          name: file.name,
          isDirectory: file.isDir,
          thumbnail: file.thumb,
          selected: isSelected,
          onTap: () => controller.onFileTap(file),
          onLongPress: () => controller.toggleSelection(file.name),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.onConnect,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final isConnectionError = message.contains('not connected') ||
                              message.contains('not running') ||
                              message.contains('Connection refused');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesign.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isConnectionError ? Icons.cloud_off : Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppDesign.space24),
            Text(
              isConnectionError ? S.current.notConnected : S.current.failedToLoadFiles,
              style: AppDesign.headline3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDesign.space12),
            Text(
              message,
              style: AppDesign.body2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDesign.space24),
            if (isConnectionError) ...[
              ElevatedButton.icon(
                onPressed: onConnect,
                icon: const Icon(Icons.refresh),
                label: Text(S.current.connectToServer),
              ),
              const SizedBox(height: AppDesign.space12),
            ],
            OutlinedButton(
              onPressed: onRetry,
              child: Text(S.current.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onCreateFolder});

  final VoidCallback onCreateFolder;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesign.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppDesign.space24),
            Text(
              S.current.noFilesHere,
              style: AppDesign.headline3,
            ),
            const SizedBox(height: AppDesign.space12),
            Text(
              S.current.uploadFilesOrCreateFolder,
              style: AppDesign.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchActionBar extends StatelessWidget {
  const _BatchActionBar({required this.controller});

  final _FilesController controller;

  @override
  Widget build(BuildContext context) {
    final count = controller.selectedFiles.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDesign.space16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            S.current.selectedCount(count),
            style: AppDesign.body1.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.drive_file_move),
            onPressed: controller.moveSelected,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: controller.copySelected,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: controller.deleteSelected,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: controller.clearSelection,
          ),
        ],
      ),
    );
  }
}

class _SortOptionsSheet extends StatelessWidget {
  const _SortOptionsSheet({
    required this.currentSort,
    required this.onSelected,
  });

  final String currentSort;
  final Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppDesign.space24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SortOption(
            title: S.current.sortByName,
            selected: currentSort == 'name',
            onTap: () => onSelected('name'),
          ),
          _SortOption(
            title: S.current.sortByDate,
            selected: currentSort == 'date',
            onTap: () => onSelected('date'),
          ),
          _SortOption(
            title: S.current.sortBySize,
            selected: currentSort == 'size',
            onTap: () => onSelected('size'),
          ),
          _SortOption(
            title: S.current.sortByType,
            selected: currentSort == 'type',
            onTap: () => onSelected('type'),
          ),
        ],
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: selected ? const Icon(Icons.check) : null,
      onTap: onTap,
    );
  }
}

enum _ViewMode { list, grid }
enum FilePickType { image, video, any }

class _FilesController extends GetxController {
  final _session = OpenListSession.instance;

  final currentPath = '/'.obs;
  final files = <FsObject>[].obs;
  final selectedFiles = <String>[].obs;
  final isLoading = false.obs;
  final error = ''.obs;
  final viewMode = _ViewMode.list.obs;
  final sortBy = 'name'.obs;

  @override
  void onInit() {
    super.onInit();
    loadFiles();
  }

  Future<void> loadFiles() async {
    isLoading.value = true;
    error.value = '';

    try {
      // Try to connect if not connected
      if (!_session.isConnected) {
        await _session.connectLocal();
      }

      final result = await _session.fs.list(currentPath.value);
      files.value = result.content;
      _sortFiles();
    } catch (e) {
      error.value = e.toString();
      debugPrint('Failed to load files: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void toggleViewMode() {
    viewMode.value = viewMode.value == _ViewMode.list
        ? _ViewMode.grid
        : _ViewMode.list;
  }

  void setSortBy(String sort) {
    sortBy.value = sort;
    _sortFiles();
  }

  void _sortFiles() {
    files.sort((a, b) {
      // Directories first
      if (a.isDir && !b.isDir) return -1;
      if (!a.isDir && b.isDir) return 1;

      switch (sortBy.value) {
        case 'date':
          final aTime = a.modified ?? DateTime(2000);
          final bTime = b.modified ?? DateTime(2000);
          return bTime.compareTo(aTime);
        case 'size':
          return b.size.compareTo(a.size);
        case 'type':
          final aExt = a.name.split('.').last;
          final bExt = b.name.split('.').last;
          final extCompare = aExt.compareTo(bExt);
          return extCompare != 0 ? extCompare : a.name.compareTo(b.name);
        default:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
    });
    files.refresh();
  }

  void onFileTap(FsObject file) {
    if (selectedFiles.isNotEmpty) {
      toggleSelection(file.name);
      return;
    }

    if (file.isDir) {
      navigateToFolder(file.name);
    } else {
      // Open file preview
      final filePath = currentPath.value == '/'
          ? '/${file.name}'
          : '${currentPath.value}/${file.name}';
      Get.to(() => FilePreviewPage(path: filePath));
    }
  }

  void navigateToFolder(String folderName) {
    final newPath = currentPath.value == '/'
        ? '/$folderName'
        : '${currentPath.value}/$folderName';
    currentPath.value = newPath;
    loadFiles();
  }

  void navigateUp() {
    if (currentPath.value == '/') return;

    final parts = currentPath.value.split('/');
    parts.removeLast();
    currentPath.value = parts.isEmpty || parts.length == 1 ? '/' : parts.join('/');
    loadFiles();
  }

  void toggleSelection(String fileName) {
    if (selectedFiles.contains(fileName)) {
      selectedFiles.remove(fileName);
    } else {
      selectedFiles.add(fileName);
    }
  }

  void clearSelection() {
    selectedFiles.clear();
  }

  Future<void> createFolder(String name) async {
    try {
      final path = currentPath.value == '/' ? '/$name' : '${currentPath.value}/$name';
      await _session.fs.mkdir(path);
      await loadFiles();
    } catch (e) {
      Get.snackbar(S.current.error, S.current.failedToCreateFolder(e.toString()));
    }
  }

  Future<void> pickAndUploadFiles(FilePickType type) async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: switch (type) {
          FilePickType.image => FileType.image,
          FilePickType.video => FileType.video,
          FilePickType.any => FileType.any,
        },
      );

      if (picked == null || picked.files.isEmpty) {
        return;
      }

      final dir = currentPath.value;
      final fs = _session.fs;

      // Queue upload jobs for each selected file
      UploadQueue.instance.addAll([
        for (final f in picked.files)
          if (f.path != null)
            UploadJob(
              name: f.name,
              dir: dir,
              size: f.size,
              run: (token, onProgress) {
                final dstPath = OpenListClient.join(dir, f.name);
                return NativeUploader.instance.upload(
                  fs.client,
                  filePath: f.path!,
                  dstPath: dstPath,
                  title: f.name,
                  dir: dir,
                  size: f.size,
                  password: '',
                  onProgress: onProgress,
                  cancelToken: token,
                  fallback: () async {
                    final file = File(f.path!);
                    await fs.upload(
                      dstPath,
                      file.openRead(),
                      await file.length(),
                      password: '',
                      onProgress: onProgress,
                      cancelToken: token,
                    );
                  },
                );
              },
            ),
      ]);

      Get.snackbar(S.current.info,
          '${S.current.uploading} ${picked.files.length} ${S.current.files}');
    } catch (e) {
      Get.snackbar(S.current.error, S.current.uploadFailed);
      debugPrint('File picker failed: $e');
    }
  }

  Future<void> deleteSelected() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(S.current.deleteFiles),
        content: Text(S.current.deleteItemsConfirm(selectedFiles.length)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(S.current.cancel),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text(S.current.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _session.fs.remove(currentPath.value, selectedFiles.toList());
      clearSelection();
      await loadFiles();
    } catch (e) {
      Get.snackbar(S.current.error, S.current.failedToDelete(e.toString()));
    }
  }

  Future<void> moveSelected() async {
    final srcDir = currentPath.value;
    try {
      // Show folder picker for destination
      final dstDir = await Get.to<String>(
        () => FolderPickerPage(
          title: S.current.moveTo,
          initial: srcDir,
        ),
      );

      if (dstDir == null || dstDir == srcDir) {
        return;
      }

      // Show operation indicator
      Get.snackbar(S.current.info, S.current.moving);

      // Perform the move operation
      await _session.fs.move(srcDir, dstDir, selectedFiles.toList());

      // Clear selection and reload
      clearSelection();
      await loadFiles();

      Get.snackbar(S.current.success, S.current.operationDone);
    } catch (e) {
      Get.snackbar(S.current.error, S.current.failedToMove(e.toString()));
      debugPrint('Move failed: $e');
    }
  }

  Future<void> copySelected() async {
    final srcDir = currentPath.value;
    try {
      // Show folder picker for destination
      final dstDir = await Get.to<String>(
        () => FolderPickerPage(
          title: S.current.copyTo,
          initial: srcDir,
        ),
      );

      if (dstDir == null) {
        return;
      }

      // Show operation indicator
      Get.snackbar(S.current.info, S.current.copying);

      // Perform the copy operation
      await _session.fs.copy(srcDir, dstDir, selectedFiles.toList());

      // Clear selection and reload (copying doesn't remove from source)
      clearSelection();
      await loadFiles();

      Get.snackbar(S.current.success, S.current.operationDone);
    } catch (e) {
      Get.snackbar(S.current.error, S.current.failedToCopy(e.toString()));
      debugPrint('Copy failed: $e');
    }
  }

  Future<void> handleConnect() async {
    try {
      isLoading.value = true;
      error.value = '';

      await _session.connectLocal();
      await loadFiles();

      Get.snackbar(S.current.success, S.current.connectedToServer);
    } catch (e) {
      error.value = 'Failed to connect: $e';
      Get.snackbar(S.current.error, S.current.failedToConnectToServer);
    } finally {
      isLoading.value = false;
    }
  }
}
