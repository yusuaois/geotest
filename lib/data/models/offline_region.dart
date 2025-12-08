import 'package:flutter_map/flutter_map.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';

part 'offline_region.g.dart';

@HiveType(typeId: 2) // 确保 typeId 不冲突
class OfflineRegion extends HiveObject {
  @HiveField(0)
  final String id; // 唯一ID (如 UUID)
  
  @HiveField(1)
  final String name; // 城市名 (如 "Beijing")
  
  @HiveField(2)
  final double minLat;
  @HiveField(3)
  final double maxLat;
  @HiveField(4)
  final double minLon;
  @HiveField(5)
  final double maxLon;
  
  @HiveField(6)
  final int minZoom;
  @HiveField(7)
  final int maxZoom;
  
  @HiveField(8)
  final int tileCount;
  
  @HiveField(9)
  final double sizeInMB; // 估算或实际大小
  
  @HiveField(10)
  final DateTime downloadDate;

  // 辅助方法：获取 LatLngBounds
  LatLngBounds get bounds => LatLngBounds(LatLng(maxLat, minLon), LatLng(minLat, maxLon));

  OfflineRegion({
    required this.id,
    required this.name,
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
    this.minZoom = 10,
    this.maxZoom = 14,
    required this.tileCount,
    this.sizeInMB = 0,
    required this.downloadDate,
  });
}