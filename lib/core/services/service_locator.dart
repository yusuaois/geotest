import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triggeo/core/services/offline_map_service.dart';
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

// 4. Current Location Provider
final currentLocationProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.locationStream;
});

// 5. Offline Map Service Provider
final offlineMapServiceProvider = Provider((ref) => OfflineMapService());
