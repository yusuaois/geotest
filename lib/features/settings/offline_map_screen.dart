import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:triggeo/core/services/offline_map_service.dart';
import 'package:triggeo/core/services/service_locator.dart';
import 'package:triggeo/data/models/download_task.dart';
import 'package:triggeo/data/repositories/settings_repository.dart';
import 'package:triggeo/core/services/notification_service.dart';

class OfflineMapScreen extends ConsumerStatefulWidget {
  const OfflineMapScreen({super.key});

  @override
  ConsumerState<OfflineMapScreen> createState() => _OfflineMapScreenState();
}

class _OfflineMapScreenState extends ConsumerState<OfflineMapScreen>
    with SingleTickerProviderStateMixin {
  late OfflineMapService _service;
  late TabController _tabController;

  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _service = ref.read(offlineMapServiceProvider);
    _service.init(); // 确保 Box 打开
    _tabController = TabController(length: 2, vsync: this);
  }

  // ... 搜索逻辑与之前类似，略微调整 _startDownload ...

  void _startDownload(Map<String, dynamic> cityData) {
    final urlTemplate =
        ref.read(settingsRepositoryProvider).getCurrentTileUrl();
    final bounds = cityData['bounds'] as LatLngBounds;
    const int minZ = 10;
    const int maxZ = 14;

    // 调用新的 createTask
    _service.createTask(
      cityName: cityData['name'],
      bounds: bounds,
      minZoom: minZ,
      maxZoom: maxZ,
      urlTemplate: urlTemplate,
    );

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("已加入下载队列")));
    _tabController.animateTo(1); // 跳到任务列表
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("离线地图管理"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: "下载新地图"), Tab(text: "任务与已下载")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: 搜索 (UI代码保持之前逻辑，不再赘述)
          _buildSearchTab(),

          // Tab 2: 任务列表 (使用 StreamBuilder 监听进度)
          _buildTaskList(),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
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
                title: Text(item['name'].split(',')[0],
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(item['name'],
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.download),
                onTap: () => _startDownload(item),
              );
            },
          ),
        ),
      ],
    );
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

  Widget _buildTaskList() {
    return StreamBuilder<List<DownloadTask>>(
      stream: _service.tasksStream,
      initialData: _service.getAllTasks(),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];
        if (tasks.isEmpty) return const Center(child: Text("暂无下载任务"));
        
        // 倒序排列，新的在上面
        final reversedTasks = tasks.reversed.toList();

        return ListView.builder(
          itemCount: reversedTasks.length,
          itemBuilder: (context, index) {
            final task = reversedTasks[index];
            return _buildTaskItem(task);
          },
        );
      },
    );
  }

  Widget _buildTaskItem(DownloadTask task) {
    final progress = task.progress;
    final percent = (progress * 100).toStringAsFixed(1);

    IconData icon;
    Color color;
    String statusText;

    switch (task.status) {
      case TaskStatus.downloading:
        icon = Icons.downloading;
        color = Colors.blue;
        statusText = "下载中 $percent%";
        break;
      case TaskStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        statusText = "已完成";
        break;
      case TaskStatus.failed:
        icon = Icons.error;
        color = Colors.red;
        statusText = "失败";
        break;
      case TaskStatus.pending:
        icon = Icons.schedule;
        color = Colors.orange;
        statusText = "等待中";
        break;
      default:
        icon = Icons.pause;
        color = Colors.grey;
        statusText = "已停止";
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Column(
        children: [
          ListTile(
            title: Text(task.regionName),
            subtitle: Text(statusText),
            leading: Icon(icon, color: color),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (task.status == TaskStatus.downloading)
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined),
                    onPressed: () => _service.cancelTask(task),
                  ),
                if (task.status == TaskStatus.failed ||
                    task.status == TaskStatus.canceled)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      final url = ref
                          .read(settingsRepositoryProvider)
                          .getCurrentTileUrl();
                      _service.resumeTask(task, url);
                    },
                  ),
                if (task.status == TaskStatus.completed)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _service.deleteRegion(task.id),
                  ),
              ],
            ),
          ),
          if (task.status == TaskStatus.downloading ||
              task.status == TaskStatus.pending)
            LinearProgressIndicator(value: progress),
        ],
      ),
    );
  }
}
