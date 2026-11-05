import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../api/session.dart';

class RecentFile {
  const RecentFile({
    required this.path,
    required this.name,
    required this.size,
    required this.type,
    required this.openedAt,
  });

  final String path;
  final String name;
  final int size;
  final int type;
  final DateTime openedAt;

  factory RecentFile.fromJson(Map<String, dynamic> json) => RecentFile(
        path: json['path'] as String? ?? '',
        name: json['name'] as String? ?? '',
        size: json['size'] is num ? (json['size'] as num).toInt() : 0,
        type: json['type'] is num ? (json['type'] as num).toInt() : 0,
        openedAt: DateTime.tryParse(json['opened_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  Map<String, dynamic> toJson() => {
        'path': path,
        'name': name,
        'size': size,
        'type': type,
        'opened_at': openedAt.toIso8601String(),
      };
}

class RecentFiles {
  static const _key = 'recent_files.v1';
  static const _limit = 50;

  static String get _serverKey {
    final session = OpenListSession.instance;
    final baseUrl = session.client?.baseUrl ?? '';
    return '${session.kind.name}:$baseUrl:${session.user?.id ?? 0}';
  }

  static Future<void> record(
      String path, String name, int size, int type) async {
    final prefs = await SharedPreferences.getInstance();
    final records = _decode(prefs.getString(_key));
    final serverKey = _serverKey;
    records.removeWhere(
        (entry) => entry['server'] == serverKey && entry['path'] == path);
    records.insert(0, {
      'server': serverKey,
      ...RecentFile(
        path: path,
        name: name,
        size: size,
        type: type,
        openedAt: DateTime.now(),
      ).toJson(),
    });
    final counts = <String, int>{};
    final retained = <Map<String, dynamic>>[];
    for (final record in records) {
      final key = record['server'] as String? ?? '';
      final count = counts[key] ?? 0;
      if (count >= _limit) continue;
      counts[key] = count + 1;
      retained.add(record);
    }
    await prefs.setString(_key, jsonEncode(retained));
  }

  static Future<List<RecentFile>> list() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_key))
        .where((entry) => entry['server'] == _serverKey)
        .map(RecentFile.fromJson)
        .where((entry) => entry.path.isNotEmpty)
        .toList();
  }

  static List<Map<String, dynamic>> _decode(String? value) {
    if (value == null || value.isEmpty) return [];
    try {
      final decoded = jsonDecode(value);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
    } on FormatException {
      return [];
    }
  }
}
