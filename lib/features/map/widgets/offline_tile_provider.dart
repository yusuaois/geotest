import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hive/hive.dart';
import 'package:triggeo/data/models/offline_region.dart';

class OfflineTileProvider extends TileProvider {
  final String offlineMapsDir;
  List<OfflineRegion>? _regions;

  OfflineTileProvider({required this.offlineMapsDir}) {
    _loadRegions();
  }

  void _loadRegions() {
    if (Hive.isBoxOpen('offline_regions')) {
      _regions = Hive.box<OfflineRegion>('offline_regions').values.toList();
    }
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    if (_regions != null) {
      for (var region in _regions!) {
        if (coordinates.z >= region.minZoom &&
            coordinates.z <= region.maxZoom) {
          // offline_maps/ID/z/x/y.png
          final path =
              '$offlineMapsDir/${region.id}/${coordinates.z}/${coordinates.x}/${coordinates.y}.png';
          final file = File(path);

          // sync check
          if (file.existsSync()) {
            return FileImage(file);
          }
        }
      }
    }

    final url = options.urlTemplate!
        .replaceAll('{z}', coordinates.z.toString())
        .replaceAll('{x}', coordinates.x.toString())
        .replaceAll('{y}', coordinates.y.toString())
        .replaceAll('{s}', 'a');

    return NetworkImage(url, headers: {'User-Agent': 'TriggeoApp/1.0'});
  }
}
