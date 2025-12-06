import 'dart:convert';
import 'dart:async'; // 引入 Timer
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http; // 用于搜索 API
import 'package:triggeo/core/services/service_locator.dart';
import 'package:triggeo/core/utils/geofence_calculator.dart';
import 'map_controller.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  // 1. 地图控制器：用于代码控制地图移动
  final MapController _mapController = MapController();

  // 2. 搜索相关状态
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  bool _hasAutoCentered = false; // 防止每次位置更新都强制拉回用户位置

  @override
  void initState() {
    super.initState();
    // 页面加载后检查权限并请求定位
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationServiceProvider).requestPermission();
    });
  }

  // --- 搜索功能实现 (使用 OSM Nominatim API) ---
  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) return;
    setState(() => _isSearching = true);

    // 为了避免频繁请求，实际项目中建议加防抖 (Debounce)
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5&accept-language=zh-CN');

    try {
      final response = await http.get(url, headers: {
        // OSM 要求必须带 User-Agent
        'User-Agent': 'TriggeoApp/1.0',
      });

      if (response.statusCode == 200) {
        setState(() {
          _searchResults = json.decode(response.body);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('搜索失败: $e')),
      );
    } finally {
      setState(() => _isSearching = false);
    }
  }

  // 移动地图到搜索结果
  void _moveToLocation(double lat, double lon) {
    _mapController.move(LatLng(lat, lon), 15.0);
    setState(() {
      _searchResults = []; // 清空搜索结果
      _searchController.clear();
      FocusScope.of(context).unfocus(); // 收起键盘
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(currentLocationProvider);
    final selectionState = ref.watch(mapControllerProvider);
    final mapNotifier = ref.read(mapControllerProvider.notifier);

    LatLng? userLatLng;
    if (locationAsync.value != null) {
      userLatLng = LatLng(
        locationAsync.value!['lat'],
        locationAsync.value!['lng'],
      );

      // ✅ 自动定位逻辑：
      // 只有在第一次获取到位置，且尚未自动定位过时，才移动地图
      if (!_hasAutoCentered && userLatLng != null) {
        // 使用微小的延迟确保 MapController 已绑定
        Future.delayed(const Duration(milliseconds: 500), () {
          _mapController.move(userLatLng!, 15.0);
        });
        _hasAutoCentered = true; // 标记已定位
      }
    }

    // 计算距离信息
    String distanceInfo = "长按地图选择目标";
    if (userLatLng != null && selectionState.selectedPosition != null) {
      final dist = GeofenceCalculator.calculateDistance(
          userLatLng, selectionState.selectedPosition!);
      distanceInfo = "距离: ${GeofenceCalculator.formatDistance(dist)}";
    }
    return Scaffold(
      // 使用 resizeToAvoidBottomInset 防止键盘顶起地图
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // --- 层级 1: 地图 ---
          FlutterMap(
            mapController: _mapController, // ✅ 绑定控制器
            options: MapOptions(
              // 初始中心点 (如果还未获取到定位，先显示北京)
              initialCenter: const LatLng(39.9042, 116.4074),
              initialZoom: 15.0,
              onLongPress: (_, latlng) => mapNotifier.selectLocation(latlng),
              onTap: (_, __) {
                // 点击地图空白处，收起搜索结果
                if (_searchResults.isNotEmpty) {
                  setState(() => _searchResults = []);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.triggeo',
              ),
              MarkerLayer(
                markers: [
                  // 用户位置：蓝色圆点 + 白色箭头
                  if (userLatLng != null)
                    Marker(
                      point: userLatLng!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(blurRadius: 5, color: Colors.black26)
                          ],
                        ),
                        child: const Icon(Icons.navigation,
                            color: Colors.blue, size: 25),
                      ),
                    ),
                  // 选中位置：红色大头针
                  if (selectionState.selectedPosition != null)
                    Marker(
                      point: selectionState.selectedPosition!,
                      width: 50,
                      height: 50,
                      // 添加 alignment 确保针尖对准坐标
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.location_on,
                          color: Colors.red, size: 50),
                    ),
                ],
              ),
            ],
          ),

          // --- 层级 2: 顶部搜索栏 ---
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // 搜索框和设置按钮在同一行
                Row(
                  children: [
                    // 搜索框（使用 Expanded 占据剩余空间）
                    Expanded(
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: "搜索地点...",
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _isSearching
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Padding(
                                        padding: EdgeInsets.all(10),
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2)))
                                : IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchResults = []);
                                    },
                                  ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                          ),
                          onSubmitted: _searchPlaces,
                        ),
                      ),
                    ),
                    // 设置按钮
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () => context.push('/settings'),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),

                // 搜索结果列表 (悬浮在地图上)
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4)
                      ],
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final place = _searchResults[index];
                        return ListTile(
                          title: Text(place['display_name'].split(',')[0],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(place['display_name'],
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          leading: const Icon(Icons.location_city, size: 20),
                          onTap: () {
                            final lat = double.parse(place['lat']);
                            final lon = double.parse(place['lon']);
                            _moveToLocation(lat, lon);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // --- 层级 3: 回到当前位置按钮 ---
          Positioned(
            right: 16,
            bottom: selectionState.selectedPosition != null
                ? 220
                : 100, // 根据底部卡片调整位置
            child: FloatingActionButton(
              heroTag: "my_location",
              mini: true,
              backgroundColor: Colors.white,
              child: Icon(Icons.my_location,
                  color: Theme.of(context).colorScheme.onPrimaryContainer),
              onPressed: () async {
                // 1. 尝试使用当前缓存的位置
                if (userLatLng != null) {
                  _mapController.move(userLatLng!, 15.0);
                  return;
                }

                // 2. 如果没有缓存，显示加载并强制获取
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('正在定位中...')));
                try {
                  // 强制获取一次当前位置 (需引入 geolocator)
                  final pos = await Geolocator.getCurrentPosition();
                  _mapController.move(
                      LatLng(pos.latitude, pos.longitude), 15.0);
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('定位失败: $e')));
                }
              },
            ),
          ),

          // --- 层级 4: 底部操作卡片 (保持原有逻辑) ---
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
                      Text("目标位置",
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      // 显示距离
                      Text(distanceInfo,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.blue)),
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
                              context.push('/add',
                                  extra: selectionState.selectedPosition!);
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
      // 这里的 FAB 用于打开列表页
      //
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
