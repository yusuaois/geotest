import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:triggeo/data/repositories/reminder_repository.dart';
import 'core/services/notification_service.dart';
import 'core/services/location_service.dart';
import 'features/settings/theme_controller.dart';
import 'app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  await ReminderRepository.init();

  // 打开设置存储箱
  await Hive.openBox('settings_box');
  
  // 初始化核心服务
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  final locationService = LocationService();
  await locationService.initialize();

  runApp(
    const ProviderScope(
      child: TriggeoApp(),
    ),
  );
}

class TriggeoApp extends ConsumerWidget { // 改为 ConsumerWidget 以监听 Riverpod
  const TriggeoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 监听主题状态
    final themeState = ref.watch(themeControllerProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        
        // 2. 决定使用哪个 ColorScheme
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        if (lightDynamic != null && darkDynamic != null && themeState.useDynamicColor) {
          // A. 如果系统支持动态色且用户开启了开关 -> 使用系统色
          lightScheme = lightDynamic.harmonized();
          darkScheme = darkDynamic.harmonized();
        } else {
          // B. 否则 -> 使用自定义种子颜色生成
          lightScheme = ColorScheme.fromSeed(
            seedColor: themeState.customSeedColor,
          );
          darkScheme = ColorScheme.fromSeed(
            seedColor: themeState.customSeedColor,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp.router(
          title: 'Triggeo',
          // 3. 配置浅色主题
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightScheme,
            // 可以在这里统一配置 AppBar, Card 等组件样式
            appBarTheme: AppBarTheme(
              centerTitle: true,
              backgroundColor: lightScheme.surface,
              surfaceTintColor: Colors.transparent, // 避免滚动时变色
            ),
          ),
          
          // 4. 配置深色主题
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkScheme,
            appBarTheme: AppBarTheme(
              centerTitle: true,
              backgroundColor: darkScheme.surface,
              surfaceTintColor: Colors.transparent,
            ),
          ),
          
          // 5. 决定当前显示模式
          themeMode: _getThemeMode(themeState.mode),
          
          routerConfig: router,
        );
      },
    );
  }

  // 辅助方法：将内部枚举转换为 Flutter ThemeMode
  ThemeMode _getThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }
}