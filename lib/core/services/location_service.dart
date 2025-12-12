import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';
import 'package:triggeo/data/models/download_task.dart';
import 'package:triggeo/data/models/offline_region.dart';
import 'package:triggeo/l10n/app_localizations.dart';
import 'package:vibration/vibration.dart';
import 'package:triggeo/data/models/reminder_location.dart';
import 'package:triggeo/data/repositories/reminder_repository.dart';
import 'package:triggeo/core/utils/geofence_calculator.dart';
import 'package:triggeo/core/services/notification_service.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service, AppLocalizations l10n,
    BuildContext context) async {
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

  //Get the initial position
  try {
    final Position initialPosition = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    service.invoke('update',
        {"lat": initialPosition.latitude, "lng": initialPosition.longitude});
  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.mapGetLocationFailed(e))));
    debugPrint("BackgroundService: $e");
  }

  Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      // TODO 设置中调整位置更新频率
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
            l10n.locationServiceAlertBodyTitle(reminder.name),
            l10n.locationServiceAlertBodySubtitle,
            NotificationDetails(
              android: AndroidNotificationDetails(
                NotificationService.channelIdAlert,
                l10n.notificationChannelAlertName,
                importance: Importance.max,
                priority: Priority.high,
                fullScreenIntent: true,
                playSound: false,
              ),
            ),
          );

          // B. Vibration
          if (reminderTypeIndex == 1 || reminderTypeIndex == 2) {
            // TODO 设置中调整震动模式
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
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(l10n.settingsRintonePlayFiled(e)),
                ));
                debugPrint("AudioPlayer Error: $e");
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

  Future<void> initialize(AppLocalizations l10n, BuildContext context) async {
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: (ServiceInstance service) => onStart(service, l10n, context),
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: NotificationService.channelIdBackground,
        initialNotificationTitle: l10n.backgroundServiceTitle,
        initialNotificationContent: l10n.backgroundServiceContent,
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: (ServiceInstance service) =>
            onStart(service, l10n, context),
        onBackground: onIosBackground,
      ),
    );
  }

  Future<bool> requestPermission() async {
    final status = await Permission.location.status;
    if (!status.isGranted) {
      final result = await Permission.location.request();
      return result.isGranted;
    }
    return true;
  }

  Future<bool> startService() async {
    final hasPermission = await requestPermission();
    if (hasPermission) {
      final isRunning = await service.isRunning();
      if (!isRunning) {
        await service.startService();
      }
      return true;
    }
    return false;
  }

  Future<Map<String, dynamic>?> getCurrentPosition(BuildContext context) async {
    bool hasPermission = await requestPermission();
    if (!hasPermission) return null;

    try {
      Position? position = await Geolocator.getLastKnownPosition();

      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      return {
        "lat": position.latitude,
        "lng": position.longitude,
      };
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.mapGetLocationFailed(e)),
      ));
      debugPrint("Error getting current location: $e");
      return null;
    }
  }

  void stopService() {
    service.invoke("stopService");
  }

  Stream<Map<String, dynamic>?> get locationStream {
    final Stream<Map<String, dynamic>?> initialStream =
        Stream.fromFuture(() async {
      try {
        Position? pos = await Geolocator.getLastKnownPosition();

        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 20),
          ),
        );
        return {
          "lat": pos.latitude,
          "lng": pos.longitude,
          "source": "initial_fetch"
        };
      } catch (e) {
        debugPrint("Stream initial fetch failed: $e");
      }
      return null;
    }())
            .where((data) => data != null);

    final Stream<Map<String, dynamic>?> liveStream = service.on('update');

    return Rx.merge([initialStream, liveStream]);
  }
}

// iOS
@pragma('vm:entry-point')
bool onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}
