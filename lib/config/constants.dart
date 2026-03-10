import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'FMT Tracker';
  static const String appVersion = '1.0.0';
  
  // Currency Options
  static const Map<String, String> currencies = {
    'INR': '₹',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
  };
  
  static const String defaultCurrency = 'INR';
  
  // Default Categories
  static const List<Map<String, dynamic>> defaultCategories = [
    {'name': 'Food', 'icon': 'restaurant', 'color': 0xFFFF6B6B},
    {'name': 'Travel', 'icon': 'directions_car', 'color': 0xFF4ECDC4},
    {'name': 'Rent', 'icon': 'home', 'color': 0xFF45B7D1},
    {'name': 'Shopping', 'icon': 'shopping_bag', 'color': 0xFFDDA0DD},
    {'name': 'Medical', 'icon': 'medical_services', 'color': 0xFF98D8C8},
    {'name': 'Entertainment', 'icon': 'movie', 'color': 0xFFF7DC6F},
    {'name': 'Bills', 'icon': 'receipt', 'color': 0xFFBB8FCE},
    {'name': 'Education', 'icon': 'school', 'color': 0xFF85C1E9},
    {'name': 'Salary', 'icon': 'account_balance_wallet', 'color': 0xFF10B981},
    {'name': 'Freelance', 'icon': 'work', 'color': 0xFF6366F1},
    {'name': 'Investment', 'icon': 'trending_up', 'color': 0xFF22C55E},
    {'name': 'Gift', 'icon': 'card_giftcard', 'color': 0xFFF59E0B},
    {'name': 'Other', 'icon': 'more_horiz', 'color': 0xFF95A5A6},
  ];
  
  // Category Icons Map
  static const Map<String, IconData> categoryIcons = {
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'home': Icons.home,
    'shopping_bag': Icons.shopping_bag,
    'medical_services': Icons.medical_services,
    'movie': Icons.movie,
    'receipt': Icons.receipt,
    'school': Icons.school,
    'account_balance_wallet': Icons.account_balance_wallet,
    'work': Icons.work,
    'trending_up': Icons.trending_up,
    'card_giftcard': Icons.card_giftcard,
    'more_horiz': Icons.more_horiz,
  };
  
  // Premium Features
  static const double premiumMonthlyPrice = 99.0;
  static const double premiumYearlyPrice = 799.0;
  
  static const List<String> premiumFeatures = [
    'No advertisements',
    'PDF & Excel export',
    'Cloud backup',
    'Business accounting',
    'Advanced analytics',
    'Priority support',
  ];
  
  static const List<String> freeFeatures = [
    'Expense tracking',
    'Salary planner',
    'EMI calculator',
    'Basic analytics',
  ];
  
  // Hive Box Names
  static const String userBox = 'users';
  static const String expenseBox = 'expenses';
  static const String categoryBox = 'categories';
  static const String salaryBox = 'salary_plans';
  static const String emiBox = 'emi_records';
  static const String businessBox = 'businesses';
  static const String transactionBox = 'business_transactions';
  static const String customerBox = 'customers';
  static const String settingsBox = 'settings';
  static const String tripBox = 'trip_plans';
  static const String investmentBox = 'investments';
  
  // Date Formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String monthYearFormat = 'MMMM yyyy';
  static const String timeFormat = 'hh:mm a';
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
}
