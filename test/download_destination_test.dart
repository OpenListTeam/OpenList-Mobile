import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlist_mobile/generated/l10n.dart';
import 'package:openlist_mobile/utils/download_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FilePicker extends FilePicker {
  _FilePicker(this.directory);

  final String? directory;

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    bool lockParentWindow = false,
    String? initialDirectory,
  }) async =>
      directory;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await S.load(const Locale('en'));
  });

  test('download directory and ask-before-download preferences persist',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('openlist-download-');
    try {
      expect(
          await DownloadManager.setDownloadDirectory(directory.path), isTrue);
      expect(await DownloadManager.getConfiguredDownloadDirectory(),
          directory.path);
      expect(await DownloadManager.getAskForDownloadDirectory(), isFalse);

      await DownloadManager.setAskForDownloadDirectory(true);
      expect(await DownloadManager.getAskForDownloadDirectory(), isTrue);

      await DownloadManager.resetDownloadDirectory();
      expect(await DownloadManager.getConfiguredDownloadDirectory(), isNull);
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test('clearing downloads removes untracked files too', () async {
    final directory =
        await Directory.systemTemp.createTemp('openlist-download-clear-');
    final unrelated = File('${directory.path}/unrelated.txt');
    try {
      await unrelated.writeAsString('remove');
      expect(
          await DownloadManager.setDownloadDirectory(directory.path), isTrue);

      expect(await DownloadManager.clearDownloadDirectory(), isTrue);
      expect(await unrelated.exists(), isFalse);
    } finally {
      await DownloadManager.resetDownloadDirectory();
      await directory.delete(recursive: true);
    }
  });

  test('keeps previously configured directories discoverable', () async {
    final directory =
        await Directory.systemTemp.createTemp('openlist-download-history-');
    final file = File('${directory.path}${Platform.pathSeparator}old.bin');
    try {
      await file.writeAsBytes(const [1, 2, 3]);
      expect(
          await DownloadManager.setDownloadDirectory(directory.path), isTrue);
      await DownloadManager.resetDownloadDirectory();

      final files = await DownloadManager.getDownloadedFiles();
      expect(files.any((entry) => entry.path == file.path), isTrue);
    } finally {
      await DownloadManager.resetDownloadDirectory();
      await directory.delete(recursive: true);
    }
  });

  test('dismissing the save-directory picker creates no download task',
      () async {
    FilePicker.platform = _FilePicker(null);
    await DownloadManager.setAskForDownloadDirectory(true);

    final result = await DownloadManager.downloadFileWithProgress(
      url: 'https://files.example.test/archive.bin',
      filename: 'archive.bin',
    );

    expect(result, isFalse);
    expect(DownloadManager.activeTasks, isEmpty);
  });
}
