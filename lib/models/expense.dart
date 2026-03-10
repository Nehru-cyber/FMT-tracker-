import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 1)
enum ExpenseType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
}

@HiveType(typeId: 2)
class Expense extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String userId;
  
  @HiveField(2)
  double amount;
  
  @HiveField(3)
  String category;
  
  @HiveField(4)
  String note;
  
  @HiveField(5)
  DateTime date;
  
  @HiveField(6)
  ExpenseType type;
  
  @HiveField(7)
  DateTime createdAt;
  
  Expense({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    this.note = '',
    required this.date,
    required this.type,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  Expense copyWith({
    String? id,
    String? userId,
    double? amount,
    String? category,
    String? note,
    DateTime? date,
    ExpenseType? type,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'category': category,
      'note': note,
      'date': date.toIso8601String(),
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      userId: json['userId'],
      amount: json['amount'].toDouble(),
      category: json['category'],
      note: json['note'] ?? '',
      date: DateTime.parse(json['date']),
      type: ExpenseType.values.firstWhere((e) => e.name == json['type']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
