import 'package:hive/hive.dart';

part 'business_transaction.g.dart';

@HiveType(typeId: 10)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
}

@HiveType(typeId: 11)
class BusinessTransaction extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String businessId;
  
  @HiveField(2)
  String? customerId;
  
  @HiveField(3)
  double amount;
  
  @HiveField(4)
  TransactionType type;
  
  @HiveField(5)
  String note;
  
  @HiveField(6)
  DateTime date;
  
  @HiveField(7)
  String? category;
  
  @HiveField(8)
  DateTime createdAt;
  
  @HiveField(9)
  bool isEdited;
  
  BusinessTransaction({
    required this.id,
    required this.businessId,
    this.customerId,
    required this.amount,
    required this.type,
    this.note = '',
    required this.date,
    this.category,
    DateTime? createdAt,
    this.isEdited = false,
  }) : createdAt = createdAt ?? DateTime.now();
  
  BusinessTransaction copyWith({
    String? id,
    String? businessId,
    String? customerId,
    double? amount,
    TransactionType? type,
    String? note,
    DateTime? date,
    String? category,
    DateTime? createdAt,
    bool? isEdited,
  }) {
    return BusinessTransaction(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      customerId: customerId ?? this.customerId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      note: note ?? this.note,
      date: date ?? this.date,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      isEdited: isEdited ?? this.isEdited,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'customerId': customerId,
      'amount': amount,
      'type': type.name,
      'note': note,
      'date': date.toIso8601String(),
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'isEdited': isEdited,
    };
  }
  
  factory BusinessTransaction.fromJson(Map<String, dynamic> json) {
    return BusinessTransaction(
      id: json['id'],
      businessId: json['businessId'],
      customerId: json['customerId'],
      amount: json['amount'].toDouble(),
      type: TransactionType.values.firstWhere((e) => e.name == json['type']),
      note: json['note'] ?? '',
      date: DateTime.parse(json['date']),
      category: json['category'],
      createdAt: DateTime.parse(json['createdAt']),
      isEdited: json['isEdited'] ?? false,
    );
  }
}
