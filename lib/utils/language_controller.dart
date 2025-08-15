import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openlist_mobile/utils/language_manager.dart';
import 'package:openlist_mobile/generated/l10n.dart';

class LanguageController extends GetxController {
  static LanguageController get to => Get.find();
  
  final _currentLanguageOption = LanguageManager.supportedLanguages.first.obs;
  final _locale = Rxn<Locale>();
  
  LanguageOption get currentLanguageOption => _currentLanguageOption.value;
  Locale? get locale => _locale.value;
  
  @override
  void onInit() {
    super.onInit();
    _loadSavedLanguage();
  }
  
  // 加载保存的语言设置
  Future<void> _loadSavedLanguage() async {
    try {
      final savedOption = await LanguageManager.instance.getSavedLanguageOption();
      _currentLanguageOption.value = savedOption;
      
      final savedLocale = await LanguageManager.instance.getCurrentLocale();
      _locale.value = savedLocale;
    } catch (e) {
      debugPrint('Failed to load saved language: $e');
    }
  }
  
  // 切换语言
  Future<void> changeLanguage(LanguageOption option) async {
    try {
      _currentLanguageOption.value = option;
      
      // 保存语言设置
      await LanguageManager.instance.saveLanguageCode(option.code);
      
      // 更新locale
      if (option.locale != null) {
        _locale.value = option.locale;
        Get.updateLocale(option.locale!);
      } else {
        // 跟随系统语言
        final systemLocale = Get.deviceLocale ?? const Locale('en');
        // 检查系统语言是否被支持
        final supportedSystemLocale = _getSupportedLocale(systemLocale);
        _locale.value = null; // 保持null表示跟随系统
        Get.updateLocale(supportedSystemLocale);
      }
      
    } catch (e) {
      debugPrint('Failed to change language: $e');
    }
  }
  
  // 获取支持的语言环境
  Locale _getSupportedLocale(Locale deviceLocale) {
    // 检查是否直接支持
    for (final option in LanguageManager.supportedLanguages) {
      if (option.locale?.languageCode == deviceLocale.languageCode) {
        return option.locale!;
      }
    }
    
    // 默认返回英语
    return const Locale('en');
  }
  
  // 获取当前应该使用的locale（考虑跟随系统的情况）
  Locale getEffectiveLocale() {
    if (_locale.value != null) {
      return _locale.value!;
    }
    
    // 如果是跟随系统，返回系统语言或默认语言
    final systemLocale = Get.deviceLocale ?? const Locale('en');
    return _getSupportedLocale(systemLocale);
  }
}

// 语言选择器组件
class LanguageSelector extends StatelessWidget {
  final VoidCallback? onLanguageChanged;
  
  const LanguageSelector({
    Key? key,
    this.onLanguageChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GetBuilder<LanguageController>(
      builder: (controller) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...LanguageManager.supportedLanguages.map(
              (option) => RadioListTile<LanguageOption>(
                title: Text(_getLocalizedLanguageName(option)),
                value: option,
                groupValue: controller.currentLanguageOption,
                onChanged: (LanguageOption? value) async {
                  if (value != null) {
                    await controller.changeLanguage(value);
                    onLanguageChanged?.call();
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }
  
  String _getLocalizedLanguageName(LanguageOption option) {
    switch (option.name) {
      case 'followSystem':
        return S.current.followSystem;
      case 'simplifiedChinese':
        return S.current.simplifiedChinese;
      case 'english':
        return S.current.english;
      default:
        return option.name;
    }
  }
}
