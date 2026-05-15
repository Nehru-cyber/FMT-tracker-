import 'package:hive/hive.dart';

part 'business.g.dart';

@HiveType(typeId: 8)
class Business extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String userId;
  
  @HiveField(2)
  String name;
  
  @HiveField(3)
  String type;
  
  @HiveField(4)
  String? description;
  
  @HiveField(5)
  DateTime createdAt;
  
  @HiveField(6)
  bool isEdited;
  
  Business({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.description,
    DateTime? createdAt,
    this.isEdited = false,
  }) : createdAt = createdAt ?? DateTime.now();
  
  Business copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    String? description,
    DateTime? createdAt,
    bool? isEdited,
  }) {
    return Business(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isEdited: isEdited ?? this.isEdited,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'type': type,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'isEdited': isEdited,
    };
  }
  
  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      type: json['type'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      isEdited: json['isEdited'] ?? false,
    );
  }
}

@HiveType(typeId: 9)
class Customer extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String businessId;
  
  @HiveField(2)
  String name;
  
  @HiveField(3)
  String phone;
  
  @HiveField(4)
  String? email;
  
  @HiveField(5)
  String? address;
  
  @HiveField(6)
  double totalDue;
  
  @HiveField(7)
  DateTime createdAt;
  
  @HiveField(8)
  bool isEdited;
  
  Customer({
    required this.id,
    required this.businessId,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.totalDue = 0,
    DateTime? createdAt,
    this.isEdited = false,
  }) : createdAt = createdAt ?? DateTime.now();
  
  Customer copyWith({
    String? id,
    String? businessId,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? totalDue,
    DateTime? createdAt,
    bool? isEdited,
  }) {
    return Customer(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      totalDue: totalDue ?? this.totalDue,
      createdAt: createdAt ?? this.createdAt,
      isEdited: isEdited ?? this.isEdited,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'totalDue': totalDue,
      'createdAt': createdAt.toIso8601String(),
      'isEdited': isEdited,
    };
  }
  
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      businessId: json['businessId'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      totalDue: json['totalDue']?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      isEdited: json['isEdited'] ?? false,
    );
  }
}
