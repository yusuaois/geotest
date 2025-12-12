import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum AppThemeMode {
  system,
  light,
  dark,
}

class ThemeState {
  final AppThemeMode mode;
  final bool useDynamicColor;
  final Color customSeedColor;

  ThemeState({
    required this.mode,
    required this.useDynamicColor,
    required this.customSeedColor,
  });

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
  // Hive Box
  static const String _boxName = 'settings_box';
  static const String _keyMode = 'theme_mode';
  static const String _keyDynamic = 'use_dynamic_color';
  static const String _keyColor = 'custom_seed_color';

  @override
  ThemeState build() {
    final box = Hive.box(_boxName);

    final int modeIndex = box.get(_keyMode, defaultValue: 0);
    final bool useDynamic = box.get(_keyDynamic, defaultValue: true);
    final int colorValue = box.get(_keyColor, defaultValue: 0xFF2196F3);

    return ThemeState(
      mode: AppThemeMode.values[modeIndex],
      useDynamicColor: useDynamic,
      customSeedColor: Color(colorValue),
    );
  }

  void setThemeMode(AppThemeMode mode) {
    state = state.copyWith(mode: mode);
    Hive.box(_boxName).put(_keyMode, mode.index);
  }

  void toggleDynamicColor(bool value) {
    state = state.copyWith(useDynamicColor: value);
    Hive.box(_boxName).put(_keyDynamic, value);
  }

  void setCustomSeedColor(Color color) {
    state = state.copyWith(customSeedColor: color);
    Hive.box(_boxName).put(_keyColor, color.toARGB32());
  }
}

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeState>(() {
  return ThemeController();
});
