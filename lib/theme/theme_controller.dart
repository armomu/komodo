import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// 主题模式存储值
/// system = null（未存储，手动跟随系统）
enum AppThemeMode { light, dark, system }

/// 主题控制器 - 管理应用主题状态
class ThemeController extends GetxController {
  static ThemeController get to => Get.find();

  final _box = GetStorage();
  final _themeKey = 'theme_mode'; // null=system, 'light', 'dark'

  // 存储值 → AppThemeMode
  final _themeMode = AppThemeMode.system.obs;

  /// 当前是否为深色模式（用于兼容旧逻辑）
  bool get isDarkMode => _themeMode.value == AppThemeMode.dark;

  /// 当前 ThemeMode
  ThemeMode get themeMode {
    switch (_themeMode.value) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  /// 当前 AppThemeMode
  AppThemeMode get appThemeMode => _themeMode.value;

  String get curThemeMode {
    switch (_themeMode.value) {
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.system:
        return 'system';
    }
  }

  @override
  void onInit() {
    super.onInit();
    // 从本地存储读取主题设置，null = 跟随系统
    final stored = _box.read<String?>(_themeKey);
    if (stored == 'light') {
      _themeMode.value = AppThemeMode.light;
    } else if (stored == 'dark') {
      _themeMode.value = AppThemeMode.dark;
    } else {
      _themeMode.value = AppThemeMode.system; // 默认跟随系统
    }
    Get.changeThemeMode(themeMode);
  }

  /// 切换主题
  void toggleTheme() {
    _themeMode.value = _themeMode.value == AppThemeMode.dark
        ? AppThemeMode.light
        : AppThemeMode.dark;
    _saveAndApply();
  }

  /// 设置为浅色模式
  void setLightMode() {
    _themeMode.value = AppThemeMode.light;
    _saveAndApply();
  }

  /// 设置为深色模式
  void setDarkMode() {
    _themeMode.value = AppThemeMode.dark;
    _saveAndApply();
  }

  /// 跟随系统主题
  void setSystemMode() {
    _themeMode.value = AppThemeMode.system;
    _saveAndApply();
  }

  void _saveAndApply() {
    switch (_themeMode.value) {
      case AppThemeMode.light:
        _box.write(_themeKey, 'light');
        break;
      case AppThemeMode.dark:
        _box.write(_themeKey, 'dark');
        break;
      case AppThemeMode.system:
        _box.remove(_themeKey); // 跟随系统，不存储具体值
        break;
    }
    Get.changeThemeMode(themeMode);
    update();
  }
}
