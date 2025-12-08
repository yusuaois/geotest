import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// 定义镜像源模型
class TileSource {
  final String name;
  final String urlTemplate;
  const TileSource(this.name, this.urlTemplate);
}

// 预设镜像源列表
const List<TileSource> kTileSources = [
  TileSource('OpenStreetMap (默认)', 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
  TileSource('CartoDB Voyager', 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png'),
  TileSource('CartoDB Dark', 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'),
  // 注意：某些源可能需要API Key，这里只列出免费源
];

class SettingsRepository {
  static const String _boxName = 'settings_box';
  Box get _box => Hive.box(_boxName);

  static const String _keyTileSourceIndex = 'tile_source_index';

  // 获取当前选中的镜像源 URL
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

// 提供实时的 URL 流
final tileUrlProvider = Provider<String>((ref) {
  // 这里简化处理，如果需要实时响应设置变化，可以使用 StreamProvider 监听 Hive
  return ref.read(settingsRepositoryProvider).getCurrentTileUrl();
});