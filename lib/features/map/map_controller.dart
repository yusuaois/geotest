import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// 状态类：仅保存当前地图上选中的临时点
class MapSelectionState {
  final LatLng? selectedPosition;
  final String? addressPreview; // 预留给逆地理编码

  MapSelectionState({this.selectedPosition, this.addressPreview});
}

class MapSelectionController extends Notifier<MapSelectionState> {
  @override
  MapSelectionState build() {
    return MapSelectionState(selectedPosition: null);
  }

  // 用户长按地图时调用
  void selectLocation(LatLng position) {
    // 实际项目中这里可以插入 Geocoding API 调用获取地址
    state = MapSelectionState(
      selectedPosition: position,
      addressPreview: "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}",
    );
  }

  // 清除选中状态（例如保存后或取消时）
  void clearSelection() {
    state = MapSelectionState(selectedPosition: null);
  }
}

final mapControllerProvider = NotifierProvider<MapSelectionController, MapSelectionState>(() {
  return MapSelectionController();
});