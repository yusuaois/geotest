import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 通道 ID
  static const String channelIdBackground = 'triggeo_background_service';
  static const String channelIdAlert = 'triggeo_arrival_alert';

  Future<void> initialize() async {
    // Android 初始化设置
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 初始化设置
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

    // 创建后台服务通知通道 (Android)
    await _createNotificationChannel(
      channelIdBackground,
      '后台运行服务',
      '保持应用在后台检测位置',
      Importance.low,
    );

    // 创建到达提醒通知通道 (Android)
    await _createNotificationChannel(
      channelIdAlert,
      '位置到达提醒',
      '当你到达目的地时发出提醒',
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

  // 发送到达提醒
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
          fullScreenIntent: true, // 类似闹钟的全屏提醒
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
    );
  }
}