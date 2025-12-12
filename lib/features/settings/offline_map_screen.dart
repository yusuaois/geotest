import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triggeo/core/services/offline_map_service.dart';
import 'package:triggeo/core/services/service_locator.dart';
import 'package:triggeo/data/models/download_task.dart';
import 'package:triggeo/data/repositories/settings_repository.dart';
import 'package:triggeo/l10n/app_localizations.dart';

class OfflineMapScreen extends ConsumerStatefulWidget {
  const OfflineMapScreen({super.key});

  @override
  ConsumerState<OfflineMapScreen> createState() => _OfflineMapScreenState();
}

class _OfflineMapScreenState extends ConsumerState<OfflineMapScreen>
    with SingleTickerProviderStateMixin {
  late OfflineMapService _service;
  late TabController _tabController;
  late Future<void> _initFuture;

  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _service = ref.read(offlineMapServiceProvider);
    _initFuture = _service.init();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _startDownload(Map<String, dynamic> cityData) {
    final urlTemplate =
        ref.read(settingsRepositoryProvider).getCurrentTileUrl();
    final bounds = cityData['bounds'] as LatLngBounds;
    const int minZ = 10;
    const int maxZ = 14;

    _service.createTask(
      cityName: cityData['name'],
      bounds: bounds,
      minZoom: minZ,
      maxZoom: maxZ,
      urlTemplate: urlTemplate,
      l10n: AppLocalizations.of(context)!,
    );

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.offlineMapAddedToQueue)));
    _tabController.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.offlineMapTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.offlineMapTabNew),
            Tab(text: AppLocalizations.of(context)!.offlineMapTabTasks)
          ],
        ),
      ),
      body: FutureBuilder(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.offlineMapLoadingData),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
                child: Text(AppLocalizations.of(context)!
                    .offlineMapLoadFailed(snapshot.error!)));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // SearchBar
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)!
                                  .offlineMapSearchHint,
                              border: const OutlineInputBorder(),
                              suffixIcon: const Icon(Icons.search),
                            ),
                            onSubmitted: (_) => _doSearch(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                            onPressed: _doSearch,
                            child: Text(AppLocalizations.of(context)!
                                .offlineMapSearchButton)),
                      ],
                    ),
                  ),
                  if (_isSearching) const LinearProgressIndicator(),
                  Expanded(
                    child: _isSearching
                        ? Center(
                            child: Text(AppLocalizations.of(context)!
                                .offlineMapNoResults))
                        : _searchResults.isEmpty
                            ? Center(
                                child: Text(AppLocalizations.of(context)!
                                    .offlineMapNoResults))
                            : ListView.builder(
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) {
                                  final item = _searchResults[index];
                                  return ListTile(
                                    title: Text(item['name'].split(',')[0],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Text(item['name'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    trailing: const Icon(Icons.download),
                                    onTap: () => _startDownload(item),
                                  );
                                },
                              ),
                  ),
                ],
              ),

              // Task List
              StreamBuilder<List<DownloadTask>>(
                stream: _service.tasksStream,
                initialData: _service.getAllTasks(),
                builder: (context, snapshot) {
                  final tasks = snapshot.data ?? [];
                  if (tasks.isEmpty)
                    return Center(
                        child: Text(
                            AppLocalizations.of(context)!.offlineMapNoTasks));
                  final reversedTasks = tasks.reversed.toList();

                  return ListView.builder(
                    itemCount: reversedTasks.length,
                    itemBuilder: (context, index) {
                      final task = reversedTasks[index];
                      return _buildTaskItem(task);
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _doSearch() async {
    if (_searchCtrl.text.isEmpty) return;
    setState(() => _isSearching = true);
    final results = await _service.searchCity(_searchCtrl.text);
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
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
        statusText =
            AppLocalizations.of(context)!.offlineMapStatusDownloading(percent);
        break;
      case TaskStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        statusText = AppLocalizations.of(context)!.offlineMapStatusCompleted;
        break;
      case TaskStatus.failed:
        icon = Icons.error;
        color = Colors.red;
        statusText = AppLocalizations.of(context)!.offlineMapStatusFailed;
        break;
      case TaskStatus.pending:
        icon = Icons.schedule;
        color = Colors.orange;
        statusText = AppLocalizations.of(context)!.offlineMapStatusPending;
        break;
      default:
        icon = Icons.pause;
        color = Colors.grey;
        statusText = AppLocalizations.of(context)!.offlineMapStatusPaused;
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
                      _service.resumeTask(
                          task, url, AppLocalizations.of(context)!);
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
