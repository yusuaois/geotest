import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:triggeo/core/services/service_locator.dart';
import 'package:triggeo/data/repositories/settings_repository.dart';
import 'package:triggeo/features/map/widgets/offline_tile_provider.dart';
import 'package:triggeo/features/map/widgets/reminder_edit_dialog.dart'; // 确保引用了这个
import 'map_controller.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  bool _hasAutoCentered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationServiceProvider).requestPermission();
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5&accept-language=zh-CN');
    try {
      final response =
          await http.get(url, headers: {'User-Agent': 'TriggeoApp/1.0'});
      if (response.statusCode == 200) {
        setState(() {
          _searchResults = json.decode(response.body);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('搜索失败: $e')));
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _moveToLocation(double lat, double lon) {
    _mapController.move(LatLng(lat, lon), 15.0);
    setState(() {
      _searchResults = [];
      _searchController.clear();
      FocusScope.of(context).unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(currentLocationProvider);
    ref.watch(mapControllerProvider);
    final tileUrl = ref.watch(tileUrlProvider);

    // 1. Extract LatLng directly. If loading or error, it remains null.
    LatLng? userLatLng;
    if (locationAsync.value != null) {
      userLatLng = LatLng(
        locationAsync.value!['lat'],
        locationAsync.value!['lng'],
      );
    }

    // 2. Handle Auto-Center Logic
    // Using addPostFrameCallback ensures we don't move the map during the build phase
    if (!_hasAutoCentered && userLatLng != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(userLatLng!, 15.0);
      });
      _hasAutoCentered = true;
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // --- 层级 1: 地图 (这是唯一的 FlutterMap) ---
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(39.9042, 116.4074),
              initialZoom: 15.0,
              // ✅ 修复点：将长按逻辑放在这里
              onLongPress: (_, latlng) {
                showDialog(
                  context: context,
                  builder: (context) => ReminderEditDialog(position: latlng),
                );
              },
              onTap: (_, __) {
                if (_searchResults.isNotEmpty) {
                  setState(() => _searchResults = []);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl, // 动态使用设置的镜像站
                userAgentPackageName: 'com.example.triggeo',
                tileProvider: OfflineTileProvider(), // 支持离线
              ),
              MarkerLayer(
                markers: [
                  // This block guarantees only ONE marker exists for the user location.
                  // It updates automatically whenever userLatLng changes (via ref.watch).
                  if (userLatLng != null)
                    Marker(
                      point: userLatLng,
                      width: 40,
                      height: 40,
                      key: const ValueKey('userLocationMarker'),
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
                Row(
                  children: [
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
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
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
            bottom: 100, // 固定位置，不再需要动态调整
            child: FloatingActionButton(
              heroTag: "my_location",
              mini: true,
              backgroundColor: Colors.white,
              child: Icon(Icons.my_location,
                  color: Theme.of(context).colorScheme.onPrimaryContainer),
              onPressed: () async {
                final position = await Geolocator.getCurrentPosition();
                userLatLng = LatLng(position.latitude, position.longitude);
                if (userLatLng != null) {
                  _mapController.move(userLatLng!, 15.0);
                  return;
                }

                // 2. 如果没有位置，可能是服务还没初始化或没信号，强制请求一次
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('正在定位...')));
                try {
                  final pos = await Geolocator.getCurrentPosition();
                  // 这里不需要手动创建 Marker，因为 Geolocator 的后台流应该也会更新
                  // 如果后台流没更新，我们可以手动强制刷新一下 Provider (如果不适用 StreamProvider的话)
                  // 但在使用 StreamProvider 的情况下，我们主要依赖流的推送
                  _mapController.move(
                      LatLng(pos.latitude, pos.longitude), 15.0);
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('定位失败: $e')));
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/list');
        },
        child: const Icon(Icons.list),
      ),
    );
  }
}
