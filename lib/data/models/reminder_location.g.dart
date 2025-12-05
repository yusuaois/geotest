// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_location.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReminderLocationAdapter extends TypeAdapter<ReminderLocation> {
  @override
  final int typeId = 0;

  @override
  ReminderLocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReminderLocation(
      id: fields[0] as String?,
      name: fields[1] as String,
      latitude: fields[2] as double,
      longitude: fields[3] as double,
      radius: fields[4] as double,
      isActive: fields[5] as bool,
      type: fields[6] as ReminderType,
    );
  }

  @override
  void write(BinaryWriter writer, ReminderLocation obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.latitude)
      ..writeByte(3)
      ..write(obj.longitude)
      ..writeByte(4)
      ..write(obj.radius)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderLocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReminderTypeAdapter extends TypeAdapter<ReminderType> {
  @override
  final int typeId = 1;

  @override
  ReminderType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ReminderType.ringtone;
      case 1:
        return ReminderType.vibration;
      case 2:
        return ReminderType.both;
      default:
        return ReminderType.ringtone;
    }
  }

  @override
  void write(BinaryWriter writer, ReminderType obj) {
    switch (obj) {
      case ReminderType.ringtone:
        writer.writeByte(0);
        break;
      case ReminderType.vibration:
        writer.writeByte(1);
        break;
      case ReminderType.both:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
