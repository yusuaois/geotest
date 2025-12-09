import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triggeo/core/services/offline_map_service.dart';
import 'package:triggeo/data/models/offline_region.dart';
import 'package:triggeo/data/repositories/settings_repository.dart';

class OfflineMapScreen extends ConsumerStatefulWidget {
  const OfflineMapScreen({super.key});

  @override
  ConsumerState<OfflineMapScreen> createState() => _OfflineMapScreenState();
}

class _OfflineMapScreenState extends ConsumerState<OfflineMapScreen> with SingleTickerProviderStateMixin {
  final OfflineMapService _service = OfflineMapService();
  late TabController _tabController;
  
  // 搜索相关
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  
  // 下载相关
  double? _progress;
  String _statusText = "";
  
  // 列表相关
  List<OfflineRegion> _downloadedRegions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshList();
  }

  Future<void> _refreshList() async {
    final list = await _service.getDownloadedRegions();
    setState(() => _downloadedRegions = list);
  }

  Future<void> _doSearch() async {
    if (_searchCtrl.text.isEmpty) return;
    setState(() => _isSearching = true);
    // 这里如果做国际化，可以尝试拼写 'China' 等
    final results = await _service.searchCity(_searchCtrl.text);
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  void _startDownload(Map<String, dynamic> cityData) {
    // 获取当前的镜像源
    final urlTemplate = ref.read(settingsRepositoryProvider).getCurrentTileUrl();
    
    final bounds = cityData['bounds'] as LatLngBounds;
    // 限制缩放级别以控制大小，城市级别通常 10-14 足够离线查看，15-18 极大
    const int minZ = 10;
    const int maxZ = 15; 
    
    final count = _service.estimateTileCount(bounds, minZ, maxZ);
    final estSize = (count * 0.02).toStringAsFixed(1); // MB

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("确认下载"),
        content: Text("即将下载: ${cityData['name']}\n"
            "缩放级别: $minZ - $maxZ\n"
            "预计瓦片: $count 张\n"
            "预计大小: ~$estSize MB"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _executeDownload(cityData['name'], bounds, minZ, maxZ, urlTemplate);
            }, 
            child: const Text("下载")
          ),
        ],
      ),
    );
  }

  void _executeDownload(String name, LatLngBounds bounds, int minZ, int maxZ, String urlTpl) {
    setState(() {
      _statusText = "正在下载 $name...";
      _progress = 0;
    });

    _service.downloadCity(
      cityName: name,
      bounds: bounds,
      minZoom: minZ,
      maxZoom: maxZ,
      urlTemplate: urlTpl,
    ).listen((prog) {
      setState(() => _progress = prog);
    }, onDone: () {
      setState(() {
        _progress = null;
        _statusText = "";
      });
      _refreshList();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("下载完成")));
      _tabController.animateTo(1); // 跳转到管理页
    }, onError: (e) {
      setState(() {
        _progress = null;
        _statusText = "";
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("下载失败: $e")));
    });
  }

  void _deleteRegion(OfflineRegion region) async {
    await _service.deleteRegion(region);
    _refreshList();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${region.name} 已删除")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("离线地图"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: "下载新地图"), Tab(text: "已下载管理")],
        ),
      ),
      body: Column(
        children: [
          if (_progress != null) ...[
            LinearProgressIndicator(value: _progress),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("$_statusText ${(_progress! * 100).toStringAsFixed(0)}%"),
            ),
          ],
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: 搜索与下载
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              decoration: const InputDecoration(
                                hintText: "输入城市名称 (如: Beijing, Shanghai)",
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.search),
                              ),
                              onSubmitted: (_) => _doSearch(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(onPressed: _doSearch, child: const Text("搜索")),
                        ],
                      ),
                    ),
                    if (_isSearching) const LinearProgressIndicator(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final item = _searchResults[index];
                          return ListTile(
                            title: Text(item['name'].split(',')[0], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(item['name'], maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: const Icon(Icons.download),
                            onTap: _progress == null ? () => _startDownload(item) : null,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                
                // Tab 2: 管理与删除
                _downloadedRegions.isEmpty 
                    ? const Center(child: Text("暂无离线地图"))
                    : ListView.builder(
                        itemCount: _downloadedRegions.length,
                        itemBuilder: (context, index) {
                          final region = _downloadedRegions[index];
                          return ListTile(
                            title: Text(region.name),
                            subtitle: Text("大小: ${region.sizeInMB.toStringAsFixed(1)} MB | 瓦片: ${region.tileCount}"),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteRegion(region),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}