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
  // 1. 初始化独立 Isolate 的环境
  DartPluginRegistrant.ensureInitialized();

  // 2. 在后台 Isolate 初始化 Hive
  await Hive.initFlutter();

  // 注册 Adapters (必须手动注册，因为这是全新的 Isolate)
  Hive.registerAdapter(ReminderLocationAdapter());
  Hive.registerAdapter(ReminderTypeAdapter());
  
  await Hive.openBox<ReminderLocation>(ReminderRepository.boxName);
  
  final notificationPlugin = FlutterLocalNotificationsPlugin();
  final box = Hive.box<ReminderLocation>(ReminderRepository.boxName);

  // 冷却池：防止在边缘反复触发 (ID -> 上次触发时间)
  final Map<String, DateTime> cooldowns = {};

  // 3. 监听来自 UI 的事件 (例如停止服务)
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // 4. 启动位置监听流
  // 监听位置
  Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // 移动10米检查一次
    ),
  ).listen((Position position) {
    // A. 发送数据给 UI (保持不变)
    service.invoke('update', {
      "lat": position.latitude,
      "lng": position.longitude,
    });

    // B. 【核心】地理围栏检测
    final userLoc = LatLng(position.latitude, position.longitude);
    
    // 遍历所有激活的提醒
    for (var reminder in box.values.where((r) => r.isActive)) {
      final targetLoc = LatLng(reminder.latitude, reminder.longitude);
      
      // 计算是否在范围内
      bool entered = GeofenceCalculator.isInRadius(userLoc, targetLoc, reminder.radius);

      if (entered) {
        // 检查冷却 (例如：5分钟内不重复提醒同一个点)
        final lastTrigger = cooldowns[reminder.id];
        if (lastTrigger == null || DateTime.now().difference(lastTrigger).inMinutes > 5) {
          
          // --- 触发提醒 ---
          notificationPlugin.show(
            reminder.id.hashCode, // 使用 HashCode 做 ID
            "到达提醒: ${reminder.name}",
            "您已进入目标 ${reminder.radius.toInt()} 米范围内",
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'triggeo_alert', // 必须与 NotificationService 定义的 channelIdAlert 一致
                '到达提醒',
                importance: Importance.max,
                priority: Priority.high,
                fullScreenIntent: true,
              ),
            ),
          );
          
          // 更新冷却时间
          cooldowns[reminder.id] = DateTime.now();
          
          // 可选：触发后自动关闭提醒
          // reminder.isActive = false;
          // reminder.save();
        }
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
