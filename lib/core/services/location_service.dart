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
import 'package:audioplayers/audioplayers.dart';
import 'package:rxdart/rxdart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:triggeo/data/models/download_task.dart';
import 'package:triggeo/data/models/offline_region.dart';
import 'package:vibration/vibration.dart';
import 'package:triggeo/data/models/reminder_location.dart';
import 'package:triggeo/data/repositories/reminder_repository.dart';
import 'package:triggeo/core/utils/geofence_calculator.dart';
import 'package:triggeo/core/services/notification_service.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ReminderLocationAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(ReminderTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(OfflineRegionAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(TaskStatusAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(DownloadTaskAdapter());
  }

  await Hive.openBox<ReminderLocation>(ReminderRepository.boxName);
  await Hive.openBox('settings_box');

  final notificationPlugin = FlutterLocalNotificationsPlugin();
  final reminderBox = Hive.box<ReminderLocation>(ReminderRepository.boxName);
  final settingsBox = Hive.box('settings_box');

  final audioPlayer = AudioPlayer();

  final Map<String, DateTime> cooldowns = {};

  service.on('stopService').listen((event) => service.stopSelf());

  // 检查后台权限
  final hasPermission = await _checkBackgroundLocationPermission();
  if (!hasPermission) {
    debugPrint("后台服务: 位置权限不足，停止服务");
    service.stopSelf();
    return;
  }

  //Get the initial position
  try {
    final Position initialPosition = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    service.invoke('update',
        {"lat": initialPosition.latitude, "lng": initialPosition.longitude});
  } catch (e) {
    debugPrint("后台服务获取初始位置失败: $e");
  }

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
                debugPrint("后台播放失败: $e");
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

// 后台服务中的权限检查
Future<bool> _checkBackgroundLocationPermission() async {
  // 检查定位服务是否开启
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    debugPrint('后台服务: 定位服务未开启');
    return false;
  }

  // 检查权限
  if (Platform.isAndroid) {
    final status = await Permission.locationAlways.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      debugPrint('后台服务: 需要后台定位权限');
      return false;
    }
    return status.isGranted || status.isLimited;
  } else if (Platform.isIOS) {
    final status = await Permission.locationAlways.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      debugPrint('后台服务: 需要后台定位权限');
      return false;
    }
    return status.isGranted || status.isLimited;
  }

  return false;
}

class LocationService {
  final service = FlutterBackgroundService();

  Future<void> initialize() async {
    await _requestLocationPermissions();
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

  // 请求位置权限
  Future<bool> _requestLocationPermissions({
    BuildContext? context,
    bool showDialog = true,
    bool requireBackground = false,
  }) async {
    // 检查定位服务是否开启
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context != null && showDialog) {
        await _showLocationServiceDialog(context);
      }
      debugPrint('定位服务未开启');
      return false;
    }

    // 请求前台定位权限
    PermissionStatus status;

    if (Platform.isAndroid || Platform.isIOS) {
      // 先请求使用中的定位权限
      status = await Permission.locationWhenInUse.status;

      if (!status.isGranted && !status.isLimited) {
        status = await Permission.locationWhenInUse.request();

        if (!status.isGranted && !status.isLimited) {
          if (context != null && showDialog) {
            await _showLocationPermissionDialog(context);
          }
          debugPrint('前台定位权限被拒绝');
          return false;
        }
      }
    }

    // 如果需要后台定位权限
    if (requireBackground) {
      final backgroundStatus = await Permission.locationAlways.status;

      if (!backgroundStatus.isGranted && !backgroundStatus.isLimited) {
        if (context != null) {
          // 显示解释后台权限的对话框
          final granted = await _showBackgroundPermissionDialog(context);
          if (!granted) {
            debugPrint('后台定位权限被拒绝');
            return false;
          }
        } else {
          // 没有context，直接请求
          final result = await Permission.locationAlways.request();
          if (!result.isGranted && !result.isLimited) {
            debugPrint('后台定位权限被拒绝');
            return false;
          }
        }
      }
    }

