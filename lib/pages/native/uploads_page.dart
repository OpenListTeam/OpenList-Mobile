import 'package:flutter/material.dart';
import 'package:openlist_mobile/api/upload_queue.dart';

import '../../generated/l10n.dart';
import 'common.dart';

/// Shows the app-wide upload queue with cancel and retry actions.
class UploadsPage extends StatelessWidget {
  const UploadsPage({super.key});

  static String stateText(UploadState s) => switch (s) {
        UploadState.queued => S.current.uploadQueued,
        UploadState.running => S.current.uploadRunning,
        UploadState.paused => S.current.paused,
        UploadState.cancelling => S.current.cancelling,
        UploadState.succeeded => S.current.uploadSucceeded,
        UploadState.failed => S.current.uploadFailedState,
        UploadState.canceled => S.current.uploadCanceled,
      };

  @override
  Widget build(BuildContext context) {
    final queue = UploadQueue.instance;
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).uploads), actions: [
        IconButton(
          tooltip: S.of(context).clearFinished,
          icon: const Icon(Icons.clear_all),
          onPressed: queue.clearFinished,
        ),
      ]),
      body: ListenableBuilder(
        listenable: queue,
        builder: (context, _) {
          final jobs = queue.jobs;
          if (jobs.isEmpty) {
            return StateMessage(
                icon: Icons.cloud_upload_outlined,
                text: S.of(context).noUploads);
          }
          return ListView(children: [
            ListTile(
              dense: true,
              leading: const Icon(Icons.info_outline),
              title: Text(S.of(context).uploadsKeepAppAlive),
            ),
            for (final j in jobs.reversed) _tile(context, queue, j),
          ]);
        },
      ),
    );
  }

  Widget _tile(BuildContext context, UploadQueue queue, UploadJob j) {
    final status = j.state == UploadState.failed && j.error != null
        ? '${stateText(j.state)}: ${errorText(j.error!)}'
        : '${stateText(j.state)} · ${formatBytes(j.sent)} / ${formatBytes(j.size)}';
    return ListTile(
      title: Text(j.name, overflow: TextOverflow.ellipsis),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${j.dir} · $status',
            maxLines: 2, overflow: TextOverflow.ellipsis),
        if (j.state == UploadState.running)
          LinearProgressIndicator(value: j.progress),
      ]),
      trailing: switch (j.state) {
        UploadState.queued ||
        UploadState.running ||
        UploadState.paused =>
          IconButton(
              tooltip: S.of(context).cancel,
              icon: const Icon(Icons.close),
              onPressed: () => queue.cancel(j)),
        UploadState.failed || UploadState.canceled => IconButton(
            tooltip: S.of(context).retry,
            icon: const Icon(Icons.refresh),
            onPressed: () => queue.retry(j)),
        UploadState.cancelling => const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        UploadState.succeeded => const Icon(Icons.check),
      },
    );
  }
}
