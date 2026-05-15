import 'package:hive/hive.dart';

part 'trip_plan.g.dart';

@HiveType(typeId: 20)
class TripPlan extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String userId;
  
  @HiveField(2)
  String name;
  
  @HiveField(3)
  double cost;
  
  @HiveField(4)
  String dietPlan;
  
  @HiveField(5)
  List<String> friends;
  
  @HiveField(6)
  DateTime date;
  
  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  bool isEdited;

  TripPlan({
    required this.id,
    required this.userId,
    required this.name,
    required this.cost,
    this.dietPlan = '',
    this.friends = const [],
    required this.date,
    DateTime? createdAt,
    this.isEdited = false,
  }) : createdAt = createdAt ?? DateTime.now();

  TripPlan copyWith({
    String? id,
    String? userId,
    String? name,
    double? cost,
    String? dietPlan,
    List<String>? friends,
    DateTime? date,
    DateTime? createdAt,
    bool? isEdited,
  }) {
    return TripPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      cost: cost ?? this.cost,
      dietPlan: dietPlan ?? this.dietPlan,
      friends: friends ?? this.friends,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'cost': cost,
      'dietPlan': dietPlan,
      'friends': friends,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isEdited': isEdited,
    };
  }

  factory TripPlan.fromJson(Map<String, dynamic> json) {
    return TripPlan(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      cost: json['cost']?.toDouble() ?? 0.0,
      dietPlan: json['dietPlan'] ?? '',
      friends: List<String>.from(json['friends'] ?? []),
      date: DateTime.parse(json['date']),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      isEdited: json['isEdited'] ?? false,
    );
  }
}
