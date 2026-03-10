// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emi.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EMIAdapter extends TypeAdapter<EMI> {
  @override
  final int typeId = 7;

  @override
  EMI read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EMI(
      id: fields[0] as String,
      userId: fields[1] as String,
      name: fields[2] as String,
      loanAmount: fields[3] as double,
      interestRate: fields[4] as double,
      tenureMonths: fields[5] as int,
      monthlyEMI: fields[6] as double,
      totalInterest: fields[7] as double,
      totalPayable: fields[8] as double,
      createdAt: fields[9] as DateTime,
      startDate: fields[10] as DateTime?,
      paymentDay: fields[11] as int? ?? 5,
      reminderDaysBefore: fields[12] as int? ?? 2,
      isReminderEnabled: fields[13] as bool? ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, EMI obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.loanAmount)
      ..writeByte(4)
      ..write(obj.interestRate)
      ..writeByte(5)
      ..write(obj.tenureMonths)
      ..writeByte(6)
      ..write(obj.monthlyEMI)
      ..writeByte(7)
      ..write(obj.totalInterest)
      ..writeByte(8)
      ..write(obj.totalPayable)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.startDate)
      ..writeByte(11)
      ..write(obj.paymentDay)
      ..writeByte(12)
      ..write(obj.reminderDaysBefore)
      ..writeByte(13)
      ..write(obj.isReminderEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EMIAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
