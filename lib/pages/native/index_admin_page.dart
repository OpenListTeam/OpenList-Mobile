import 'dart:async';

import 'package:flutter/material.dart';
import 'package:openlist_mobile/api/session.dart';

import '../../generated/l10n.dart';
import 'common.dart';

class IndexAdminPage extends StatefulWidget {
  const IndexAdminPage({super.key});

  @override
  State<IndexAdminPage> createState() => _IndexAdminPageState();
}

class _IndexAdminPageState extends State<IndexAdminPage> {
  final _paths = TextEditingController();
  final _maxDepth = TextEditingController(text: '-1');
  final _scanPath = TextEditingController(text: '/');
  final _rateLimit = TextEditingController(text: '0');
  Map<String, dynamic> _index = const {};
  Map<String, dynamic> _scan = const {};
  Object? _indexError;
  Object? _scanError;
  bool _loading = true;
  bool _busy = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_isRunning) _load(quiet: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _paths.dispose();
    _maxDepth.dispose();
    _scanPath.dispose();
    _rateLimit.dispose();
    super.dispose();
  }

  bool get _isRunning =>
      _index['is_done'] == false || _scan['is_done'] == false;

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) setState(() => _loading = true);
    final session = OpenListSession.instance;
    try {
      _index = await session.admin.indexProgress();
      _indexError = null;
    } catch (e) {
      _indexError = e;
    }
    try {
      _scan = await session.admin.manualScanProgress();
      _scanError = null;
    } catch (e) {
      _scanError = e;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await _load(quiet: true);
    } catch (e) {
      if (mounted) showError(e);
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _buildIndex() async {
    if (!await confirmDialog(context, S.current.adminBuildIndexConfirm,
        title: S.current.adminIndexBuild)) {
      return;
    }
    await _run(() => OpenListSession.instance.admin.buildIndex());
  }

  Future<void> _updateIndex() async {
    final paths = _paths.text
        .split('\n')
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList();
    final maxDepth = int.tryParse(_maxDepth.text.trim());
    if (paths.isEmpty) {
      showMessage(S.current.adminIndexPathRequired);
      return;
    }
    if (maxDepth == null) {
      showMessage(S.current.adminInvalidNumber);
      return;
    }
    await _run(() => OpenListSession.instance.admin
        .updateIndex(paths: paths, maxDepth: maxDepth));
  }

  Future<void> _clearIndex() async {
    if (!await confirmDialog(context, S.current.adminClearIndexConfirm,
        title: S.current.adminIndexClear)) {
      return;
    }
    await _run(() => OpenListSession.instance.admin.clearIndex());
  }

  Future<void> _startManualScan() async {
    final path = _scanPath.text.trim();
    final limit = double.tryParse(_rateLimit.text.trim());
    if (path.isEmpty) {
      showMessage(S.current.emptyInput);
      return;
    }
    if (limit == null || limit < 0) {
      showMessage(S.current.adminInvalidNumber);
      return;
    }
    await _run(() => OpenListSession.instance.admin
        .startManualScan(path: path, limit: limit));
  }

  Widget _progressCard(String title, Map<String, dynamic> progress,
      {required String countKey}) {
    final done = progress['is_done'] != false;
    final details = [
      '${S.current.adminRunning}: ${done ? S.current.adminIdle : S.current.adminRunning}',
      '${S.current.adminScannedObjects}: ${progress[countKey] ?? 0}',
      if (progress['last_done_time'] != null)
        '${S.current.adminLastIndexed}: ${progress['last_done_time']}',
      if (progress['error'] is String &&
          (progress['error'] as String).isNotEmpty)
        '${S.current.adminProgressError}: ${progress['error']}',
    ].join('\n');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(details),
        ]),
      ),
    );
  }

  Widget _errorCard(Object error) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          leading: const Icon(Icons.error_outline),
          title: Text(errorText(error)),
        ),
      );

  Widget _section(String title, List<Widget> children) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children,
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).adminIndexes),
          actions: [
            IconButton(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh)),
          ],
        ),
        body: _loading && _index.isEmpty && _scan.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      if (_indexError != null)
                        _errorCard(_indexError!)
                      else
                        _progressCard(S.current.adminIndexes, _index,
                            countKey: 'obj_count'),
                      _section(S.current.adminIndexes, [
                        FilledButton.tonalIcon(
                          onPressed: _busy ? null : _buildIndex,
                          icon: const Icon(Icons.build_outlined),
                          label: Text(S.current.adminIndexBuild),
                        ),
                        TextField(
                          controller: _paths,
                          minLines: 2,
                          maxLines: 5,
                          decoration: InputDecoration(
                              labelText: S.current.adminPathsToUpdate),
                        ),
                        TextField(
                          controller: _maxDepth,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              labelText: S.current.adminMaxDepth),
                        ),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, children: [
                          FilledButton.tonal(
                              onPressed: _busy ? null : _updateIndex,
                              child: Text(S.current.adminIndexUpdate)),
                          OutlinedButton(
                              onPressed: _busy || !_isRunning
                                  ? null
                                  : () => _run(() => OpenListSession
                                      .instance.admin
                                      .stopIndex()),
                              child: Text(S.current.adminIndexStop)),
                          TextButton(
                              onPressed: _busy ? null : _clearIndex,
                              child: Text(S.current.adminIndexClear)),
                        ]),
                      ]),
                      if (_scanError != null)
                        _errorCard(_scanError!)
                      else
                        _progressCard(S.current.adminManualScan, _scan,
                            countKey: 'obj_count'),
                      _section(S.current.adminManualScan, [
                        TextField(
                            controller: _scanPath,
                            decoration: InputDecoration(
                                labelText: S.current.adminScanPath)),
                        TextField(
                          controller: _rateLimit,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                              labelText: S.current.adminRateLimit),
                        ),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, children: [
                          FilledButton.tonal(
                              onPressed: _busy ? null : _startManualScan,
                              child: Text(S.current.adminManualScan)),
                          OutlinedButton(
                              onPressed: _busy || _scan['is_done'] != false
                                  ? null
                                  : () => _run(() => OpenListSession
                                      .instance.admin
                                      .stopManualScan()),
                              child: Text(S.current.adminIndexStop)),
                        ]),
                      ]),
                    ]),
              ),
      );
}
