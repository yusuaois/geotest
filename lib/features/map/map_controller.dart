import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class MapSelectionState {
  final LatLng? selectedPosition;
  final String? addressPreview; 

  MapSelectionState({this.selectedPosition, this.addressPreview});
}

class MapSelectionController extends Notifier<MapSelectionState> {
  @override
  MapSelectionState build() {
    return MapSelectionState(selectedPosition: null);
  }

  void selectLocation(LatLng position) {
    state = MapSelectionState(
      selectedPosition: position,
      addressPreview: "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}",
    );
  }

  void clearSelection() {
    state = MapSelectionState(selectedPosition: null);
  }
}

final mapControllerProvider = NotifierProvider<MapSelectionController, MapSelectionState>(() {
  return MapSelectionController();
});