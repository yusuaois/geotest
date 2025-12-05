import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rxdart/rxdart.dart';
import 'package:triggeo/data/models/reminder_location.dart';

class ReminderRepository {
  static const String boxName = 'reminders';

  // 初始化 Hive (务必在 main.dart 调用)
  static Future<void> init() async {
    if(!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ReminderLocationAdapter()); 
    if(!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ReminderTypeAdapter());
    await Hive.openBox<ReminderLocation>(boxName);
  }

  Box<ReminderLocation> get _box => Hive.box<ReminderLocation>(boxName);

  List<ReminderLocation> getAll() => _box.values.toList();
  
  // 增加/修改
  Future<void> save(ReminderLocation item) async => await _box.put(item.id, item);
  
  // 删除
  Future<void> delete(String id) async => await _box.delete(id);
}

final reminderRepositoryProvider = Provider((ref) => ReminderRepository());

// 实时监听数据库变化的 Provider (给 UI 用)
final reminderListProvider = StreamProvider<List<ReminderLocation>>((ref) {
  final box = Hive.box<ReminderLocation>(ReminderRepository.boxName);
  return box.watch()
      .map((_) => box.values.toList())
      .startWith(box.values.toList());
});