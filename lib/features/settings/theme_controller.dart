import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// 定义主题模式枚举
enum AppThemeMode {
  system, // 跟随系统
  light,  // 强制浅色
  dark,   // 强制深色
}

// 定义主题状态类
class ThemeState {
  final AppThemeMode mode;
  final bool useDynamicColor; // 是否使用壁纸取色
  final Color customSeedColor; // 如果不使用动态色，使用这个自定义颜色

  ThemeState({
    required this.mode,
    required this.useDynamicColor,
    required this.customSeedColor,
  });

  // 复制方法，用于状态更新
  ThemeState copyWith({
    AppThemeMode? mode,
    bool? useDynamicColor,
    Color? customSeedColor,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
      customSeedColor: customSeedColor ?? this.customSeedColor,
    );
  }
}

// Riverpod Notifier
class ThemeController extends Notifier<ThemeState> {
  // Hive Box 名称
  static const String _boxName = 'settings_box';
  static const String _keyMode = 'theme_mode';
  static const String _keyDynamic = 'use_dynamic_color';
  static const String _keyColor = 'custom_seed_color';

  @override
  ThemeState build() {
    // 1. 获取 Hive Box (假设已在 main 初始化时打开，或者在这里懒加载)
    // 注意：在实际生产中，最好将 Hive 封装在 Repository 中，这里为了简洁直接调用
    final box = Hive.box(_boxName);

    // 2. 读取保存的设置，如果没有则使用默认值
    final int modeIndex = box.get(_keyMode, defaultValue: 0);
    final bool useDynamic = box.get(_keyDynamic, defaultValue: true);
    final int colorValue = box.get(_keyColor, defaultValue: 0xFF2196F3); // 默认蓝色

    return ThemeState(
      mode: AppThemeMode.values[modeIndex],
      useDynamicColor: useDynamic,
      customSeedColor: Color(colorValue),
    );
  }

  // 切换主题模式
  void setThemeMode(AppThemeMode mode) {
    state = state.copyWith(mode: mode);
    Hive.box(_boxName).put(_keyMode, mode.index);
  }

  // 切换动态取色开关
  void toggleDynamicColor(bool value) {
    state = state.copyWith(useDynamicColor: value);
    Hive.box(_boxName).put(_keyDynamic, value);
  }

  // 设置自定义颜色
  void setCustomSeedColor(Color color) {
    state = state.copyWith(customSeedColor: color);
    Hive.box(_boxName).put(_keyColor, color.value);
  }
}

// 暴露 Provider
final themeControllerProvider = NotifierProvider<ThemeController, ThemeState>(() {
  return ThemeController();
});