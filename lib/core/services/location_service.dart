import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:audioplayers/audioplayers.dart'; // 引入音频播放
import 'package:vibration/vibration.dart'; // 引入震动
import 'package:triggeo/data/models/reminder_location.dart';
import 'package:triggeo/data/repositories/reminder_repository.dart';
import 'package:triggeo/core/utils/geofence_calculator.dart';
import 'package:triggeo/core/services/notification_service.dart'; // 确保引用了常量
import 'package:triggeo/core/services/overlay_service.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // 1. 初始化 Hive 和 Adapter
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0))
    Hive.registerAdapter(ReminderLocationAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ReminderTypeAdapter());

  // 2. 打开所有需要的 Box
  await Hive.openBox<ReminderLocation>(ReminderRepository.boxName);
  await Hive.openBox('settings_box'); // 打开设置盒子

  final notificationPlugin = FlutterLocalNotificationsPlugin();
  final reminderBox = Hive.box<ReminderLocation>(ReminderRepository.boxName);
  final settingsBox = Hive.box('settings_box');

  // 初始化音频播放器 (后台专用)
  final audioPlayer = AudioPlayer();

  final Map<String, DateTime> cooldowns = {};

  service.on('stopService').listen((event) => service.stopSelf());

  Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    ),
  ).listen((Position position) async {
    service.invoke('update', {
      "lat": position.latitude,
      "lng": position.longitude,
    });

    final userLoc = LatLng(position.latitude, position.longitude);

    // 读取最新的全局设置 (每次检测都读取，确保设置实时生效)
    // 0: ringtone, 1: vibration, 2: both
    final int reminderTypeIndex =
        settingsBox.get('reminder_type', defaultValue: 2);
    final String? customRingtonePath = settingsBox.get('custom_ringtone_path');

    for (var reminder in reminderBox.values.where((r) => r.isActive)) {
      final targetLoc = LatLng(reminder.latitude, reminder.longitude);

      if (GeofenceCalculator.isInRadius(userLoc, targetLoc, reminder.radius)) {
        final lastTrigger = cooldowns[reminder.id];

        // 冷却时间 2 分钟
        if (lastTrigger == null ||
            DateTime.now().difference(lastTrigger).inMinutes > 2) {
          // A. 显示视觉通知
          await notificationPlugin.show(
            reminder.id.hashCode,
            "📍 到达提醒: ${reminder.name}",
            "您已进入目标区域",
            const NotificationDetails(
              android: AndroidNotificationDetails(
                NotificationService.channelIdAlert,
                '位置到达提醒',
                importance: Importance.max,
                priority: Priority.high,
                fullScreenIntent: true,
                playSound: false, // 我们手动控制播放，所以这里设为 false (或者设为 true 使用默认音)
              ),
            ),
          );

          // B. 触发震动
          if (reminderTypeIndex == 1 || reminderTypeIndex == 2) {
            if (await Vibration.hasVibrator() ?? false) {
              Vibration.vibrate(pattern: [0, 1000, 500, 1000]);
            }
          }

          // C. 触发铃声
          if (reminderTypeIndex == 0 || reminderTypeIndex == 2) {
            if (customRingtonePath != null &&
                File(customRingtonePath).existsSync()) {
              try {
                await audioPlayer.stop();
                await audioPlayer.play(DeviceFileSource(customRingtonePath));
              } catch (e) {
                print("后台播放失败: $e");
              }
            }
          }

          // D. 显示应用内浮窗 (需要通过主隔离区通信)
          // 发送消息给 UI Isolate
          service.invoke('showOverlay', {
            'name': reminder.name,
            'lat': reminder.latitude,
            'lng': reminder.longitude,
          });

          // 更新冷却
          cooldowns[reminder.id] = DateTime.now();
        }
      } else {
        // 离开区域移除冷却，实现“离开再进入”可再次触发
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
