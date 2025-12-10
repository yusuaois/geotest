import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rxdart/rxdart.dart';
import 'package:triggeo/data/models/reminder_location.dart';

class ReminderRepository {
  static const String boxName = 'reminders';

  // Initialize Hive box
  static Future<void> init() async {
    if(!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ReminderLocationAdapter()); 
    if(!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ReminderTypeAdapter());
    await Hive.openBox<ReminderLocation>(boxName);
  }

  Box<ReminderLocation> get _box => Hive.box<ReminderLocation>(boxName);
  List<ReminderLocation> getAll() => _box.values.toList();
  Future<void> save(ReminderLocation item) async => await _box.put(item.id, item);
  Future<void> delete(String id) async => await _box.delete(id);
}

final reminderRepositoryProvider = Provider((ref) => ReminderRepository());

// StreamProvider for the list of reminders
final reminderListProvider = StreamProvider<List<ReminderLocation>>((ref) {
  final box = Hive.box<ReminderLocation>(ReminderRepository.boxName);
  return box.watch()
      .map((_) => box.values.toList())
      .startWith(box.values.toList());
});