import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:triggeo/core/services/notification_service.dart';

// --- 必须是顶级函数 (Top-level function) ---
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // 1. 初始化独立 Isolate 的环境
  DartPluginRegistrant.ensureInitialized();

  // 2. 初始化通知插件 (用于更新前台通知)
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 3. 监听来自 UI 的事件 (例如停止服务)
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // 4. 启动位置监听流
  // 使用高精度，但为了省电可以适当调整 distanceFilter
  const LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // 移动10米才更新
  );

  Geolocator.getPositionStream(locationSettings: locationSettings)
      .listen((Position? position) async {
    if (position != null) {
      // A. 更新前台通知，让用户知道 App 正在检测
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          flutterLocalNotificationsPlugin.show(
            888, // 固定的通知 ID
            'Triggeo 正在运行',
            '当前位置: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                NotificationService.channelIdBackground,
                '后台运行服务',
                icon:
                    'ic_bg_service_small', // 确保 android/app/src/main/res/drawable 有此图标，或者使用 @mipmap/ic_launcher
                ongoing: true,
              ),
            ),
          );
        }
      }

      // B. 发送位置给主 UI (通过 Port)
      service.invoke(
        'update',
        {
          "lat": position.latitude,
          "lng": position.longitude,
          "speed": position.speed,
          "heading": position.heading,
        },
      );

      // C. TODO: 这里未来将加入【地理围栏检测逻辑】
      // 为了性能，检测逻辑最好放在后台 Isolate 计算，
      // 到达后直接在这里触发 NotificationService.showArrivalNotification
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
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
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
