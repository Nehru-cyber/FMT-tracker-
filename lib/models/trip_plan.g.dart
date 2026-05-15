// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_plan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TripPlanAdapter extends TypeAdapter<TripPlan> {
  @override
  final int typeId = 20;

  @override
  TripPlan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TripPlan(
      id: fields[0] as String,
      userId: fields[1] as String,
      name: fields[2] as String,
      cost: fields[3] as double,
      dietPlan: fields[4] as String,
      friends: (fields[5] as List).cast<String>(),
      date: fields[6] as DateTime,
      createdAt: fields[7] as DateTime?,
      isEdited: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TripPlan obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.cost)
      ..writeByte(4)
      ..write(obj.dietPlan)
      ..writeByte(5)
      ..write(obj.friends)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.isEdited);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripPlanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
