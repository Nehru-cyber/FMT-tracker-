import 'package:hive/hive.dart';

part 'wish.g.dart';

@HiveType(typeId: 30)
class Wish extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String userId;
  
  @HiveField(2)
  String title;
  
  @HiveField(3)
  double targetAmount;
  
  @HiveField(4)
  double savedAmount;
  
  @HiveField(5)
  String? imageUrl;
  
  @HiveField(6)
  DateTime createdAt;
  
  @HiveField(7)
  bool isCompleted;

  Wish({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    this.savedAmount = 0,
    this.imageUrl,
    DateTime? createdAt,
    this.isCompleted = false,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progress => (savedAmount / targetAmount).clamp(0.0, 1.0);
  double get remaining => targetAmount - savedAmount;

  Wish copyWith({
    String? id,
    String? userId,
    String? title,
    double? targetAmount,
    double? savedAmount,
    String? imageUrl,
    DateTime? createdAt,
    bool? isCompleted,
  }) {
    return Wish(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory Wish.fromJson(Map<String, dynamic> json) {
    return Wish(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      targetAmount: json['targetAmount']?.toDouble() ?? 0.0,
      savedAmount: json['savedAmount']?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}
