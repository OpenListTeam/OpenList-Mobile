import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef WebBrowserAction = Future<bool> Function();
typedef WebBrowserStartAction = Future<void> Function();

class WebBrowserManager {
  WebBrowserManager._();

  static final instance = WebBrowserManager._();

  final enabled = true.obs;
  final running = false.obs;

  WebBrowserAction? _stopAction;
  WebBrowserStartAction? _startAction;
  late SharedPreferences _preferences;
  int _operationVersion = 0;

  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
    enabled.value = _preferences.getBool('web_browser_enabled') ?? true;
  }

  void register({
    required WebBrowserAction stop,
    required WebBrowserStartAction start,
  }) {
    _stopAction = stop;
    _startAction = start;
  }

  void unregister() {
    _stopAction = null;
    _startAction = null;
    running.value = false;
  }

  Future<bool> stop() async {
    final action = _stopAction;
    if (action == null) return !running.value;
    final stopped = await action();
    if (stopped) running.value = false;
    return stopped;
  }

  Future<void> enableAndStart() async {
    final operationVersion = ++_operationVersion;
    if (!await _setEnabled(true) ||
        operationVersion != _operationVersion ||
        !enabled.value) {
      return;
    }
    await _startAction?.call();
  }

  Future<bool> setEnabled(bool value) async {
    _operationVersion++;
    return _setEnabled(value);
  }

  Future<bool> _setEnabled(bool value) async {
    if (!value && !await stop()) return false;
    enabled.value = value;
    await _preferences.setBool('web_browser_enabled', value);
    return true;
  }
}
