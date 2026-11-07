import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlist_mobile/api/upload_queue.dart';

/// A job whose single attempt is finished by the test.
class _Job {
  _Job(String name) {
    job = UploadJob(
      name: name,
      dir: '/d',
      size: 10,
      run: (token, onProgress) {
        attempts++;
        final c = Completer<void>();
        attempt = c;
        token.whenCancel.then((e) {
          if (!c.isCompleted) c.completeError(e);
        });
        onProgress(5, 10);
        return c.future;
      },
    );
  }

  late final UploadJob job;
  Completer<void>? attempt;
  int attempts = 0;
}

void main() {
  test(
    'runs at most `concurrency` jobs and starts the next on finish',
    () async {
      final q = UploadQueue(concurrency: 2);
      final jobs = [_Job('a'), _Job('b'), _Job('c')];
      q.addAll(jobs.map((j) => j.job));
      await Future<void>.delayed(Duration.zero);

      expect(jobs.map((j) => j.job.state), [
        UploadState.running,
        UploadState.running,
        UploadState.queued,
      ]);
      expect(jobs[0].job.sent, 5);

      jobs[0].attempt!.complete();
      await Future<void>.delayed(Duration.zero);
      expect(jobs[0].job.state, UploadState.succeeded);
      expect(jobs[0].job.sent, 10);
      expect(jobs[2].job.state, UploadState.running);
      expect(q.activeCount, 2);
    },
  );

  test('cancel stops queued and running jobs; retry runs them again', () async {
    final q = UploadQueue(concurrency: 1);
    final a = _Job('a'), b = _Job('b');
    final finished = <String>[];
    q.finished.listen((j) => finished.add('${j.name}:${j.state.name}'));
    q.addAll([a.job, b.job]);
    await Future<void>.delayed(Duration.zero);

    q.cancel(b.job);
    q.cancel(a.job);
    await Future<void>.delayed(Duration.zero);
    expect(a.job.state, UploadState.canceled);
    expect(b.job.state, UploadState.canceled);
    expect(b.attempts, 0);
    expect(finished, ['b:canceled', 'a:canceled']);

    q.retry(a.job);
    await Future<void>.delayed(Duration.zero);
    expect(a.job.state, UploadState.running);
    expect(a.attempts, 2);
  });

  test(
    'running cancellation is visible immediately and starts the next job',
    () async {
      final q = UploadQueue(concurrency: 1);
      final a = _Job('a'), b = _Job('b');
      q.addAll([a.job, b.job]);
      await Future<void>.delayed(Duration.zero);

      q.cancel(a.job);
      expect(a.job.state, UploadState.cancelling);

      await Future<void>.delayed(Duration.zero);
      expect(a.job.state, UploadState.canceled);
      expect(b.job.state, UploadState.running);
    },
  );

  test(
    'restores terminal history without running it and removes it cleanly',
    () async {
      final q = UploadQueue();
      var ran = false;
      var removed = false;
      var notifications = 0;
      q.addListener(() => notifications++);
      final job = UploadJob(
        name: 'restored.bin',
        dir: '/d',
        size: 10,
        historyId: 'native-1',
        onRemove: () => removed = true,
        run: (token, onProgress) async {
          ran = true;
        },
      )..state = UploadState.failed;

      q.addHistory(job);
      await Future<void>.delayed(Duration.zero);
      expect(q.jobs, [job]);
      expect(job.state, UploadState.failed);
      expect(ran, isFalse);
      expect(notifications, 1);

      q.remove(job);
      expect(q.jobs, isEmpty);
      expect(removed, isTrue);
      expect(notifications, 2);
    },
  );

  test('normal completion wins over a late cancellation', () async {
    final q = UploadQueue(concurrency: 1);
    final job = UploadJob(
      name: 'late-cancel.bin',
      dir: '/d',
      size: 10,
      run: (token, onProgress) async {
        token.cancel();
      },
    );

    q.add(job);
    await Future<void>.delayed(Duration.zero);

    expect(job.state, UploadState.succeeded);
    expect(job.sent, 10);
  });

  test(
    'remove waits for a cancelling job to finish before removing it',
    () async {
      final q = UploadQueue(concurrency: 1);
      final a = _Job('a'), b = _Job('b');
      q.addAll([a.job, b.job]);
      await Future<void>.delayed(Duration.zero);

      q.remove(a.job);
      expect(a.job.state, UploadState.cancelling);
      expect(q.jobs, contains(a.job));

      await Future<void>.delayed(Duration.zero);
      expect(q.jobs, isNot(contains(a.job)));
      expect(q.jobs, contains(b.job));
      expect(b.job.state, UploadState.running);
    },
  );

  test('errors mark the job failed and keep the error', () async {
    final q = UploadQueue();
    final a = _Job('a');
    q.add(a.job);
    await Future<void>.delayed(Duration.zero);
    a.attempt!.completeError(DioException(requestOptions: RequestOptions()));
    await Future<void>.delayed(Duration.zero);
    expect(a.job.state, UploadState.failed);
    expect(a.job.error, isA<DioException>());

    q.clearFinished();
    expect(q.jobs, isEmpty);
  });
}
