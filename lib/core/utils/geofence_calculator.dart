import 'package:latlong2/latlong.dart';

// Calculate distance between two points
const Distance distance = Distance();

class GeofenceCalculator {
  /// Calculate distance in meters between two LatLng points
  static double calculateDistance(LatLng point1, LatLng point2) {
    return distance(point1, point2);
  }

  static bool isInRadius(
      LatLng userLocation, LatLng targetLocation, double radiusMeters) {
    final dist = calculateDistance(userLocation, targetLocation);
    return dist <= (radiusMeters + 5);
  }
}
