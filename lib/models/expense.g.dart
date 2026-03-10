// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseTypeAdapter extends TypeAdapter<ExpenseType> {
  @override
  final int typeId = 1;

  @override
  ExpenseType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExpenseType.income;
      case 1:
        return ExpenseType.expense;
      default:
        return ExpenseType.expense;
    }
  }

  @override
  void write(BinaryWriter writer, ExpenseType obj) {
    switch (obj) {
      case ExpenseType.income:
        writer.writeByte(0);
        break;
      case ExpenseType.expense:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 2;

  @override
  Expense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Expense(
      id: fields[0] as String,
      userId: fields[1] as String,
      amount: fields[2] as double,
      category: fields[3] as String,
      note: fields[4] as String,
      date: fields[5] as DateTime,
      type: fields[6] as ExpenseType,
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
