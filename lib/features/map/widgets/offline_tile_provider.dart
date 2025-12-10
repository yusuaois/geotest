import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hive/hive.dart';
import 'package:triggeo/data/models/offline_region.dart';

class OfflineTileProvider extends TileProvider {
  // 必须通过构造函数传入，确保同步可用
  final String offlineMapsDir; 
  List<OfflineRegion>? _regions;

  OfflineTileProvider({required this.offlineMapsDir}) {
    _loadRegions();
  }

  void _loadRegions() {
    // Hive 在 main.dart 已初始化，这里可以直接同步获取
    if (Hive.isBoxOpen('offline_regions')) {
      _regions = Hive.box<OfflineRegion>('offline_regions').values.toList();
    }
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    // 1. 离线优先：检查本地文件
    if (_regions != null) {
      for (var region in _regions!) {
        // 缩放级别检查
        if (coordinates.z >= region.minZoom && coordinates.z <= region.maxZoom) {
           // 检查文件是否存在: offline_maps/ID/z/x/y.png
           final path = '$offlineMapsDir/${region.id}/${coordinates.z}/${coordinates.x}/${coordinates.y}.png';
           final file = File(path);
           
           // sync check 是必要的，虽然可能阻塞 UI 线程微秒级，但为了正确返回 FileImage 必须这样做
           if (file.existsSync()) {
             return FileImage(file);
           }
        }
      }
    }

    // 2. 网络回退
    final url = options.urlTemplate!
        .replaceAll('{z}', coordinates.z.toString())
        .replaceAll('{x}', coordinates.x.toString())
        .replaceAll('{y}', coordinates.y.toString())
        .replaceAll('{s}', 'a');
        
    return NetworkImage(url, headers: {'User-Agent': 'TriggeoApp/1.0'});
  }
}