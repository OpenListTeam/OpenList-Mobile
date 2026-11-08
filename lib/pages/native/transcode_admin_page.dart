import 'dart:async';

import 'package:flutter/material.dart';
import 'package:openlist_mobile/api/session.dart';

import '../../generated/l10n.dart';
import 'common.dart';

class TranscodeAdminPage extends StatefulWidget {
  const TranscodeAdminPage({super.key});

  @override
  State<TranscodeAdminPage> createState() => _TranscodeAdminPageState();
}

class _TranscodeAdminPageState extends State<TranscodeAdminPage> {
  List<Map<String, dynamic>> _workers = const [];
  List<Map<String, dynamic>> _jobs = const [];
  Object? _error;
  bool _loading = true;
  bool _busy = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _load(quiet: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) setState(() => _loading = true);
    try {
      final results = await Future.wait([
        OpenListSession.instance.admin.listTranscodeWorkers(),
        OpenListSession.instance.admin.listTranscodeJobs(),
      ]);
      if (!mounted) return;
      _workers = results[0];
      _jobs = results[1];
      _error = null;
    } catch (e) {
      if (mounted && !quiet) _error = e;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _cancel(String id) async {
    if (!await confirmDialog(
      context,
      S.current.transcodeCancelConfirm,
      title: S.current.cancel,
    )) {
      return;
    }
    setState(() => _busy = true);
    try {
      await OpenListSession.instance.admin.cancelTranscodeJob(id);
      await _load(quiet: true);
    } catch (e) {
      if (mounted) showError(e);
    }
    if (mounted) setState(() => _busy = false);
  }

  Widget _section(String title, List<Widget> children) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        ...children,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading && _workers.isEmpty && _jobs.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null && _workers.isEmpty && _jobs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(S.of(context).transcodeManagement)),
        body: StateMessage(
          icon: Icons.error_outline,
          text: errorText(_error!),
          action: S.of(context).retry,
          onAction: _load,
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).transcodeManagement),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _section(S.current.transcodeWorkers, [
              if (_workers.isEmpty) ListTile(title: Text(S.current.adminEmpty)),
              for (final worker in _workers)
                ListTile(
                  title: Text('${worker['name'] ?? worker['id'] ?? ''}'),
                  subtitle: Text(
                    [
                      '${S.current.transcodeCapacity}: ${worker['capacity'] ?? 0}',
                      '${S.current.transcodeFreeSlots}: ${worker['free_slots'] ?? 0}',
                      '${S.current.transcodeHardwareAcceleration}: ${((worker['hwaccel'] as List?) ?? const []).join(', ')}',
                      if (worker['local'] == true)
                        S.current.transcodeLocalWorker,
                      '${S.current.transcodeLastSeen}: ${worker['last_seen'] ?? '—'}',
                    ].join('\n'),
                  ),
                ),
            ]),
            _section(S.current.transcodeJobs, [
              if (_jobs.isEmpty) ListTile(title: Text(S.current.adminEmpty)),
              for (final job in _jobs)
                ListTile(
                  title: Text(
                    '${job['path'] ?? ''}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    [
                      '${S.current.transcodeJobStatus}: ${job['status'] ?? ''}',
                      '${S.current.transcodeJobWorker}: ${job['worker_id'] ?? '—'}',
                      if (job['error'] is String &&
                          (job['error'] as String).isNotEmpty)
                        '${S.current.error}: ${job['error']}',
                    ].join('\n'),
                  ),
                  trailing:
                      ['pending', 'running', 'ready'].contains(job['status'])
                      ? IconButton(
                          tooltip: S.current.cancel,
                          onPressed: _busy
                              ? null
                              : () => _cancel('${job['id'] ?? ''}'),
                          icon: const Icon(Icons.cancel_outlined),
                        )
                      : null,
                ),
            ]),
          ],
        ),
      ),
    );
  }
}
