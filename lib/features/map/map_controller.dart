import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:triggeo/data/models/reminder_location.dart'; // 稍后创建这个模型

// 临时的 Marker 状态，稍后会被真正的 ReminderLocation 模型取代
class MapMarkerState {
  final LatLng? targetPosition;
  final String? address; // 实际项目中可能需要逆地理编码获取

  MapMarkerState({this.targetPosition, this.address});

  MapMarkerState copyWith({
    LatLng? targetPosition,
    String? address,
  }) {
    return MapMarkerState(
      targetPosition: targetPosition ?? this.targetPosition,
      address: address ?? this.address,
    );
  }
}

class MapController extends Notifier<MapMarkerState> {
  @override
  MapMarkerState build() {
    // 默认不选择任何位置
    return MapMarkerState(targetPosition: null);
  }

  // 通过地图长按来设置目标位置
  void setTargetLocation(LatLng position) {
    // 实际项目中，这里会调用 Geocoding 服务获取地址
    final mockAddress = 
        "(${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})";
        
    state = state.copyWith(
      targetPosition: position,
      address: mockAddress,
    );
  }

  // 清除目标标记
  void clearTargetLocation() {
    state = MapMarkerState(targetPosition: null);
  }
}

final mapControllerProvider = NotifierProvider<MapController, MapMarkerState>(() {
  return MapController();
});