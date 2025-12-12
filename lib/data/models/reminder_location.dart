import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'reminder_location.g.dart';

@HiveType(typeId: 1)
enum ReminderType {
  @HiveField(0)
  ringtone,
  @HiveField(1)
  vibration,
  @HiveField(2)
  both,
}

@HiveType(typeId: 0)
class ReminderLocation extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  double latitude;
  @HiveField(3)
  double longitude;
  @HiveField(4)
  double radius;
  @HiveField(5)
  bool isActive;
  @HiveField(6)
  ReminderType type;

  ReminderLocation({
    String? id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radius = 100.0,
    this.isActive = true,
    this.type = ReminderType.both,
  }) : id = id ?? const Uuid().v4();
}