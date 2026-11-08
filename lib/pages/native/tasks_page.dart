import 'dart:async';

import 'package:flutter/material.dart';
import 'package:openlist_mobile/api/models.dart';
import 'package:openlist_mobile/api/session.dart';
import 'package:openlist_mobile/api/task_api.dart';

import '../../generated/l10n.dart';
import 'common.dart';

String taskGroupLabel(String group) => switch (group) {
  TaskGroup.upload => S.current.taskGroupUpload,
  TaskGroup.copy => S.current.taskGroupCopy,
  TaskGroup.move => S.current.taskGroupMove,
  TaskGroup.offlineDownload => S.current.taskGroupOfflineDownload,
  TaskGroup.offlineDownloadTransfer => S.current.taskGroupTransfer,
  TaskGroup.decompress => S.current.taskGroupDecompress,
  TaskGroup.decompressUpload => S.current.taskGroupDecompressUpload,
  _ => group,
};

/// Server-side tasks grouped by type.
class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: TaskGroup.all.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).tasks),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final g in TaskGroup.all) Tab(text: taskGroupLabel(g))],
          ),
        ),
        body: TabBarView(
          children: [for (final g in TaskGroup.all) _TaskGroupView(group: g)],
        ),
      ),
    );
  }
}

class _TaskGroupView extends StatefulWidget {
  const _TaskGroupView({required this.group});

  final String group;

  @override
  State<_TaskGroupView> createState() => _TaskGroupViewState();
}

class _TaskGroupViewState extends State<_TaskGroupView>
    with AutomaticKeepAliveClientMixin {
  List<TaskInfo> _undone = const [];
  List<TaskInfo> _done = const [];
  Object? _error;
  bool _loading = true;
  Timer? _timer;

  TaskApi get _api => OpenListSession.instance.tasks;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
    // Poll while active tasks exist.
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_undone.isNotEmpty) _load(quiet: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) setState(() => _loading = true);
    try {
      final r = await Future.wait([
        _api.undone(widget.group),
        _api.done(widget.group),
      ]);
      _undone = r[0];
      _done = r[1];
      _error = null;
    } catch (e) {
      if (!quiet) _error = e;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _act(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (e) {
      showError(e);
    }
    if (mounted) await _load(quiet: true);
  }

  Widget _tile(TaskInfo t) {
    final g = widget.group;
    final sub = [
      if (t.status.isNotEmpty) t.status,
      if (t.totalBytes > 0) formatBytes(t.totalBytes),
      formatTime(t.startTime),
    ].where((e) => e.isNotEmpty).join(' · ');
    return ListTile(
      title: Text(t.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sub.isNotEmpty) Text(sub),
          if (t.isActive)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: LinearProgressIndicator(
                value: t.progress > 0
                    ? (t.progress / 100).clamp(0.0, 1.0)
                    : null,
              ),
            ),
          if (t.error.isNotEmpty)
            Text(
              t.error,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (t.isActive)
            IconButton(
              tooltip: S.current.cancel,
              icon: const Icon(Icons.close),
              onPressed: () => _act(() => _api.cancel(g, t.id)),
            ),
          if (t.canRetry)
            IconButton(
              tooltip: S.current.retry,
              icon: const Icon(Icons.replay),
              onPressed: () => _act(() => _api.retry(g, t.id)),
            ),
          if (!t.isActive)
            IconButton(
              tooltip: S.current.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _act(() => _api.delete(g, t.id)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading && _undone.isEmpty && _done.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return StateMessage(
        icon: Icons.error_outline,
        text: errorText(_error!),
        action: S.of(context).retry,
        onAction: _load,
      );
    }
    final g = widget.group;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        children: [
          if (_undone.isEmpty && _done.isEmpty) ...[
            const SizedBox(height: 120),
            StateMessage(icon: Icons.task_alt, text: S.of(context).noTasks),
          ],
          if (_undone.isNotEmpty) ...[
            ListTile(dense: true, title: Text(S.of(context).taskUndone)),
            for (final t in _undone) _tile(t),
          ],
          if (_done.isNotEmpty) ...[
            ListTile(
              dense: true,
              title: Text(S.of(context).taskDone),
              trailing: PopupMenuButton<int>(
                icon: const Icon(Icons.cleaning_services_outlined),
                onSelected: (v) => _act(
                  () => v == 0
                      ? _api.clearSucceeded(g)
                      : v == 1
                      ? _api.clearDone(g)
                      : _api.retryFailed(g),
                ),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 0,
                    child: Text(S.current.clearSucceeded),
                  ),
                  PopupMenuItem(value: 1, child: Text(S.current.clearFinished)),
                  PopupMenuItem(value: 2, child: Text(S.current.retry)),
                ],
              ),
            ),
            for (final t in _done) _tile(t),
          ],
        ],
      ),
    );
  }
}
