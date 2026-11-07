import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:openlist_mobile/utils/recent_files.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('records most recent paths once and limits stored history', () async {
    for (var i = 0; i < 55; i++) {
      await RecentFiles.record('/dir/$i.txt', '$i.txt', i, 4);
    }
    await RecentFiles.record('/dir/54.txt', 'updated.txt', 54, 4);

    final files = await RecentFiles.list();
    expect(files, hasLength(50));
    expect(files.first.path, '/dir/54.txt');
    expect(files.first.name, 'updated.txt');
    expect(files.last.path, '/dir/5.txt');
  });

  test('retains history independently for each server', () async {
    final otherServer = List.generate(
      50,
      (i) => {
        'server': 'remote:https://other.example:1',
        'path': '/other/$i.txt',
        'name': '$i.txt',
        'size': i,
        'type': 4,
        'opened_at': DateTime.utc(2026, 1, 1).toIso8601String(),
      },
    );
    SharedPreferences.setMockInitialValues({
      'recent_files.v1': jsonEncode(otherServer),
    });
    for (var i = 0; i < 51; i++) {
      await RecentFiles.record('/current/$i.txt', '$i.txt', i, 4);
    }

    final prefs = await SharedPreferences.getInstance();
    final persisted = jsonDecode(prefs.getString('recent_files.v1')!) as List;
    expect(
      persisted.where(
        (entry) => entry['server'] == 'remote:https://other.example:1',
      ),
      hasLength(50),
    );
    expect(await RecentFiles.list(), hasLength(50));
  });

  test('ignores malformed persisted data', () async {
    SharedPreferences.setMockInitialValues({'recent_files.v1': '{'});
    expect(await RecentFiles.list(), isEmpty);
  });
}
