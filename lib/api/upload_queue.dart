import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

enum UploadState {
  queued,
  running,
  paused,
  cancelling,
  succeeded,
  failed,
  canceled
}

/// Performs one upload attempt; must open a fresh data stream on every call
/// so failed or canceled jobs can be retried.
typedef UploadRunner = Future<void> Function(
    CancelToken cancelToken, ProgressCallback onProgress);

class UploadJob {
  UploadJob({
    required this.name,
    required this.dir,
    required this.size,
    required this.run,
    this.historyId,
    this.onRemove,
    this.canRetry = true,
  });

  final String name;

  /// Destination folder, used to refresh listings when the job finishes.
  final String dir;
  final int size;
  final UploadRunner run;
  final String? historyId;
  final VoidCallback? onRemove;
  final bool canRetry;

  UploadState state = UploadState.queued;
  int sent = 0;
  Object? error;
  CancelToken? _cancelToken;

  /// Running through [UploadQueue.adopt], outside the concurrency limit.
  bool _adopted = false;

  bool _removeWhenFinished = false;

  double? get progress =>
      size > 0 ? (sent / size).clamp(0.0, 1.0).toDouble() : null;

  bool get isFinished =>
      state == UploadState.succeeded ||
      state == UploadState.failed ||
      state == UploadState.canceled;
}

/// App-wide upload queue with bounded concurrency and per-job cancel/retry.
///
/// Jobs keep running while the app process lives, independent of the page
/// that queued them.
class UploadQueue extends ChangeNotifier {
  UploadQueue({this.concurrency = 2});

  static final UploadQueue instance = UploadQueue();

  final int concurrency;
  final List<UploadJob> _jobs = [];
  final StreamController<UploadJob> _finished =
      StreamController<UploadJob>.broadcast();

  static const _progressInterval = Duration(milliseconds: 250);

  List<UploadJob> get jobs => List.unmodifiable(_jobs);

  /// Emits each job once it succeeds, fails or is canceled.
  Stream<UploadJob> get finished => _finished.stream;

  int get activeCount => _jobs.where((j) => !j.isFinished).length;

  void add(UploadJob job) {
    _jobs.add(job);
    notifyListeners();
    _pump();
  }

  void addAll(Iterable<UploadJob> jobs) {
    _jobs.addAll(jobs);
    notifyListeners();
    _pump();
  }

  /// Adds a job whose transfer is already in progress elsewhere, such as a
  /// background upload restored after a relaunch. [attach] follows that
  /// transfer like [UploadJob.run] would. The job shows as running at once
  /// and does not take a concurrency slot; a later retry runs [job]'s `run`
  /// through the queue like any other job.
  void adopt(UploadJob job, UploadRunner attach) {
    _jobs.add(job);
    unawaited(_start(job, runner: attach));
  }

  /// Inserts a persisted terminal job without running its upload runner.
  void addHistory(UploadJob job) {
    if (_jobs.any((existing) =>
        job.historyId != null && existing.historyId == job.historyId)) {
      return;
    }
    if (!job.isFinished) {
      throw ArgumentError.value(
          job.state, 'job.state', 'History jobs must be finished');
    }
    _jobs.add(job);
    notifyListeners();
  }

  /// Removes a finished job, or cancels an active job before removing it.
  void remove(UploadJob job) {
    if (!_jobs.contains(job)) return;
    if (!job.isFinished) {
      job._removeWhenFinished = true;
      cancel(job);
      if (!job.isFinished) return;
    }
    if (_jobs.remove(job)) {
      job._removeWhenFinished = false;
      job.onRemove?.call();
      notifyListeners();
    }
  }

  void cancel(UploadJob job) {
    switch (job.state) {
      case UploadState.queued:
        job.state = UploadState.canceled;
        notifyListeners();
        _finished.add(job);
      case UploadState.running:
        final token = job._cancelToken;
        if (token == null || token.isCancelled) return;
        job.state = UploadState.cancelling;
        notifyListeners();
        token.cancel();
      default:
        break;
    }
  }

  void retry(UploadJob job) {
    if (!_jobs.contains(job) ||
        !job.canRetry ||
        (job.state != UploadState.failed &&
            job.state != UploadState.canceled)) {
      return;
    }
    job
      .._removeWhenFinished = false
      ..state = UploadState.queued
      ..sent = 0
      ..error = null;
    notifyListeners();
    _pump();
  }

  void clearFinished() {
    for (final job in _jobs.where((job) => job.isFinished)) {
      job.onRemove?.call();
    }
    _jobs.removeWhere((j) => j.isFinished);
    notifyListeners();
  }

  void _pump() {
    var running = _jobs
        .where((j) =>
            (j.state == UploadState.running ||
                j.state == UploadState.cancelling) &&
            !j._adopted)
        .length;
    for (final job in _jobs) {
      if (running >= concurrency) break;
      if (job.state != UploadState.queued) continue;
      running++;
      unawaited(_start(job));
    }
  }

  Future<void> _start(UploadJob job, {UploadRunner? runner}) async {
    final token = CancelToken();
    job
      ..state = UploadState.running
      ..sent = 0
      .._cancelToken = token
      .._adopted = runner != null;
    notifyListeners();
    var lastNotify = DateTime.fromMillisecondsSinceEpoch(0);
    try {
      await (runner ?? job.run)(token, (sent, _) {
        job.sent = sent;
        final now = DateTime.now();
        if (now.difference(lastNotify) >= _progressInterval) {
          lastNotify = now;
          notifyListeners();
        }
      });
      job.state = UploadState.succeeded;
      job.sent = job.size;
    } catch (e) {
      job.state = token.isCancelled ? UploadState.canceled : UploadState.failed;
      job.error = token.isCancelled ? null : e;
    }
    job
      .._cancelToken = null
      .._adopted = false;
    if (job._removeWhenFinished && _jobs.remove(job)) {
      job._removeWhenFinished = false;
      job.onRemove?.call();
    }
    notifyListeners();
    _finished.add(job);
    _pump();
  }
}
