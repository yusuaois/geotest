import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Channel ID
  static const String channelIdBackground = 'triggeo_background_service';
  static const String channelIdAlert = 'triggeo_arrival_alert';
  static const String channelIdDownload = 'triggeo_download_progress';
  static const int _downloadNotificationId = 777;

  Future<void> initialize() async {
    await _requestNotificationPermissions();

    // Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
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
      const AndroidNotificationChannel downloadChannel =
          AndroidNotificationChannel(
        channelIdDownload,
        '地图下载进度',
        description: '显示离线地图下载的进度',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(downloadChannel);
    }
  }

  Future<void> _requestNotificationPermissions() async {
    if (Platform.isIOS) {
      // iOS: 使用 FlutterLocalNotificationsPlugin 请求权限
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      // Android 13+ 需要请求通知权限
      if (await Permission.notification.isRestricted) {
        // 权限被限制（家长控制等）
        return;
      }
      
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }
  }

  Future<bool> hasNotificationPermission() async {
    if (Platform.isIOS) {
      // iOS: 检查通知权限状态
      final settings = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.getNotificationAppLaunchDetails();
      
      if (settings == null) return false;
      
      return settings.didNotificationLaunchApp;
    } else if (Platform.isAndroid) {
      // Android: 检查通知权限
      final status = await Permission.notification.status;
      return status.isGranted;
    }
    return false;
  }

  // 显示权限引导对话框
  Future<void> showPermissionGuide(BuildContext context) async {
    final hasPermission = await hasNotificationPermission();
    
    if (!hasPermission) {
      return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('通知权限'),
          content: const Text(
            'Triggeo需要通知权限来：\n\n'
            '• 在后台运行时显示位置提醒\n'
            '• 显示地图下载进度\n'
            '• 显示重要的应用通知\n\n'
            '请授予通知权限以获得完整功能体验。',
          ),
          actions: [
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
                await _requestNotificationPermissions();
              },
              child: const Text('授予权限'),
            ),
          ],
        ),
      );
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
    required int progress,
    required int total,
    required int activeTasks,
  }) async {
    final int percentage = total > 0 ? ((progress / total) * 100).toInt() : 0;
    final int safeProgress = progress > total ? total : progress;

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channelIdDownload,
      '地图下载进度',
      channelDescription: '显示离线地图下载的进度',
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: total,
      progress: safeProgress,
      ongoing: true,
      autoCancel: false,
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      _downloadNotificationId,
      '正在下载离线地图 ($activeTasks 个任务)',
      '$percentage% ($progress / $total)',
      platformChannelSpecifics,
    );
  }

  Future<void> cancelDownloadNotification() async {
    await _notificationsPlugin.cancel(_downloadNotificationId);
  }
}
