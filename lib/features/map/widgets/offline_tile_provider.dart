import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:triggeo/data/models/offline_region.dart';

class OfflineTileProvider extends TileProvider {
  String? _rootDir;
  List<OfflineRegion>? _regions;

  OfflineTileProvider() {
    _init();
  }

  Future<void> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    _rootDir = '${dir.path}/offline_maps';
    
    // 加载所有下载的区域信息
    // 注意：这里需要确保 Hive 已初始化且 box 已打开。通常在 main.dart 已完成。
    if (Hive.isBoxOpen('offline_regions')) {
      _regions = Hive.box<OfflineRegion>('offline_regions').values.toList();
    }
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    // 1. 离线优先：遍历所有已下载区域，检查该瓦片是否在区域内
    if (_rootDir != null && _regions != null) {
      for (var region in _regions!) {
        // 简单的缩放级别检查
        if (coordinates.z >= region.minZoom && coordinates.z <= region.maxZoom) {
           // 检查文件是否存在: offline_maps/ID/z/x/y.png
           final path = '$_rootDir/${region.id}/${coordinates.z}/${coordinates.x}/${coordinates.y}.png';
           final file = File(path);
           if (file.existsSync()) {
             return FileImage(file);
           }
        }
      }
    }

    // 2. 网络回退 (使用 options 传入的 urlTemplate，即我们在 Settings 设定的镜像站)
    final url = options.urlTemplate!
        .replaceAll('{z}', coordinates.z.toString())
        .replaceAll('{x}', coordinates.x.toString())
        .replaceAll('{y}', coordinates.y.toString())
        .replaceAll('{s}', 'a');
        
    return NetworkImage(url, headers: {'User-Agent': 'TriggeoApp/1.0'});
  }
}