// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'salary_plan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SalaryPlanAdapter extends TypeAdapter<SalaryPlan> {
  @override
  final int typeId = 5;

  @override
  SalaryPlan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SalaryPlan(
      id: fields[0] as String,
      userId: fields[1] as String,
      monthlySalary: fields[2] as double,
      fixedExpensesData: fields[3] as String? ?? '[]',
      savingsGoal: fields[4] as double,
      isPercentage: fields[5] as bool? ?? true,
      createdAt: fields[6] as DateTime?,
      updatedAt: fields[7] as DateTime?,
      incomeDay: fields[8] as int? ?? 1,
      incomeReminderEnabled: fields[9] as bool? ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, SalaryPlan obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.monthlySalary)
      ..writeByte(3)
      ..write(obj.fixedExpensesData)
      ..writeByte(4)
      ..write(obj.savingsGoal)
      ..writeByte(5)
      ..write(obj.isPercentage)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.incomeDay)
      ..writeByte(9)
      ..write(obj.incomeReminderEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SalaryPlanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
