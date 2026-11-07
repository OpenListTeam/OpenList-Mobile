import 'dart:io';
import 'dart:typed_data';

import 'package:openlist_mobile/contant/native_bridge.dart';
import 'package:openlist_mobile/generated_api.dart';

class DownloadDirectoryTarget {
  DownloadDirectoryTarget.path({
    required this.reference,
    required Directory directory,
  }) : name = directory.path,
       directory = directory,
       native = null;

  DownloadDirectoryTarget.native(DownloadDirectory directory)
    : reference = directory.reference,
      name = directory.name,
      directory = null,
      native = directory;

  final String reference;
  final String name;
  final Directory? directory;
  final DownloadDirectory? native;

  bool get isNative => native != null;
}

abstract class DownloadDestination {
  String get directoryReference;
  String get filename;
  String? get filePath;
  String? get partialFilePath;
  String? get fileReference;

  Future<int> length();
  Future<void> truncate();
  Future<void> write(int offset, List<int> data);
  Future<void> flush();
  Future<void> finalize();
  Future<void> discard();
  Future<DownloadFile?> stat();
  Future<bool> open();
}

class PathDownloadDestination implements DownloadDestination {
  PathDownloadDestination({
    required this.directoryReference,
    required this.filename,
    required this.filePath,
    required this.partialFilePath,
    bool finalized = false,
  }) : _finalized = finalized;

  @override
  final String directoryReference;

  @override
  String filename;

  @override
  final String filePath;

  @override
  final String partialFilePath;

  @override
  String? get fileReference => null;

  File get _partialFile => File(partialFilePath);
  File get _finalFile => File(filePath);
  File get _currentFile => _finalized ? _finalFile : _partialFile;
  bool _finalized;

  @override
  Future<int> length() async {
    final file = _currentFile;
    if (!await file.exists()) return 0;
    return file.length();
  }

  @override
  Future<void> truncate() async {
    final file = _currentFile;
    final output = await file.open(mode: FileMode.write);
    await output.truncate(0);
    await output.close();
  }

  @override
  Future<void> write(int offset, List<int> data) async {
    final file = _currentFile;
    final length = await file.exists() ? await file.length() : 0;
    if (length != offset) {
      throw FileSystemException('Unexpected download write offset');
    }
    await file.writeAsBytes(data, mode: FileMode.append);
  }

  @override
  Future<void> flush() async {
    final output = await _currentFile.open(mode: FileMode.append);
    try {
      await output.flush();
    } finally {
      await output.close();
    }
  }

  @override
  Future<void> finalize() async {
    await _partialFile.rename(filePath);
    _finalized = true;
  }

  @override
  Future<void> discard() async {
    final current = _currentFile;
    if (await current.exists()) await current.delete();
    _finalized = false;
  }

  @override
  Future<DownloadFile?> stat() async {
    final file = _currentFile;
    if (!await file.exists()) return null;
    final stat = await file.stat();
    return DownloadFile(
      reference: file.path,
      directoryReference: directoryReference,
      name: filename,
      size: stat.size,
      modifiedAt: stat.modified.millisecondsSinceEpoch,
      mimeType: null,
    );
  }

  @override
  Future<bool> open() async => false;
}

class NativeDownloadDestination implements DownloadDestination {
  NativeDownloadDestination({
    required this.directoryReference,
    required this.filename,
    required String fileReference,
  }) : _fileReference = fileReference;

  @override
  final String directoryReference;

  @override
  String filename;

  String _fileReference;

  @override
  String? get filePath => null;

  @override
  String? get partialFilePath => null;

  @override
  String get fileReference => _fileReference;

  DownloadStorage get _storage => NativeBridge.downloadStorage;

  static Future<NativeDownloadDestination> reserve(
    String directoryReference,
    String filename,
  ) async {
    final file = await NativeBridge.downloadStorage.reserveFile(
      directoryReference,
      filename,
    );
    return NativeDownloadDestination(
      directoryReference: file.directoryReference,
      filename: file.name,
      fileReference: file.reference,
    );
  }

  static NativeDownloadDestination fromFile(DownloadFile file) =>
      NativeDownloadDestination(
        directoryReference: file.directoryReference,
        filename: file.name,
        fileReference: file.reference,
      );

  @override
  Future<int> length() => _storage.getFileLength(_fileReference);

  @override
  Future<void> truncate() => _storage.truncateFile(_fileReference);

  @override
  Future<void> write(int offset, List<int> data) =>
      _storage.writeFile(_fileReference, offset, Uint8List.fromList(data));

  @override
  Future<void> flush() => _storage.flushFile(_fileReference);

  @override
  Future<void> finalize() async {
    final file = await _storage.finalizeFile(_fileReference);
    _fileReference = file.reference;
    filename = file.name;
  }

  @override
  Future<void> discard() => _storage.discardFile(_fileReference);

  @override
  Future<DownloadFile?> stat() => _storage.getFile(_fileReference);

  @override
  Future<bool> open() => _storage.openFile(_fileReference);
}
