import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:triggeo/core/services/offline_map_service.dart';

class OfflineMapScreen extends StatefulWidget {
  const OfflineMapScreen({super.key});

  @override
  State<OfflineMapScreen> createState() => _OfflineMapScreenState();
}

class _OfflineMapScreenState extends State<OfflineMapScreen> {
  final OfflineMapService _service = OfflineMapService();
  List<Map<String, dynamic>> _regions = [];
  double? _downloadProgress;
  
  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    final regions = await _service.getDownloadedRegions();
    setState(() => _regions = regions);
  }

  // 模拟：实际项目中应该让用户在搜索栏搜索地名，并输入距离范围，然后根据输入的参数下载区域地图
  void _downloadBeijingDemo() {
    final bounds = LatLngBounds(
      const LatLng(39.99, 116.30), // 西北
      const LatLng(39.85, 116.50), // 东南
    );
    
    _service.downloadRegion(
      regionName: "北京核心区 (示例)",
      bounds: bounds,
      minZoom: 10,
      maxZoom: 14,
    ).listen((progress) {
      setState(() => _downloadProgress = progress);
      if (progress >= 1.0) {
        setState(() => _downloadProgress = null);
        _loadRegions();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("下载完成")));
      }
    }, onError: (e) {
      setState(() => _downloadProgress = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("错误: $e")));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("离线地图管理")),
      body: Column(
        children: [
          if (_downloadProgress != null)
            LinearProgressIndicator(value: _downloadProgress),
            
          ListTile(
            title: const Text("下载当前视图区域 (模拟)"),
            subtitle: const Text("点击下载北京核心区示例 (Zoom 10-14)"),
            leading: const Icon(Icons.download),
            onTap: _downloadProgress == null ? _downloadBeijingDemo : null,
          ),
          
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(alignment: Alignment.centerLeft, child: Text("已下载区域")),
          ),
          
          Expanded(
            child: ListView.builder(
              itemCount: _regions.length,
              itemBuilder: (context, index) {
                final region = _regions[index];
                return ListTile(
                  title: Text(region['name']),
                  subtitle: Text("瓦片数: ${region['count']} | 时间: ${region['date'].toString().substring(0, 10)}"),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                );
              },
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.delete_forever),
              label: const Text("清空所有离线缓存"),
              onPressed: () async {
                await _service.clearAllCache();
                _loadRegions();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("缓存已清空")));
              },
            ),
          )
        ],
      ),
    );
  }
}