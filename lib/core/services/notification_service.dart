import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Channel ID
  static const String channelIdBackground = 'triggeo_background_service';
  static const String channelIdAlert = 'triggeo_arrival_alert';

  Future<void> initialize() async {
    // Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    await _createNotificationChannel(
      channelIdBackground,
      '后台运行服务',
      '保持应用在后台检测位置',
      Importance.low,
    );

    await _createNotificationChannel(
      channelIdAlert,
      '位置到达提醒',
      '当到达目的地时发出提醒',
      Importance.max,
      playSound: true,
    );
  }

  Future<void> _createNotificationChannel(
      String id, String name, String desc, Importance importance,
      {bool playSound = false}) async {
    if (Platform.isAndroid) {
      final AndroidNotificationChannel channel = AndroidNotificationChannel(
        id,
        name,
        description: desc,
        importance: importance,
        playSound: playSound,
      );
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> showArrivalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelIdAlert,
          '位置到达提醒',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true, 
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> showProgressNotification({
    required int id,
    required int progress,
    required int max,
    required String title,
    required String body,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'offline_map_download_channel', // Channel ID
      'Map Downloads', // Channel Name
      channelDescription: 'Shows progress of offline map downloads',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: max,
      progress: progress,
      onlyAlertOnce: true, 
      ongoing: true, 
      autoCancel: false,
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
