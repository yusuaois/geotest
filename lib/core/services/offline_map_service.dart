import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:triggeo/core/utils/tile_math.dart';
import 'package:triggeo/data/models/download_task.dart';
import 'package:triggeo/data/models/offline_region.dart';
import 'package:triggeo/core/services/notification_service.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class OfflineMapService {
  final Dio _dio = Dio();
  final NotificationService _notificationService = NotificationService();
  static const String _taskBoxName = 'download_tasks';
  static const String _regionBoxName = 'offline_regions';

  static const int _maxConcurrency = 5;
  final Map<String, CancelToken> _cancelTokens = {};
  final StreamController<List<DownloadTask>> _tasksController =
      StreamController.broadcast();

  Stream<List<DownloadTask>> get tasksStream => _tasksController.stream;

  Future<void> init() async {
    if (!Hive.isBoxOpen(_taskBoxName))
      await Hive.openBox<DownloadTask>(_taskBoxName);
    if (!Hive.isBoxOpen(_regionBoxName))
      await Hive.openBox<OfflineRegion>(_regionBoxName);
    _emitTasks();
  }

  Future<void> createTask({
    required String cityName,
    required LatLngBounds bounds,
    required int minZoom,
    required int maxZoom,
    required String urlTemplate,
  }) async {
    final box = Hive.box<DownloadTask>(_taskBoxName);
    final taskId = const Uuid().v4();

    // Calculate the total number of tiles to download
    int total = 0;
    for (int z = minZoom; z <= maxZoom; z++) {
      var topLeft = TileMath.project(bounds.northWest, z);
      var bottomRight = TileMath.project(bounds.southEast, z);
      total += ((bottomRight.x - topLeft.x).abs() + 1) *
          ((bottomRight.y - topLeft.y).abs() + 1);
    }

    final task = DownloadTask(
      id: taskId,
      regionName: cityName,
      minLat: bounds.south,
      maxLat: bounds.north,
      minLon: bounds.west,
      maxLon: bounds.east,
      minZoom: minZoom,
      maxZoom: maxZoom,
      totalTiles: total,
      status: TaskStatus.pending,
    );

    await box.put(taskId, task);
    _emitTasks();
    _startDownload(task, urlTemplate);
  }

  Future<void> _updateTotalProgressNotification() async {
    if (!Hive.isBoxOpen(_taskBoxName)) return;

    final box = Hive.box<DownloadTask>(_taskBoxName);
    // 筛选出所有状态为 downloading 的任务
    final activeTasks =
        box.values.where((t) => t.status == TaskStatus.downloading).toList();

    if (activeTasks.isEmpty) {
      // 如果没有正在下载的任务，关闭通知
      await _notificationService.cancelDownloadNotification();
      return;
    }

    int totalTilesAll = 0;
    int downloadedTilesAll = 0;

    for (var task in activeTasks) {
      totalTilesAll += task.totalTiles;
      downloadedTilesAll += task.downloadedTiles;
    }

    // 调用通知服务
    await _notificationService.showDownloadProgress(
      progress: downloadedTilesAll,
      total: totalTilesAll,
      activeTasks: activeTasks.length,
    );
  }

  // --- 2. 核心下载逻辑 (多线程 + 重试) ---
  Future<void> _startDownload(DownloadTask task, String urlTemplate) async {
    task.status = TaskStatus.downloading;
    task.errorMessage = null;
    await task.save();
    _emitTasks();

    final cancelToken = CancelToken();
    _cancelTokens[task.id] = cancelToken;

    final appDir = await getApplicationDocumentsDirectory();
    final regionDir = '${appDir.path}/offline_maps/${task.id}';

    List<Map<String, dynamic>> tilesToDownload = [];
    for (int z = task.minZoom; z <= task.maxZoom; z++) {
      var topLeft = TileMath.project(task.bounds.northWest, z);
      var bottomRight = TileMath.project(task.bounds.southEast, z);
      for (int x = topLeft.x; x <= bottomRight.x; x++) {
        for (int y = topLeft.y; y <= bottomRight.y; y++) {
          tilesToDownload.add({'z': z, 'x': x, 'y': y});
        }
      }
    }

    int activeWorkers = 0;
    int index = 0;
    int saveCounter = 0;

    _updateTotalProgressNotification();

    try {
      while (index < tilesToDownload.length) {
        if (cancelToken.isCancelled)
          throw DioException(
              requestOptions: RequestOptions(), type: DioExceptionType.cancel);

        while (
            activeWorkers < _maxConcurrency && index < tilesToDownload.length) {
          final tile = tilesToDownload[index];
          index++;

          final z = tile['z'];
          final x = tile['x'];
          final y = tile['y'];
          final savePath = '$regionDir/$z/$x/$y.png';

          if (File(savePath).existsSync()) {
            if (task.downloadedTiles < index) task.downloadedTiles = index;
            continue;
          }

          activeWorkers++;

          _downloadSingleTile(urlTemplate, z, x, y, savePath, cancelToken)
              .then((_) {
            activeWorkers--;
            task.downloadedTiles++;
            saveCounter++;

            if (task.downloadedTiles % 5 == 0) {
              _updateTotalProgressNotification();
            }

            if (saveCounter >= 20 || task.downloadedTiles == task.totalTiles) {
              task.save();
              _emitTasks();
              saveCounter = 0;
            }
          }).catchError((e) {
            activeWorkers--;
            debugPrint("Tile failed: $e");
          });
        }
        await Future.delayed(const Duration(milliseconds: 50));
      }

      while (activeWorkers > 0) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (!cancelToken.isCancelled) {
        await _finishTask(task);
      }
    } catch (e) {
      if (CancelToken.isCancel(e as dynamic)) {
        task.status = TaskStatus.canceled;
      } else {
        task.status = TaskStatus.failed;
        task.errorMessage = e.toString();
      }
      await task.save();
      _emitTasks();
    } finally {
      _cancelTokens.remove(task.id);
      // 任务结束（无论成功失败），检查是否还有其他任务，更新或取消通知
      _updateTotalProgressNotification();
    }
  }

  // --- 3. 单个瓦片下载 (带重试) ---
  Future<void> _downloadSingleTile(String template, int z, int x, int y,
      String savePath, CancelToken token) async {
    final url = template
        .replaceAll('{z}', z.toString())
        .replaceAll('{x}', x.toString())
        .replaceAll('{y}', y.toString());

    int retryCount = 0;
    int maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        if (token.isCancelled) return;

        // 确保目录存在
        await File(savePath).parent.create(recursive: true);

        await _dio.download(
          url,
          savePath,
          cancelToken: token,
          options: Options(headers: {'User-Agent': 'TriggeoApp/1.0'}),
        );
        return; // 成功
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) rethrow; // 超过重试次数，抛出
        // 指数退避
        await Future.delayed(Duration(milliseconds: 500 * (1 << retryCount)));
      }
    }
  }

  // --- 4. 任务完成处理 ---
  Future<void> _finishTask(DownloadTask task) async {
    task.status = TaskStatus.completed;
    task.downloadedTiles = task.totalTiles;
    await task.save();

    // 转换为 OfflineRegion (供地图使用)
    final regionBox = Hive.box<OfflineRegion>(_regionBoxName);
    final region = OfflineRegion(
      id: task.id,
      name: task.regionName,
      minLat: task.minLat,
      maxLat: task.maxLat,
      minLon: task.minLon,
      maxLon: task.maxLon,
      minZoom: task.minZoom,
      maxZoom: task.maxZoom,
      tileCount: task.totalTiles,
      sizeInMB: task.totalTiles * 0.02,
      downloadDate: DateTime.now(),
    );
    await regionBox.put(task.id, region);

    // 任务完成后，可以选择删除 Task 记录，或者保留在“已完成”列表
    // 这里我们保留 Task 记录以便显示历史
    _emitTasks();
  }

  // --- 5. 操作控制 (暂停/取消/删除) ---

  // 暂停/取消下载
  Future<void> cancelTask(DownloadTask task) async {
    if (_cancelTokens.containsKey(task.id)) {
      _cancelTokens[task.id]?.cancel();
    }
    task.status = TaskStatus.canceled;
    await task.save();

    // 需求：取消时清理缓存
    await _deleteLocalFiles(task.id);

    // 从 Task 列表移除
    task.delete();
    _emitTasks();
  }

  // 删除已完成的地图
  Future<void> deleteRegion(String id) async {
    // 1. 删除文件
    await _deleteLocalFiles(id);
    // 2. 删除 OfflineRegion 记录
    final rBox = Hive.box<OfflineRegion>(_regionBoxName);
    await rBox.delete(id);
    // 3. 删除 Task 记录 (如果存在)
    final tBox = Hive.box<DownloadTask>(_taskBoxName);
    if (tBox.containsKey(id)) {
      await tBox.delete(id);
    }
    _emitTasks();
  }

  Future<void> _deleteLocalFiles(String id) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/offline_maps/$id');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  // 恢复/重试任务
  Future<void> resumeTask(DownloadTask task, String urlTemplate) async {
    if (task.status == TaskStatus.downloading) return;
    _startDownload(task, urlTemplate);
  }

  // 获取任务列表 (用于 UI 初始化)
  List<DownloadTask> getAllTasks() {
    if (!Hive.isBoxOpen(_taskBoxName)) return [];
    return Hive.box<DownloadTask>(_taskBoxName).values.toList();
  }

  void _emitTasks() {
    if (Hive.isBoxOpen(_taskBoxName)) {
      _tasksController
          .add(Hive.box<DownloadTask>(_taskBoxName).values.toList());
    }
  }

  // 搜索城市并获取边界
  Future<List<Map<String, dynamic>>> searchCity(String query) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?city=$query&format=json&limit=5');

    final response =
        await http.get(url, headers: {'User-Agent': 'TriggeoApp/1.0'});

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) {
        // Nominatim bbox 格式: [minLat, maxLat, minLon, maxLon] (字符串数组)
        final bbox = item['boundingbox'];
        return {
          'name': item['display_name'],
          'lat': double.parse(item['lat']),
          'lon': double.parse(item['lon']),
          'bounds': LatLngBounds(
            LatLng(
                double.parse(bbox[1]),
                double.parse(bbox[
                    2])), // NorthWest (MaxLat, MinLon) - latlong2定义可能不同，需注意
            LatLng(double.parse(bbox[0]),
                double.parse(bbox[3])), // SouthEast (MinLat, MaxLon)
          )
        };
      }).toList();
    }
    return [];
  }

  // 估算瓦片数量
  int estimateTileCount(LatLngBounds bounds, int minZoom, int maxZoom) {
    int count = 0;
    for (int z = minZoom; z <= maxZoom; z++) {
      var topLeft = TileMath.project(bounds.northWest, z);
      var bottomRight = TileMath.project(bounds.southEast, z);
      count += ((bottomRight.x - topLeft.x).abs() + 1) *
          ((bottomRight.y - topLeft.y).abs() + 1);
    }
    return count;
  }
}
