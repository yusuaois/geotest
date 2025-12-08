import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:triggeo/core/utils/tile_math.dart'; // 引用之前的 TileMath
import 'package:triggeo/data/models/offline_region.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http; // 用于 Nominatim API

class OfflineMapService {
  final Dio _dio = Dio();
  bool _isDownloading = false;
  static const String _boxName = 'offline_regions';

  // 搜索城市并获取边界
  Future<List<Map<String, dynamic>>> searchCity(String query) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?city=$query&format=json&limit=5');
    
    final response = await http.get(url, headers: {'User-Agent': 'TriggeoApp/1.0'});
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) {
        // Nominatim bbox 格式: [minLat, maxLat, minLon, maxLon] (字符串数组)
        final bbox = item['boundingbox'];
        return {
          'name': item['display_name'],
          'lat': double.parse(item['lat']),
          'lon': double.parse(item['lon']),
          'bounds': LatLngBounds(
            LatLng(double.parse(bbox[1]), double.parse(bbox[2])), // NorthWest (MaxLat, MinLon) - latlong2定义可能不同，需注意
            LatLng(double.parse(bbox[0]), double.parse(bbox[3])), // SouthEast (MinLat, MaxLon)
          )
        };
      }).toList();
    }
    return [];
  }

  // 估算瓦片数量
  int estimateTileCount(LatLngBounds bounds, int minZoom, int maxZoom) {
    int count = 0;
    for (int z = minZoom; z <= maxZoom; z++) {
      var topLeft = TileMath.project(bounds.northWest, z);
      var bottomRight = TileMath.project(bounds.southEast, z);
      count += ((bottomRight.x - topLeft.x).abs() + 1) * ((bottomRight.y - topLeft.y).abs() + 1);
    }
    return count;
  }

  // 下载核心逻辑 (支持镜像站模板)
  Stream<double> downloadCity({
    required String cityName,
    required LatLngBounds bounds,
    required int minZoom,
    required int maxZoom,
    required String urlTemplate, // 从 Settings 传入
  }) async* {
    if (_isDownloading) throw Exception("已有下载任务在进行");
    _isDownloading = true;

    final appDir = await getApplicationDocumentsDirectory();
    final regionId = const Uuid().v4();
    // 使用独立目录：offline_maps/regionId/z/x/y.png
    final regionDir = '${appDir.path}/offline_maps/$regionId'; 
    
    final totalTiles = estimateTileCount(bounds, minZoom, maxZoom);
    int downloadedCount = 0;
    int failedCount = 0;

    try {
      for (int z = minZoom; z <= maxZoom; z++) {
        var topLeft = TileMath.project(bounds.northWest, z);
        var bottomRight = TileMath.project(bounds.southEast, z);

        for (int x = topLeft.x; x <= bottomRight.x; x++) {
          for (int y = topLeft.y; y <= bottomRight.y; y++) {
            if (!_isDownloading) break;

            final url = urlTemplate
                .replaceAll('{z}', z.toString())
                .replaceAll('{x}', x.toString())
                .replaceAll('{y}', y.toString());
            
            final savePath = '$regionDir/$z/$x/$y.png';
            
            final file = File(savePath);
            if (!await file.exists()) {
              try {
                await file.parent.create(recursive: true);
                await _dio.download(
                  url, 
                  savePath,
                  options: Options(headers: {'User-Agent': 'TriggeoApp/1.0'}),
                );
              } catch (e) {
                failedCount++;
                debugPrint("Tile failed: $z/$x/$y");
              }
            }
            downloadedCount++;
            // 每下载 10 个汇报一次进度，减少 Stream 压力
            if (downloadedCount % 10 == 0) yield downloadedCount / totalTiles;
          }
        }
      }

      // 只有正常结束才保存元数据
      if (_isDownloading) {
        final box = await Hive.openBox<OfflineRegion>(_boxName);
        final region = OfflineRegion(
          id: regionId,
          name: cityName.split(',')[0], // 简化名称
          minLat: bounds.south,
          maxLat: bounds.north,
          minLon: bounds.west,
          maxLon: bounds.east,
          minZoom: minZoom,
          maxZoom: maxZoom,
          tileCount: downloadedCount,
          sizeInMB: (downloadedCount * 0.02), // 估算：每张图约 20KB
          downloadDate: DateTime.now(),
        );
        await box.add(region);
        yield 1.0;
      }

    } finally {
      _isDownloading = false;
    }
  }

  // 删除离线包
  Future<void> deleteRegion(OfflineRegion region) async {
    final appDir = await getApplicationDocumentsDirectory();
    final regionDir = Directory('${appDir.path}/offline_maps/${region.id}');
    
    if (await regionDir.exists()) {
      await regionDir.delete(recursive: true);
    }
    
    await region.delete(); // 从 Hive 中移除
  }

  // 获取所有离线包
  Future<List<OfflineRegion>> getDownloadedRegions() async {
    final box = await Hive.openBox<OfflineRegion>(_boxName);
    return box.values.toList();
  }
}