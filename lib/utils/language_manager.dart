import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageManager {
  static const String _languageKey = 'app_language';
  static const String _systemLanguageValue = 'system';
  
  static LanguageManager? _instance;
  static LanguageManager get instance => _instance ??= LanguageManager._();
  
  LanguageManager._();
  
  // 支持的语言
  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(
      code: _systemLanguageValue,
      name: 'followSystem',
      locale: null,
    ),
    LanguageOption(
      code: 'zh',
      name: 'simplifiedChinese',
      locale: Locale('zh'),
    ),
    LanguageOption(
      code: 'en',
      name: 'english',
      locale: Locale('en'),
    ),
  ];
  
  // 获取保存的语言代码
  Future<String> getSavedLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? _systemLanguageValue;
  }
  
  // 保存语言代码
  Future<void> saveLanguageCode(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }
  
  // 获取保存的语言选项
  Future<LanguageOption> getSavedLanguageOption() async {
    final languageCode = await getSavedLanguageCode();
    return supportedLanguages.firstWhere(
      (option) => option.code == languageCode,
      orElse: () => supportedLanguages.first,
    );
  }
  
  // 根据语言代码获取Locale
  Future<Locale?> getLocaleFromCode(String languageCode) async {
    if (languageCode == _systemLanguageValue) {
      return null; // 跟随系统
    }
    
    final option = supportedLanguages.firstWhere(
      (option) => option.code == languageCode,
      orElse: () => supportedLanguages.first,
    );
    
    return option.locale;
  }
  
  // 获取当前应该使用的Locale
  Future<Locale?> getCurrentLocale() async {
    final languageCode = await getSavedLanguageCode();
    return await getLocaleFromCode(languageCode);
  }
  
  // 清除语言设置（恢复为跟随系统）
  Future<void> clearLanguageSetting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_languageKey);
  }
}

class LanguageOption {
  final String code;
  final String name; // 对应本地化键名
  final Locale? locale;
  
  const LanguageOption({
    required this.code,
    required this.name,
    required this.locale,
  });
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LanguageOption && other.code == code;
  }
  
  @override
  int get hashCode => code.hashCode;
}
