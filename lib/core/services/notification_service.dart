import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Channel ID
  static const String channelIdBackground = 'triggeo_background_service';
  static const String channelIdAlert = 'triggeo_arrival_alert';
  static const String channelIdDownload = 'triggeo_download_progress';
  static const int _downloadNotificationId = 777;

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

    const InitializationSettings initializationSettings =
        InitializationSettings(
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

    if (Platform.isAndroid) {
      const AndroidNotificationChannel downloadChannel = AndroidNotificationChannel(
        channelIdDownload,
        '地图下载进度',
        description: '显示离线地图下载的进度',
        importance: Importance.low, // Low 避免每次更新进度都发出声音/震动
        playSound: false,
        enableVibration: false,
        showBadge: false,
      );
      
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(downloadChannel);
    }
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

  Future<void> showDownloadProgress({
    required int progress, // 当前下载数量
    required int total,    // 总数量
    required int activeTasks, // 正在进行的任务数
  }) async {
    // 计算百分比 (0-100)
    final int percentage = total > 0 ? ((progress / total) * 100).toInt() : 0;
    // 确保不越界
    final int safeProgress = progress > total ? total : progress;

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channelIdDownload,
      '地图下载进度',
      channelDescription: '显示离线地图下载的进度',
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true, // 仅首次提醒，后续静默更新
      showProgress: true,  // 显示进度条
      maxProgress: total,
      progress: safeProgress,
      ongoing: true,       // 常驻通知，用户无法划掉
      autoCancel: false,
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      _downloadNotificationId,
      '正在下载离线地图 ($activeTasks 个任务)',
      '$percentage% ($progress / $total)', // 内容文本
      platformChannelSpecifics,
    );
  }

  Future<void> cancelDownloadNotification() async {
    await _notificationsPlugin.cancel(_downloadNotificationId);
  }
}
