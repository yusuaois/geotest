import 'package:flutter_map/flutter_map.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';

part 'download_task.g.dart';

@HiveType(typeId: 3)
enum TaskStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  downloading,
  @HiveField(2)
  paused,
  @HiveField(3)
  completed,
  @HiveField(4)
  failed,
  @HiveField(5)
  canceled
}

@HiveType(typeId: 4)
class DownloadTask extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String regionName;

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
  int totalTiles;

  @HiveField(9)
  int downloadedTiles;

  @HiveField(10)
  TaskStatus status;

  @HiveField(11)
  String? errorMessage;

  DownloadTask({
    required this.id,
    required this.regionName,
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
    required this.minZoom,
    required this.maxZoom,
    this.totalTiles = 0,
    this.downloadedTiles = 0,
    this.status = TaskStatus.pending,
    this.errorMessage,
  });

  LatLngBounds get bounds =>
      LatLngBounds(LatLng(maxLat, minLon), LatLng(minLat, maxLon));

  double get progress => totalTiles == 0 ? 0 : downloadedTiles / totalTiles;
}
