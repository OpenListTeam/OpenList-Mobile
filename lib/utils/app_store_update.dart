import 'dart:io';

import 'package:flutter/services.dart';

class AppStoreUpdate {
  static const MethodChannel _channel = MethodChannel('openlist/app_store_update');

  static Future<bool> checkAndShowUpdate() async {
    if (!Platform.isIOS) {
      return false;
    }

    final result = await _channel.invokeMethod<bool>('checkAndShowUpdate');
    return result ?? false;
  }
}
