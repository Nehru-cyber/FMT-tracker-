import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'category.g.dart';

@HiveType(typeId: 3)
class Category extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  String icon;
  
  @HiveField(3)
  int colorValue;
  
  @HiveField(4)
  bool isCustom;
  
  @HiveField(5)
  bool isIncome;
  
  @HiveField(6)
  String userId;
  
  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
    this.isCustom = false,
    this.isIncome = false,
    this.userId = '',
  });
  
  Color get color => Color(colorValue);
  
  Category copyWith({
    String? id,
    String? name,
    String? icon,
    int? colorValue,
    bool? isCustom,
    bool? isIncome,
    String? userId,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
      isCustom: isCustom ?? this.isCustom,
      isIncome: isIncome ?? this.isIncome,
      userId: userId ?? this.userId,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'colorValue': colorValue,
      'isCustom': isCustom,
      'isIncome': isIncome,
      'userId': userId,
    };
  }
  
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      colorValue: json['colorValue'],
      isCustom: json['isCustom'] ?? false,
      isIncome: json['isIncome'] ?? false,
      userId: json['userId'] ?? '',
    );
  }
}
