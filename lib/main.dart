import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:path_provider/path_provider.dart';
import 'package:triggeo/core/constants/global_config.dart';
import 'package:triggeo/data/models/download_task.dart';
import 'package:triggeo/data/models/offline_region.dart';
import 'package:triggeo/data/models/reminder_location.dart';
import 'package:triggeo/data/repositories/reminder_repository.dart';
import 'package:triggeo/l10n/app_localizations.dart';
import 'core/services/notification_service.dart';
import 'core/services/location_service.dart';
import 'features/settings/theme_controller.dart';
import 'app_router.dart';

// 全局 key 用于访问 MaterialApp 的 context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Hive.initFlutter();

  Hive.registerAdapter(ReminderLocationAdapter());
  Hive.registerAdapter(ReminderTypeAdapter());
  Hive.registerAdapter(OfflineRegionAdapter());
  Hive.registerAdapter(TaskStatusAdapter());
  Hive.registerAdapter(DownloadTaskAdapter());

  await ReminderRepository.init();

  // Open the settings box
  await Hive.openBox('settings_box');

  final docDir = await getApplicationDocumentsDirectory();
  globalOfflineMapsDir = '${docDir.path}/offline_maps';

  runApp(
    const ProviderScope(
      child: TriggeoApp(),
    ),
  );
}

class TriggeoApp extends ConsumerStatefulWidget {
  const TriggeoApp({super.key});

  @override
  ConsumerState<TriggeoApp> createState() => _TriggeoAppState();
}

class _TriggeoAppState extends ConsumerState<TriggeoApp> {
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();
  bool _servicesInitialized = false;

  @override
  void initState() {
    super.initState();
    // 在应用启动后初始化服务
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  Future<void> _initializeServices() async {
    if (_servicesInitialized) return;
    
    final BuildContext? context = navigatorKey.currentContext;
    if (context == null) {
      // 如果 context 还未就绪，稍后重试
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeServices();
      });
      return;
    }

    try {
      final l10n = AppLocalizations.of(context)!;
      
      // 初始化通知服务
      await _notificationService.initialize(l10n);
      
      // 初始化位置服务
      await _locationService.initialize(l10n, context);
      await _locationService.requestPermission();
      
      _servicesInitialized = true;
      
      // 隐藏启动画面
      FlutterNativeSplash.remove();
    } catch (e) {
      print('Service initialization error: $e');
      // 重试
      Future.delayed(const Duration(seconds: 1), _initializeServices);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeControllerProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        if (lightDynamic != null &&
            darkDynamic != null &&
            themeState.useDynamicColor) {
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
          navigatorKey: navigatorKey, // 添加全局 key
          title: 'Triggeo',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightScheme,
            bottomAppBarTheme: const BottomAppBarThemeData(
              color: Colors.transparent,
              elevation: 0,
            ),
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
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            const Locale('zh', 'CN'), // Chinese
            const Locale('en', 'US'), // English
          ],
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