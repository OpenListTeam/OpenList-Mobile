import 'dart:io';

import 'package:archive/archive.dart' as zip;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class LocalZipEntry {
  const LocalZipEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
    this.file,
  });

  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final zip.ArchiveFile? file;
}

class LocalZipArchive {
  LocalZipArchive._(this.file, this._directory);

  final File file;
  final Directory? _directory;
  late zip.InputFileStream _input;
  late zip.Archive _archive;
  bool encrypted = false;
  bool _disposed = false;

  static Future<LocalZipArchive> download({
    required String url,
    required Map<String, String> headers,
    required int expectedSize,
    String password = '',
    Dio? client,
    CancelToken? cancelToken,
  }) async {
    final temp = await getTemporaryDirectory();
    final directory = await temp.createTemp('openlist-zip-');
    final file = File('${directory.path}${Platform.pathSeparator}archive.zip');
    try {
      final response = await (client ?? Dio()).download(
        url,
        file.path,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      );
      if (response.statusCode != 200) {
        throw HttpException('Unexpected ZIP download status',
            uri: Uri.parse(url));
      }
      final actualSize = await file.length();
      if (expectedSize > 0 && actualSize != expectedSize) {
        throw const FormatException('Incomplete ZIP download');
      }
      final archive = LocalZipArchive._(file, directory);
      archive._open(password);
      return archive;
    } catch (_) {
      if (await directory.exists()) await directory.delete(recursive: true);
      rethrow;
    }
  }

  static LocalZipArchive fromFile(File file, {String password = ''}) {
    final archive = LocalZipArchive._(file, null);
    archive._open(password);
    return archive;
  }

  void _open(String password) {
    _input = zip.InputFileStream(file.path);
    final decoder = zip.ZipDecoder();
    try {
      _archive = decoder.decodeStream(
        _input,
        password: password.isEmpty ? null : password,
      );
      if (decoder.directory.filePosition < 0) {
        throw const FormatException('Invalid ZIP archive');
      }
      encrypted = decoder.directory.fileHeaders.any((header) =>
          header.generalPurposeBitFlag & 1 != 0 ||
          header.compressionMethod == 99);
    } catch (_) {
      _input.closeSync();
      rethrow;
    }
  }

  Future<void> setPassword(String password) async {
    await _closeArchive();
    _open(password);
  }

  List<LocalZipEntry> list(String innerPath) {
    final normalizedInner = innerPath
        .replaceAll('\\', '/')
        .split('/')
        .where((part) => part.isNotEmpty)
        .join('/');
    final prefix = normalizedInner.isEmpty ? '' : '$normalizedInner/';
    final entries = <String, LocalZipEntry>{};

    for (final file in _archive.files) {
      var path =
          file.name.replaceAll('\\', '/').replaceFirst(RegExp(r'^/+'), '');
      final isDirectory = file.isDirectory || path.endsWith('/');
      path = path.replaceAll(RegExp(r'/+$'), '');
      if (path.isEmpty || path.split('/').contains('..')) continue;
      if (!path.startsWith(prefix)) continue;

      final relative = path.substring(prefix.length);
      if (relative.isEmpty) continue;
      final separator = relative.indexOf('/');
      if (separator >= 0) {
        final name = relative.substring(0, separator);
        final childPath = '$prefix$name'.replaceAll(RegExp(r'/+$'), '');
        entries.putIfAbsent(
          childPath,
          () => LocalZipEntry(
            name: name,
            path: childPath,
            isDirectory: true,
            size: 0,
          ),
        );
      } else {
        entries[path] = LocalZipEntry(
          name: relative,
          path: path,
          isDirectory: isDirectory,
          size: isDirectory ? 0 : file.size,
          file: isDirectory ? null : file,
        );
      }
    }

    final result = entries.values.toList()
      ..sort((a, b) {
        if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return result;
  }

  LocalZipEntry? findFile(String path) {
    final normalized = path
        .replaceAll('\\', '/')
        .split('/')
        .where((part) => part.isNotEmpty)
        .join('/');
    for (final file in _archive.files) {
      final name = file.name
          .replaceAll('\\', '/')
          .replaceFirst(RegExp(r'^/+'), '')
          .replaceAll(RegExp(r'/+$'), '');
      if (name == normalized && !file.isDirectory) {
        return LocalZipEntry(
          name: name.split('/').last,
          path: name,
          isDirectory: false,
          size: file.size,
          file: file,
        );
      }
    }
    return null;
  }

  Future<TemporaryZipEntry> extract(LocalZipEntry entry) async {
    final source = entry.file;
    if (source == null || entry.isDirectory) {
      throw ArgumentError.value(entry, 'entry', 'Not a ZIP file entry');
    }
    final directory = await Directory.systemTemp.createTemp('openlist-entry-');
    final outputFile = File('${directory.path}${Platform.pathSeparator}entry');
    final output = zip.OutputFileStream(outputFile.path);
    try {
      source.writeContent(output);
      await output.close();
      return TemporaryZipEntry(directory, outputFile);
    } catch (_) {
      await output.close();
      await directory.delete(recursive: true);
      rethrow;
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _closeArchive();
    final directory = _directory;
    if (directory != null && await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<void> _closeArchive() async {
    await _archive.clear();
    await _input.close();
  }
}

class TemporaryZipEntry {
  const TemporaryZipEntry(this.directory, this.file);

  final Directory directory;
  final File file;

  Future<void> dispose() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}
