import 'package:hive/hive.dart';

part 'investment.g.dart';

@HiveType(typeId: 21)
class Investment extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String userId;
  
  @HiveField(2)
  String name;
  
  @HiveField(3)
  double amount;
  
  @HiveField(4)
  int investDay; // Day of the month for reminders (1-31)
  
  @HiveField(5)
  String type; // 'SIP', 'Mutual Fund', 'Stocks', etc.
  
  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  bool isEdited;

  Investment({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.investDay,
    required this.type,
    DateTime? createdAt,
    this.isEdited = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Investment copyWith({
    String? id,
    String? userId,
    String? name,
    double? amount,
    int? investDay,
    String? type,
    DateTime? createdAt,
    bool? isEdited,
  }) {
    return Investment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      investDay: investDay ?? this.investDay,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'amount': amount,
      'investDay': investDay,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'isEdited': isEdited,
    };
  }

  factory Investment.fromJson(Map<String, dynamic> json) {
    return Investment(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      amount: json['amount']?.toDouble() ?? 0.0,
      investDay: json['investDay'] ?? 1,
      type: json['type'] ?? 'SIP',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      isEdited: json['isEdited'] ?? false,
    );
  }
}
