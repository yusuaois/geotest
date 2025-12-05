import 'package:latlong2/latlong.dart';
import 'dart:math';

// Haversine 公式实现距离计算
const Distance distance = Distance();

class GeofenceCalculator {
  // 计算两个 LatLng 点之间的距离 (米)
  static double calculateDistance(
      LatLng point1, LatLng point2) {
    return distance(point1, point2);
  }

  // 格式化距离字符串
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} 米';
    } else {
      double km = meters / 1000;
      return '${km.toStringAsFixed(2)} 公里';
    }
  }

  // 检查点是否在目标半径内
  static bool isInRadius(
      LatLng userLocation, LatLng targetLocation, double radiusMeters) {
    final dist = calculateDistance(userLocation, targetLocation);
    // 增加一点容错，例如 5 米
    return dist <= radiusMeters + 5; 
  }
}