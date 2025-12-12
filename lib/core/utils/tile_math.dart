import 'dart:math';
import 'package:latlong2/latlong.dart';

double sinh(double x) => (exp(x) - exp(-x)) / 2;

class TileMath {
  static const int tileSize = 256;

  static Point<int> project(LatLng latLng, int zoom) {
    var siny = sin(latLng.latitude * pi / 180);
    siny = min(max(siny, -0.9999), 0.9999);
    var n = pow(2, zoom);
    var x = tileSize * (0.5 + latLng.longitude / 360);
    var y = tileSize * (0.5 - log((1 + siny) / (1 - siny)) / (4 * pi));
    return Point<int>((x * n / tileSize).floor(), (y * n / tileSize).floor());
  }

  static LatLng unproject(int x, int y, int zoom) {
    var n = pow(2, zoom);
    var lonDeg = x / n * 360.0 - 180.0;
    var latRad = atan(sinh(pi * (1 - 2 * y / n)));
    var latDeg = latRad * 180.0 / pi;
    return LatLng(latDeg, lonDeg);
  }
}
