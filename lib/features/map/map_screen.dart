import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:triggeo/core/services/service_locator.dart'; // 位置服务
import 'package:triggeo/core/utils/geofence_calculator.dart'; // 距离计算
import 'map_controller.dart'; 
// import 'package:triggeo/features/settings/simple_settings_card.dart'; // 调试用

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听当前用户位置流 (来自 LocationService)
    final currentLocationAsync = ref.watch(currentLocationProvider);
    // 监听目标标记状态 (来自 MapController)
    final mapMarkerState = ref.watch(mapControllerProvider);
    final mapController = ref.read(mapControllerProvider.notifier);

    // 获取当前用户位置
    LatLng? userLatLng;
    if (currentLocationAsync.value != null) {
      userLatLng = LatLng(
        currentLocationAsync.value!['lat'] as double,
        currentLocationAsync.value!['lng'] as double,
      );
    }

    // 地图的初始中心点，优先使用用户当前位置，否则使用默认值
    final LatLng initialCenter = userLatLng ?? const LatLng(39.9042, 116.4074); // 默认北京

    // 计算距离
    String distanceText = '选择目标位置';
    if (userLatLng != null && mapMarkerState.targetPosition != null) {
      final distance = GeofenceCalculator.calculateDistance(
          userLatLng, mapMarkerState.targetPosition!);
      distanceText = GeofenceCalculator.formatDistance(distance);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Triggeo'),
        actions: [
          // TODO: 这里添加设置按钮
          IconButton(
            icon: const Icon(Icons.settings), 
            onPressed: () { 
              // TODO: 导航到 SettingsScreen (在 Step 6/7 实现)
              // 为了调试主题，你可以在这里暂时显示 SimpleSettingsCard
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('导航到设置页')),
              );
            },
          ),
        ],
      ),
      
      body: Column(
        children: [
          // 顶部信息栏 (当前位置/电量优化提示)
          _buildInfoBar(context, userLatLng, currentLocationAsync.isLoading),
          
          // 地图主体 (70% 屏幕高度)
          Expanded(
            flex: 7,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: 14.0,
                // 实现地图长按选择位置
                onLongPress: (tapPosition, latlng) {
                  mapController.setTargetLocation(latlng);
                },
              ),
              children: [
                // OpenStreetMap Tile Layer
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.yourcompany.triggeo', // 必须设置
                  maxZoom: 18,
                ),

                // Marker Layer (用户当前位置 + 目标位置)
                MarkerLayer(
                  markers: [
                    // 1. 用户当前位置标记 (蓝色圆点)
                    if (userLatLng != null)
                      Marker(
                        width: 30.0,
                        height: 30.0,
                        point: userLatLng,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                    
                    // 2. 目标位置标记 (红色大头针)
                    if (mapMarkerState.targetPosition != null)
                      Marker(
                        width: 50.0,
                        height: 50.0,
                        point: mapMarkerState.targetPosition!,
                        child: Icon(
                          Icons.location_on,
                          color: Theme.of(context).colorScheme.error,
                          size: 50,
                        ),
                      ),
                  ],
                ),
                
                // 目标位置的圆形提醒半径 (稍后在 Step 5 实现)
                // CircleLayer(circles: [...]), 
              ],
            ),
          ),
          
          // 底部目标信息卡片 (30% 屏幕高度)
          Expanded(
            flex: 3,
            child: _buildTargetInfoCard(context, mapMarkerState, distanceText),
          ),
        ],
      ),
      
      // 浮动操作按钮
      floatingActionButton: FloatingActionButton.extended(
        onPressed: mapMarkerState.targetPosition == null
            ? null // 未选择位置时禁用
            : () {
                // TODO: 导航到提醒详情设置页 (在 Step 6/7 实现)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('导航到提醒详情设置')),
                );
              },
        label: const Text('添加新提醒'),
        icon: const Icon(Icons.add_location_alt),
      ),
    );
  }
  
  // --- Widgets for UI Sections ---
  
  Widget _buildInfoBar(
      BuildContext context, LatLng? userLatLng, bool isLoading) {
    final theme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      color: theme.surfaceContainerLow,
      child: Row(
        children: [
          Icon(Icons.gps_fixed, color: theme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isLoading
                  ? '正在获取当前位置...'
                  : userLatLng == null
                      ? '等待 GPS 信号...'
                      : '当前位置: ${userLatLng.latitude.toStringAsFixed(5)}, ${userLatLng.longitude.toStringAsFixed(5)}',
              style: TextStyle(
                  fontSize: 12, color: theme.onSurface.withOpacity(0.8)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // TODO: 电池优化提示图标
          const Icon(Icons.battery_alert, color: Colors.orange, size: 20),
        ],
      ),
    );
  }

  Widget _buildTargetInfoCard(
      BuildContext context, MapMarkerState state, String distanceText) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.targetPosition == null ? '长按地图选择目标位置' : '目标位置详情',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Divider(),
          if (state.targetPosition != null) ...[
            Text('距离您: $distanceText',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 8),
            Text(
              '坐标/地址: ${state.address}',
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed: () => mapController.clearTargetLocation(),
                icon: const Icon(Icons.clear),
                label: const Text('清除标记'),
              ),
            ),
          ] else
            const Text('请长按地图任意一点来设置提醒目标。'),
        ],
      ),
    );
  }
}