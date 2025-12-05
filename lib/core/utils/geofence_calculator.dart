import 'package:latlong2/latlong.dart';

// 定义距离计算器实例
const Distance distance = Distance();

class GeofenceCalculator {
  /// 计算两点之间的距离（米）
  static double calculateDistance(LatLng point1, LatLng point2) {
    return distance(point1, point2);
  }

  /// 格式化距离显示
  /// 小于1公里显示米，大于1公里显示公里
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} 米';
    } else {
      double km = meters / 1000;
      return '${km.toStringAsFixed(2)} 公里';
    }
  }

  /// 核心判定：用户是否进入目标半径
  static bool isInRadius(LatLng userLocation, LatLng targetLocation, double radiusMeters) {
    final dist = calculateDistance(userLocation, targetLocation);
    // 增加 5 米的缓冲容错，避免边界抖动
    return dist <= (radiusMeters + 5); 
  }
}