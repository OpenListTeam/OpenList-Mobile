import 'package:flutter_test/flutter_test.dart';
import 'package:openlist_mobile/utils/web_browser_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final manager = WebBrowserManager.instance;

  tearDown(() {
    manager.unregister();
  });

  test('loads persisted disabled state', () async {
    SharedPreferences.setMockInitialValues({'web_browser_enabled': false});

    await manager.initialize();

    expect(manager.enabled.value, isFalse);
    expect(manager.running.value, isFalse);
  });

  test('disabling stops browser and persists preference', () async {
    SharedPreferences.setMockInitialValues({});
    await manager.initialize();
    manager.running.value = true;
    var stopCalls = 0;
    manager.register(
      stop: () async {
        stopCalls++;
        return true;
      },
      start: () async {},
    );

    final disabled = await manager.setEnabled(false);
    final preferences = await SharedPreferences.getInstance();

    expect(disabled, isTrue);
    expect(stopCalls, 1);
    expect(manager.enabled.value, isFalse);
    expect(manager.running.value, isFalse);
    expect(preferences.getBool('web_browser_enabled'), isFalse);
  });

  test('failed stop keeps browser enabled and running', () async {
    SharedPreferences.setMockInitialValues({'web_browser_enabled': true});
    await manager.initialize();
    manager.running.value = true;
    manager.register(
      stop: () async => false,
      start: () async {},
    );

    final disabled = await manager.setEnabled(false);
    final preferences = await SharedPreferences.getInstance();

    expect(disabled, isFalse);
    expect(manager.enabled.value, isTrue);
    expect(manager.running.value, isTrue);
    expect(preferences.getBool('web_browser_enabled'), isTrue);
  });

  test('restart enables preference before starting browser', () async {
    SharedPreferences.setMockInitialValues({'web_browser_enabled': false});
    await manager.initialize();
    var startCalls = 0;
    manager.register(
      stop: () async => true,
      start: () async {
        startCalls++;
        expect(manager.enabled.value, isTrue);
      },
    );

    await manager.enableAndStart();
    final preferences = await SharedPreferences.getInstance();

    expect(startCalls, 1);
    expect(preferences.getBool('web_browser_enabled'), isTrue);
  });

  test('operation queue continues after a failed callback', () async {
    SharedPreferences.setMockInitialValues({'web_browser_enabled': true});
    await manager.initialize();
    manager.running.value = true;
    var shouldThrow = true;
    manager.register(
      stop: () async {
        if (shouldThrow) {
          shouldThrow = false;
          throw StateError('stop failed');
        }
        return true;
      },
      start: () async {},
    );

    await expectLater(manager.stop(), throwsStateError);
    final stopped = await manager.stop();

    expect(stopped, isTrue);
    expect(manager.running.value, isFalse);
  });

  test('newer disable cancels an in-flight restart', () async {
    SharedPreferences.setMockInitialValues({'web_browser_enabled': false});
    await manager.initialize();
    var startCalls = 0;
    manager.register(
      stop: () async => true,
      start: () async {
        startCalls++;
      },
    );

    final restart = manager.enableAndStart();
    final disable = manager.setEnabled(false);
    await Future.wait([restart, disable]);
    final preferences = await SharedPreferences.getInstance();

    expect(startCalls, 0);
    expect(manager.enabled.value, isFalse);
    expect(preferences.getBool('web_browser_enabled'), isFalse);
  });
}
