import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:triggeo/data/models/download_task.dart';
import 'package:triggeo/data/models/offline_region.dart';
import 'package:triggeo/data/models/reminder_location.dart';
import 'package:triggeo/data/repositories/reminder_repository.dart';
import 'core/services/notification_service.dart';
import 'core/services/location_service.dart';
import 'features/settings/theme_controller.dart';
import 'app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();

  Hive.registerAdapter(ReminderLocationAdapter()); 
  Hive.registerAdapter(ReminderTypeAdapter());
  Hive.registerAdapter(OfflineRegionAdapter());
  Hive.registerAdapter(TaskStatusAdapter());
  Hive.registerAdapter(DownloadTaskAdapter());
  
  await ReminderRepository.init();

  // Open the settings box
  await Hive.openBox('settings_box');
  
  // Initialize services
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

class TriggeoApp extends ConsumerWidget { 
  const TriggeoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeControllerProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        if (lightDynamic != null && darkDynamic != null && themeState.useDynamicColor) {
          // If support dynamic color and enabled in settings
          lightScheme = lightDynamic.harmonized();
          darkScheme = darkDynamic.harmonized();
        } else {
          // Fallback to custom seed color
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
          // Light and dark theme
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightScheme,
            // Global AppBar Theme
            appBarTheme: AppBarTheme(
              centerTitle: true,
              backgroundColor: lightScheme.surface,
              surfaceTintColor: Colors.transparent,
            ),
          ),
          
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkScheme,
            appBarTheme: AppBarTheme(
              centerTitle: true,
              backgroundColor: darkScheme.surface,
              surfaceTintColor: Colors.transparent,
            ),
          ),
          
          themeMode: _getThemeMode(themeState.mode),
          
          routerConfig: router,
        );
      },
    );
  }

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