import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:path_provider/path_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:triggeo/core/utils/tile_math.dart';

class OfflineMapService {
  final Dio _dio = Dio();
  bool _isDownloading = false;
  
  // 获取离线地图根目录
  Future<String> get _offlineMapDir async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/offline_maps';
    if (!await Directory(path).exists()) {
      await Directory(path).create(recursive: true);
    }
    return path;
  }

  // 计算区域内的瓦片数量
  int estimateTileCount(LatLngBounds bounds, int minZoom, int maxZoom) {
    int count = 0;
    for (int z = minZoom; z <= maxZoom; z++) {
      var topLeft = TileMath.project(bounds.northWest, z);
      var bottomRight = TileMath.project(bounds.southEast, z);
      count += ((bottomRight.x - topLeft.x).abs() + 1) * ((bottomRight.y - topLeft.y).abs() + 1);
    }
    return count;
  }

  // 下载地图区域
  Stream<double> downloadRegion({
    required String regionName,
    required LatLngBounds bounds,
    required int minZoom,
    required int maxZoom,
  }) async* {
    if (_isDownloading) throw Exception("已有下载任务在进行");
    _isDownloading = true;

    final rootPath = await _offlineMapDir;
    final totalTiles = estimateTileCount(bounds, minZoom, maxZoom);
    int downloadedCount = 0;

    try {
      for (int z = minZoom; z <= maxZoom; z++) {
        var topLeft = TileMath.project(bounds.northWest, z);
        var bottomRight = TileMath.project(bounds.southEast, z);

        for (int x = topLeft.x; x <= bottomRight.x; x++) {
          for (int y = topLeft.y; y <= bottomRight.y; y++) {
            if (!_isDownloading) break; // 支持取消

            final url = 'https://tile.openstreetmap.org/$z/$x/$y.png';
            final savePath = '$rootPath/$z/$x/$y.png'; // 统一结构，不按区域分文件夹，方便复用
            
            final file = File(savePath);
            if (!await file.exists()) {
              try {
                // 确保目录存在
                await file.parent.create(recursive: true);
                // 下载必须带 User-Agent
                await _dio.download(
                  url, 
                  savePath,
                  options: Options(headers: {'User-Agent': 'TriggeoApp/1.0'}),
                );
              } catch (e) {
                debugPrint("下载瓦片失败 $z/$x/$y: $e");
              }
            }
            
            downloadedCount++;
            yield downloadedCount / totalTiles;
          }
        }
      }
      
      // 保存区域元数据（用于管理列表）
      await _saveRegionMetadata(regionName, bounds, totalTiles);

    } finally {
      _isDownloading = false;
    }
  }

  void cancelDownload() {
    _isDownloading = false;
  }

  Future<void> _saveRegionMetadata(String name, LatLngBounds bounds, int count) async {
    final root = await _offlineMapDir;
    final file = File('$root/regions.csv');
    // 简单格式: Name,MinLat,MinLon,MaxLat,MaxLon,Count,Size(est)
    String line = '$name,${bounds.south},${bounds.west},${bounds.north},${bounds.east},$count,${DateTime.now().toIso8601String()}\n';
    await file.writeAsString(line, mode: FileMode.append);
  }

  Future<List<Map<String, dynamic>>> getDownloadedRegions() async {
    final root = await _offlineMapDir;
    final file = File('$root/regions.csv');
    if (!await file.exists()) return [];

    final lines = await file.readAsLines();
    return lines.map((line) {
      final parts = line.split(',');
      return {
        'name': parts[0],
        'bounds': LatLngBounds(LatLng(double.parse(parts[3]), double.parse(parts[4])), LatLng(double.parse(parts[1]), double.parse(parts[2]))),
        'count': parts[5],
        'date': parts[6],
      };
    }).toList();
  }

  // 清理逻辑：为了简化，这里只删除记录，实际物理文件删除很复杂因为多个区域可能共用瓦片
  // 真正的清理需要遍历所有瓦片看是否属于剩余区域，或者直接提供“清空所有缓存”的功能
  Future<void> clearAllCache() async {
    final root = await _offlineMapDir;
    final dir = Directory(root);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}