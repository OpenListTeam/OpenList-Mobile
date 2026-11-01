import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static ThemeController get to => Get.find();

  static const String _kThemeMode = 'theme_mode';

  final _themeMode = ThemeMode.system.obs;

  ThemeMode get themeMode => _themeMode.value;

  @override
  void onInit() {
    super.onInit();
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_kThemeMode);

      if (savedMode != null) {
        _themeMode.value = _parseThemeMode(savedMode);
      }
    } catch (e) {
      debugPrint('Failed to load saved theme: $e');
    }
  }

  Future<void> changeTheme(ThemeMode mode) async {
    try {
      _themeMode.value = mode;

      // Apply theme immediately
      Get.changeThemeMode(mode);

      // Save theme preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kThemeMode, mode.name);
    } catch (e) {
      debugPrint('Failed to change theme: $e');
    }
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String getThemeName() {
    switch (_themeMode.value) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }
}