    return true;
  }

  // 检查是否有位置权限
  Future<bool> hasLocationPermission({bool requireBackground = false}) async {
    // 检查定位服务
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    // 检查前台权限
    if (Platform.isAndroid || Platform.isIOS) {
      final foregroundStatus = await Permission.locationWhenInUse.status;
      if (!foregroundStatus.isGranted && !foregroundStatus.isLimited) {
        return false;
      }

      // 检查后台权限
      if (requireBackground) {
        final backgroundStatus = await Permission.locationAlways.status;
        return backgroundStatus.isGranted || backgroundStatus.isLimited;
      }

      return true;
    }

    return false;
  }

  // 显示定位服务对话框
  Future<void> _showLocationServiceDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('定位服务已关闭'),
          content: const Text('请打开设备定位服务以使用位置提醒功能'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Geolocator.openLocationSettings();
                Navigator.pop(context);
              },
              child: const Text('打开设置'),
            ),
          ],
        );
      },
    );
  }

  // 显示前台定位权限对话框
  Future<void> _showLocationPermissionDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('需要位置权限'),
          content: const Text(
            'Triggeo需要位置权限来：\n\n'
            '• 在地图上显示您的位置\n'
            '• 设置位置提醒\n'
            '• 在您移动时检测位置\n\n'
            '请授予位置权限以获得完整功能体验。',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('稍后'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await openAppSettings();
              },
              child: const Text('去设置'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await Permission.locationWhenInUse.request();
              },
              child: const Text('授予权限'),
            ),
          ],
        );
      },
    );
  }

  // 显示后台定位权限对话框
  Future<bool> _showBackgroundPermissionDialog(BuildContext context) async {
    Completer<bool> completer = Completer<bool>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('需要后台位置权限'),
          content: const Text(
            '为了在后台运行并检测位置提醒，Triggeo需要后台位置权限。\n\n'
            '这样即使应用在后台，您也能收到位置提醒。\n\n'
            '请授予"始终允许"位置权限。',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                completer.complete(false);
              },
              child: const Text('仅使用期间'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final result = await Permission.locationAlways.request();
                completer.complete(result.isGranted || result.isLimited);
              },
              child: const Text('始终允许'),
            ),
          ],
        );
      },
    );

    return completer.future;
  }

  Future<Map<String, dynamic>?> getCurrentPosition({
    BuildContext? context,
    bool requestPermission = true,
  }) async {
    if (requestPermission) {
      final permissionGranted = await _requestLocationPermissions(
        context: context,
        showDialog: context != null,
        requireBackground: false,
      );

      if (!permissionGranted) {
        debugPrint("获取位置: 权限被拒绝");
        return null;
      }
    }

    try {
      Position? position = await Geolocator.getLastKnownPosition();

      position ??= await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 5),
      );

      return {
        "lat": position.latitude,
        "lng": position.longitude,
        "accuracy": position.accuracy,
        "timestamp": position.timestamp?.millisecondsSinceEpoch,
      };
    } catch (e) {
      debugPrint("Error getting current location: $e");
      return null;
    }
  }

  void stopService() {
    service.invoke("stopService");
  }

  Stream<Map<String, dynamic>?> get locationStream {
    // Future to Stream
    final Stream<Map<String, dynamic>?> cachedStream = Stream.fromFuture(
      Geolocator.getLastKnownPosition(),
    ).map((position) {
      if (position != null) {
        debugPrint("LocationService: Used cached location");
        return {
          "lat": position.latitude,
          "lng": position.longitude,
          "source": "cached"
        };
      }
      return null;
    }).where((data) => data != null); // Filter out null values

    final Stream<Map<String, dynamic>?> liveStream = service.on('update');

    // cachedStream first，then liveStream
    return Rx.concat([cachedStream, liveStream]);
  }
}

// iOS
@pragma('vm:entry-point')
bool onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}
