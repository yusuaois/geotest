import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Modle of tile source
class TileSource {
  final String name;
  final String urlTemplate;
  const TileSource(this.name, this.urlTemplate);
}

const List<TileSource> kTileSources = [
  TileSource('OpenStreetMap (Default)', 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
  TileSource('CartoDB Voyager', 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png'),
  TileSource('CartoDB Dark', 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'),
];

class SettingsRepository {
  static const String _boxName = 'settings_box';
  Box get _box => Hive.box(_boxName);

  static const String _keyTileSourceIndex = 'tile_source_index';

  String getCurrentTileUrl() {
    int index = _box.get(_keyTileSourceIndex, defaultValue: 0);
    if (index >= kTileSources.length) index = 0;
    return kTileSources[index].urlTemplate;
  }

  Future<void> setTileSource(int index) async {
    await _box.put(_keyTileSourceIndex, index);
  }
  
  int getCurrentTileSourceIndex() {
    return _box.get(_keyTileSourceIndex, defaultValue: 0);
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) => SettingsRepository());

final tileUrlProvider = Provider<String>((ref) {
  return ref.read(settingsRepositoryProvider).getCurrentTileUrl();
});