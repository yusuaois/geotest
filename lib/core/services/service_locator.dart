import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audio_service.dart';
import 'location_service.dart';
import 'notification_service.dart';

// 1. Notification Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// 2. Audio Provider
final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});

// 3. Location Service Provider
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

// 4. 当前位置流 Provider (供地图 UI 使用)
// 这是一个 StreamProvider，UI 可以直接 watch 它来获取实时坐标
final currentLocationProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.locationStream;
});