import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // 核心地图库
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:triggeo/core/services/service_locator.dart'; // 引入位置服务 Provider
import 'package:triggeo/core/utils/geofence_calculator.dart';
import 'map_controller.dart'; 

// 暂时占位，稍后会在 Step 5 实现后取消注释
// import 'package:triggeo/data/repositories/reminder_repository.dart'; 

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 获取实时数据
    final locationAsync = ref.watch(currentLocationProvider); // 用户位置
    final selectionState = ref.watch(mapControllerProvider);  // 临时选点
    final mapNotifier = ref.read(mapControllerProvider.notifier);
    
    // 2. 解析用户位置 (如果正在加载或无信号，则为 null)
    LatLng? userLatLng;
    if (locationAsync.value != null) {
      userLatLng = LatLng(
        locationAsync.value!['lat'],
        locationAsync.value!['lng'],
      );
    }
    
    // 3. 计算临时选点与用户的距离
    String distanceInfo = "长按地图选择目标";
    if (userLatLng != null && selectionState.selectedPosition != null) {
      final dist = GeofenceCalculator.calculateDistance(userLatLng, selectionState.selectedPosition!);
      distanceInfo = "距离: ${GeofenceCalculator.formatDistance(dist)}";
    }

    // 4. 默认中心点 (如果没有定位，默认为北京)
    final initialCenter = userLatLng ?? const LatLng(39.9042, 116.4074);

    return Scaffold(
      body: Stack(
        children: [
          // --- 层级 1: 地图 ---
          FlutterMap(
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 15.0,
              // 长按交互：设置临时目标
              onLongPress: (_, latlng) => mapNotifier.selectLocation(latlng),
            ),
            children: [
              // 底图图层 (OpenStreetMap)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.triggeo', // 替换为你的包名
              ),
              
              // 标记图层
              MarkerLayer(
                markers: [
                  // A. 用户当前位置 (蓝色导航箭头)
                  if (userLatLng != null)
                    Marker(
                      point: userLatLng,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.navigation, color: Colors.blue, size: 30),
                    ),
                  
                  // B. 临时选中的目标 (红色大头针)
                  if (selectionState.selectedPosition != null)
                    Marker(
                      point: selectionState.selectedPosition!,
                      width: 50,
                      height: 50,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 50),
                    ),
                ],
              ),
              
              // C. 稍后这里会添加 CircleLayer 显示已有的地理围栏
            ],
          ),

          // --- 层级 2: 顶部状态栏 ---
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(userLatLng == null ? Icons.gps_not_fixed : Icons.gps_fixed, 
                         color: userLatLng == null ? Colors.grey : Colors.green),
                    const SizedBox(width: 10),
                    Text(userLatLng == null ? "正在获取定位..." : "定位正常 | 后台服务运行中"),
                  ],
                ),
              ),
            ),
          ),

          // --- 层级 3: 底部操作卡片 ---
          if (selectionState.selectedPosition != null)
            Positioned(
              bottom: 30,
              left: 16,
              right: 16,
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("目标位置", style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(selectionState.addressPreview ?? ""),
                      Text(distanceInfo, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () => mapNotifier.clearSelection(),
                            child: const Text("取消"),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add_alarm),
                            label: const Text("添加提醒"),
                            onPressed: () {
                              context.push('/add', extra: selectionState.selectedPosition!);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("即将跳转到设置页..."))
                              );
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      // 这里的 FAB 以后用于打开列表页
      floatingActionButton: selectionState.selectedPosition == null 
          ? FloatingActionButton(
              onPressed: () {
                context.push('/list');
              },
              child: const Icon(Icons.list),
            ) 
          : null,
    );
  }
}