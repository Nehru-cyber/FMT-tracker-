import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  String email;
  
  @HiveField(3)
  String phone;
  
  @HiveField(4)
  bool isPremium;
  
  @HiveField(5)
  String currency;
  
  @HiveField(6)
  DateTime createdAt;
  
  @HiveField(7)
  bool isGuest;
  
  @HiveField(8)
  bool biometricEnabled;
  
  @HiveField(9)
  String? password;
  
  @HiveField(10)
  String? photoPath;
  
  @HiveField(11)
  String? bio;
  
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.isPremium = false,
    this.currency = 'INR',
    DateTime? createdAt,
    this.isGuest = false,
    this.biometricEnabled = false,
    this.password,
    this.photoPath,
    this.bio,
  }) : createdAt = createdAt ?? DateTime.now();
  
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    bool? isPremium,
    String? currency,
    DateTime? createdAt,
    bool? isGuest,
    bool? biometricEnabled,
    String? password,
    String? photoPath,
    String? bio,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isPremium: isPremium ?? this.isPremium,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      isGuest: isGuest ?? this.isGuest,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      password: password ?? this.password,
      photoPath: photoPath ?? this.photoPath,
      bio: bio ?? this.bio,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'isPremium': isPremium,
      'currency': currency,
      'createdAt': createdAt.toIso8601String(),
      'isGuest': isGuest,
      'biometricEnabled': biometricEnabled,
      'password': password,
      'photoPath': photoPath,
      'bio': bio,
    };
  }
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      isPremium: json['isPremium'] ?? false,
      currency: json['currency'] ?? 'INR',
      createdAt: DateTime.parse(json['createdAt']),
      isGuest: json['isGuest'] ?? false,
      biometricEnabled: json['biometricEnabled'] ?? false,
      password: json['password'],
      photoPath: json['photoPath'],
      bio: json['bio'],
    );
  }
  
  factory User.guest() {
    return User(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Guest User',
      email: '',
      phone: '',
      isGuest: true,
    );
  }
}
