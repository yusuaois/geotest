import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:audioplayers/audioplayers.dart'; // 引入音频播放
import 'package:triggeo/data/models/download_task.dart';
import 'package:triggeo/data/models/offline_region.dart';
import 'package:vibration/vibration.dart'; // 引入震动
import 'package:triggeo/data/models/reminder_location.dart';
import 'package:triggeo/data/repositories/reminder_repository.dart';
import 'package:triggeo/core/utils/geofence_calculator.dart';
import 'package:triggeo/core/services/notification_service.dart'; // 确保引用了常量

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0))
    Hive.registerAdapter(ReminderLocationAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ReminderTypeAdapter());
  if (!Hive.isAdapterRegistered(2))
    Hive.registerAdapter(OfflineRegionAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(TaskStatusAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(DownloadTaskAdapter());

  await Hive.openBox<ReminderLocation>(ReminderRepository.boxName);
  await Hive.openBox('settings_box');

  final notificationPlugin = FlutterLocalNotificationsPlugin();
  final reminderBox = Hive.box<ReminderLocation>(ReminderRepository.boxName);
  final settingsBox = Hive.box('settings_box');

  final audioPlayer = AudioPlayer();

  final Map<String, DateTime> cooldowns = {};

  service.on('stopService').listen((event) => service.stopSelf());

  //Get the initial position
  final Position initialPosition = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
  );
  service.invoke('update',
      {"lat": initialPosition.latitude, "lng": initialPosition.longitude});

  Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    ),
  ).listen((Position position) async {
    service.invoke('update', {
      "lat": position.latitude,
      "lng": position.longitude,
    });

    final userLoc = LatLng(position.latitude, position.longitude);

    // 0: ringtone, 1: vibration, 2: both
    final int reminderTypeIndex =
        settingsBox.get('reminder_type', defaultValue: 2);
    final String? customRingtonePath = settingsBox.get('custom_ringtone_path');

    for (var reminder in reminderBox.values.where((r) => r.isActive)) {
      final targetLoc = LatLng(reminder.latitude, reminder.longitude);

      if (GeofenceCalculator.isInRadius(userLoc, targetLoc, reminder.radius)) {
        final lastTrigger = cooldowns[reminder.id];

        if (lastTrigger == null ||
            DateTime.now().difference(lastTrigger).inSeconds > 30) {
          // A. Visual notification
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
                playSound: false,
              ),
            ),
          );

          // B. Vibration
          if (reminderTypeIndex == 1 || reminderTypeIndex == 2) {
            if (await Vibration.hasVibrator()) {
              Vibration.vibrate(pattern: [
                0,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                500,
                1000,
                100,
                200,
                100,
                200,
                100,
                200,
                100,
                200,
                100,
                200
              ], amplitude: 255);
            }
          }

          // C. Audio
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

          // D. Floatting Window
          service.invoke('showOverlay', {
            'name': reminder.name,
            'lat': reminder.latitude,
            'lng': reminder.longitude,
          });

          cooldowns[reminder.id] = DateTime.now();
        }
      } else {
        cooldowns.remove(reminder.id);
      }
    }
  });
}

class LocationService {
  final service = FlutterBackgroundService();

  Future<void> initialize() async {
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: NotificationService.channelIdBackground,
        initialNotificationTitle: 'Triggeo 后台检测',
        initialNotificationContent: '后台定位检测中...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  Future<bool> requestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('定位服务未开启');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {

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

  Future<void> startService() async {
    final hasPermission = await requestPermission();
    if (hasPermission) {
      await service.startService();
    }
  }

  void stopService() {
    service.invoke("stopService");
  }

  Stream<Map<String, dynamic>?> get locationStream {
    return service.on('update');
  }
}

// iOS 
@pragma('vm:entry-point')
bool onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}
