import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

enum UploadState { queued, running, succeeded, failed, canceled }

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
  });

  final String name;

  /// Destination folder, used to refresh listings when the job finishes.
  final String dir;
  final int size;
  final UploadRunner run;

  UploadState state = UploadState.queued;
  int sent = 0;
  Object? error;
  CancelToken? _cancelToken;

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

  void cancel(UploadJob job) {
    switch (job.state) {
      case UploadState.queued:
        job.state = UploadState.canceled;
        notifyListeners();
        _finished.add(job);
      case UploadState.running:
        job._cancelToken?.cancel();
      default:
        break;
    }
  }

  void retry(UploadJob job) {
    if (job.state != UploadState.failed && job.state != UploadState.canceled) {
      return;
    }
    job
      ..state = UploadState.queued
      ..sent = 0
      ..error = null;
    notifyListeners();
    _pump();
  }

  void clearFinished() {
    _jobs.removeWhere((j) => j.isFinished);
    notifyListeners();
  }

  void _pump() {
    var running = _jobs.where((j) => j.state == UploadState.running).length;
    for (final job in _jobs) {
      if (running >= concurrency) break;
      if (job.state != UploadState.queued) continue;
      running++;
      unawaited(_start(job));
    }
  }

  Future<void> _start(UploadJob job) async {
    final token = CancelToken();
    job
      ..state = UploadState.running
      ..sent = 0
      .._cancelToken = token;
    notifyListeners();
    var lastNotify = DateTime.fromMillisecondsSinceEpoch(0);
    try {
      await job.run(token, (sent, _) {
        job.sent = sent;
        final now = DateTime.now();
        if (now.difference(lastNotify) >= _progressInterval) {
          lastNotify = now;
          notifyListeners();
        }
      });
      job
        ..state = UploadState.succeeded
        ..sent = job.size;
    } catch (e) {
      job.state = token.isCancelled ? UploadState.canceled : UploadState.failed;
      job.error = token.isCancelled ? null : e;
    }
    job._cancelToken = null;
    notifyListeners();
    _finished.add(job);
    _pump();
  }
}
