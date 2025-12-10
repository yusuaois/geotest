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
    
    if (Hive.isBoxOpen('offline_regions')) {
      _regions = Hive.box<OfflineRegion>('offline_regions').values.toList();
    }
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    // 1. Offline first
    if (_rootDir != null && _regions != null) {
      for (var region in _regions!) {
        if (coordinates.z >= region.minZoom && coordinates.z <= region.maxZoom) {
           // Check if tile exists in offline storage: offline_maps/ID/z/x/y.png
           final path = '$_rootDir/${region.id}/${coordinates.z}/${coordinates.x}/${coordinates.y}.png';
           final file = File(path);
           if (file.existsSync()) {
             return FileImage(file);
           }
        }
      }
    }

    // 2. Fallback to online tiles
    final url = options.urlTemplate!
        .replaceAll('{z}', coordinates.z.toString())
        .replaceAll('{x}', coordinates.x.toString())
        .replaceAll('{y}', coordinates.y.toString())
        .replaceAll('{s}', 'a');
        
    return NetworkImage(url, headers: {'User-Agent': 'TriggeoApp/1.0'});
  }
}