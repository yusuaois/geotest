// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_region.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OfflineRegionAdapter extends TypeAdapter<OfflineRegion> {
  @override
  final int typeId = 2;

  @override
  OfflineRegion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineRegion(
      id: fields[0] as String,
      name: fields[1] as String,
      minLat: fields[2] as double,
      maxLat: fields[3] as double,
      minLon: fields[4] as double,
      maxLon: fields[5] as double,
      minZoom: fields[6] as int,
      maxZoom: fields[7] as int,
      tileCount: fields[8] as int,
      sizeInMB: fields[9] as double,
      downloadDate: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineRegion obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
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
      ..write(obj.tileCount)
      ..writeByte(9)
      ..write(obj.sizeInMB)
      ..writeByte(10)
      ..write(obj.downloadDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineRegionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
