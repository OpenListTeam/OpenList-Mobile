import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart' as zip;
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlist_mobile/utils/local_zip_archive.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _TestPathProvider extends PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async => Directory.systemTemp.path;
}

class _ZipAdapter implements HttpClientAdapter {
  _ZipAdapter(this.bytes);

  final Uint8List bytes;
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    request = options;
    return ResponseBody.fromBytes(bytes, 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = _TestPathProvider();
  late Directory directory;
  late File archiveFile;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('openlist-local-zip-');
    archiveFile = File('${directory.path}${Platform.pathSeparator}test.zip');
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('downloads ZIP data with the supplied authorization headers', () async {
    final archive = zip.Archive()
      ..add(zip.ArchiveFile.string('remote.txt', 'remote data'));
    final bytes = Uint8List.fromList(zip.ZipEncoder().encode(archive));
    final adapter = _ZipAdapter(bytes);
    final client = Dio()..httpClientAdapter = adapter;

    final local = await LocalZipArchive.download(
      url: 'https://core.example.test/archive.zip',
      headers: const {'Authorization': 'token'},
      expectedSize: bytes.length,
      client: client,
    );
    try {
      expect(adapter.request?.headers['Authorization'], 'token');
      final entry = local.list('/').single;
      expect(entry.name, 'remote.txt');
    } finally {
      await local.dispose();
    }
  });

  test('lists nested ZIP entries and extracts files from disk', () async {
    final archive = zip.Archive()
      ..add(zip.ArchiveFile.string('root.txt', 'root'))
      ..add(zip.ArchiveFile.string('nested/child.txt', 'child data'));
    await archiveFile.writeAsBytes(zip.ZipEncoder().encode(archive));

    final local = LocalZipArchive.fromFile(archiveFile);
    try {
      final root = local.list('/');
      expect(root.map((entry) => entry.name), ['nested', 'root.txt']);
      expect(root.first.isDirectory, isTrue);

      final nested = local.list('/nested/');
      expect(nested.map((entry) => entry.name), ['child.txt']);
      final extracted = await local.extract(nested.single);
      try {
        expect(await extracted.file.readAsString(), 'child data');
      } finally {
        await extracted.dispose();
      }
    } finally {
      await local.dispose();
    }
  });

  test('omits unsafe paths and keeps similarly prefixed directories separate',
      () async {
    final archive = zip.Archive()
      ..add(zip.ArchiveFile.string('safe/file.txt', 'safe'))
      ..add(zip.ArchiveFile.string('safely/other.txt', 'other'))
      ..add(zip.ArchiveFile.string('../outside.txt', 'outside'));
    await archiveFile.writeAsBytes(zip.ZipEncoder().encode(archive));

    final local = LocalZipArchive.fromFile(archiveFile);
    try {
      expect(local.list('/').map((entry) => entry.name), ['safe', 'safely']);
      expect(local.list('/safe/').map((entry) => entry.name), ['file.txt']);
    } finally {
      await local.dispose();
    }
  });
}
