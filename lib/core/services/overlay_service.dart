import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:triggeo/features/map/widgets/arrival_overlay.dart';

class OverlayService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static OverlayEntry? _overlayEntry;

  static void showArrivalFloat(String name, LatLng location) {
    // 如果已有浮窗，先移除
    removeFloat();

    final context = navigatorKey.currentContext;
    if (context == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => ArrivalOverlay(
        title: name,
        location: location,
        time: DateTime.now(),
        onClose: removeFloat,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void removeFloat() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}