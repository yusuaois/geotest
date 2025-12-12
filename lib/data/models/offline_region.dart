import 'package:flutter_map/flutter_map.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';

part 'offline_region.g.dart';

@HiveType(typeId: 2)
class OfflineRegion extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
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
  final double sizeInMB;
  @HiveField(10)
  final DateTime downloadDate;

  OfflineRegion({
    required this.id,
    required this.name,
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
    required this.minZoom,
    required this.maxZoom,
    required this.tileCount,
    required this.sizeInMB,
    required this.downloadDate,
  });

  LatLngBounds get bounds =>
      LatLngBounds(LatLng(maxLat, minLon), LatLng(minLat, maxLon));
}
