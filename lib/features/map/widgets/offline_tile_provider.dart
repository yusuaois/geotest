import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:path_provider/path_provider.dart';

class OfflineTileProvider extends TileProvider {
  String? _offlinePath;

  OfflineTileProvider() {
    _initPath();
  }

  Future<void> _initPath() async {
    final dir = await getApplicationDocumentsDirectory();
    _offlinePath = '${dir.path}/offline_maps';
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    // 1. 尝试从本地加载
    if (_offlinePath != null) {
      final path = '$_offlinePath/${coordinates.z}/${coordinates.x}/${coordinates.y}.png';
      final file = File(path);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }

    // 2. 本地没有，回退到网络 (OpenStreetMap)
    final url = options.urlTemplate!
        .replaceAll('{z}', coordinates.z.toString())
        .replaceAll('{x}', coordinates.x.toString())
        .replaceAll('{y}', coordinates.y.toString())
        .replaceAll('{s}', 'a'); // 简单处理子域
        
    return NetworkImage(url, headers: {'User-Agent': 'TriggeoApp/1.0'});
  }
}