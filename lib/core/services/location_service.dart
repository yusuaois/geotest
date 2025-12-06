import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:triggeo/core/services/notification_service.dart';
import 'package:triggeo/data/models/reminder_location.dart';
import 'package:triggeo/data/repositories/reminder_repository.dart';
import 'package:triggeo/core/utils/geofence_calculator.dart';

// --- 必须是顶级函数 (Top-level function) ---
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ReminderLocationAdapter());
  Hive.registerAdapter(ReminderTypeAdapter());
  await Hive.openBox<ReminderLocation>(ReminderRepository.boxName);
  
  final notificationPlugin = FlutterLocalNotificationsPlugin();
  final box = Hive.box<ReminderLocation>(ReminderRepository.boxName);
  final notificationService = NotificationService(); // 确保 NotificationService 能在 Isolate 使用

  // 冷却池
  final Map<String, DateTime> cooldowns = {};

  service.on('stopService').listen((event) => service.stopSelf());

  // Android 前台服务通知配置 (必须有，否则后台服务会被系统杀掉)
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  // 开始监听位置
  Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // 降低到 5 米以提高测试灵敏度
    ),
  ).listen((Position position) async {
    // 1. 发送位置给 UI
    service.invoke('update', {
      "lat": position.latitude,
      "lng": position.longitude,
    });

    // 2. 更新前台通知内容 (可选，用于调试确认服务在运行)
    if (service is AndroidServiceInstance) {
       service.setForegroundNotificationInfo(
         title: "Triggeo 正在运行",
         content: "当前位置: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}",
       );
    }

    final userLoc = LatLng(position.latitude, position.longitude);
    
    // 3. 遍历提醒
    // 注意：必须重新从 box 获取 values，因为 box 数据可能更新
    for (var reminder in box.values.where((r) => r.isActive)) {
      final targetLoc = LatLng(reminder.latitude, reminder.longitude);
      
      bool isInside = GeofenceCalculator.isInRadius(userLoc, targetLoc, reminder.radius);

      if (isInside) {
        final lastTrigger = cooldowns[reminder.id];
        // 冷却逻辑：如果从未触发过，或距离上次触发超过 2 分钟 (测试用短一点)
        if (lastTrigger == null || DateTime.now().difference(lastTrigger).inMinutes > 2) {
            
            // 触发通知
            await notificationPlugin.show(
              reminder.id.hashCode,
              "到达提醒: ${reminder.name}",
              "您已进入目标区域 (距离 ${GeofenceCalculator.calculateDistance(userLoc, targetLoc).toInt()} 米)",
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'triggeo_alert', // 必须与 NotificationService.channelIdAlert 一致
                  '位置到达提醒',
                  importance: Importance.max,
                  priority: Priority.high,
                  fullScreenIntent: true,
                  playSound: true,
                ),
              ),
            );

            // 更新冷却
            cooldowns[reminder.id] = DateTime.now();
        }
      } else {
        // 如果离开了区域，可以考虑重置冷却（可选），以便下次进入立即触发
        cooldowns.remove(reminder.id);
      }
    }
  });
}

// --- 主应用使用的管理类 ---
class LocationService {
  final service = FlutterBackgroundService();

  Future<void> initialize() async {
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        // 这里必须引用上面的顶级函数
        onStart: onStart,
        autoStart: false, // 我们希望用户手动开启
        isForegroundMode: true,
        notificationChannelId: NotificationService.channelIdBackground,
        initialNotificationTitle: 'Triggeo 服务初始化',
        initialNotificationContent: '准备开始位置检测...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  // 请求权限的辅助方法
  Future<bool> requestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. 检查定位服务是否开启
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('定位服务未开启');
      return false;
    }

    // 2. 检查权限状态
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // 3. 如果被拒绝，发起请求
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('定位权限被拒绝');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('定位权限被永久拒绝');
      return false;
    }

    return true;
  }

  // 启动服务
  Future<void> startService() async {
    final hasPermission = await requestPermission();
    if (hasPermission) {
      await service.startService();
    }
  }

  // 停止服务
  void stopService() {
    service.invoke("stopService");
  }

  // 获取位置流 (供 UI 显示用)
  Stream<Map<String, dynamic>?> get locationStream {
    return service.on('update');
  }
}

// iOS 后台特殊处理
@pragma('vm:entry-point')
bool onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}
