// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DownloadTaskAdapter extends TypeAdapter<DownloadTask> {
  @override
  final int typeId = 4;

  @override
  DownloadTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadTask(
      id: fields[0] as String,
      regionName: fields[1] as String,
      minLat: fields[2] as double,
      maxLat: fields[3] as double,
      minLon: fields[4] as double,
      maxLon: fields[5] as double,
      minZoom: fields[6] as int,
      maxZoom: fields[7] as int,
      totalTiles: fields[8] as int,
      downloadedTiles: fields[9] as int,
      status: fields[10] as TaskStatus,
      errorMessage: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DownloadTask obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.regionName)
      ..writeByte(2)
      ..write(obj.minLat)
      ..writeByte(3)
      ..write(obj.maxLat)
      ..writeByte(4)
      ..write(obj.minLon)
      ..writeByte(5)
      ..write(obj.maxLon)
      ..writeByte(6)
      ..write(obj.minZoom)
      ..writeByte(7)
      ..write(obj.maxZoom)
      ..writeByte(8)
      ..write(obj.totalTiles)
      ..writeByte(9)
      ..write(obj.downloadedTiles)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.errorMessage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskStatusAdapter extends TypeAdapter<TaskStatus> {
  @override
  final int typeId = 3;

  @override
  TaskStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskStatus.pending;
      case 1:
        return TaskStatus.downloading;
      case 2:
        return TaskStatus.paused;
      case 3:
        return TaskStatus.completed;
      case 4:
        return TaskStatus.failed;
      case 5:
        return TaskStatus.canceled;
      default:
        return TaskStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, TaskStatus obj) {
    switch (obj) {
      case TaskStatus.pending:
        writer.writeByte(0);
        break;
      case TaskStatus.downloading:
        writer.writeByte(1);
        break;
      case TaskStatus.paused:
        writer.writeByte(2);
        break;
      case TaskStatus.completed:
        writer.writeByte(3);
        break;
      case TaskStatus.failed:
        writer.writeByte(4);
        break;
      case TaskStatus.canceled:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
