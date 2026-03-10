import 'dart:convert';
import 'package:hive/hive.dart';

part 'salary_plan.g.dart';

class FixedExpense {
  String name;
  double amount;
  String category;
  
  FixedExpense({
    required this.name,
    required this.amount,
    this.category = 'Bills',
  });
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'category': category,
    };
  }
  
  factory FixedExpense.fromJson(Map<String, dynamic> json) {
    return FixedExpense(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: (json['category'] as String?) ?? 'Bills',
    );
  }
}

@HiveType(typeId: 5)
class SalaryPlan extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String userId;
  
  @HiveField(2)
  double monthlySalary;
  
  @HiveField(3)
  String fixedExpensesData; // JSON string instead of List
  
  @HiveField(4)
  double savingsGoal;
  
  @HiveField(5)
  bool isPercentage;
  
  @HiveField(6)
  DateTime createdAt;
  
  @HiveField(7)
  DateTime updatedAt;
  
  @HiveField(8)
  int incomeDay; // Day of month when salary is credited (1-28)
  
  @HiveField(9)
  bool incomeReminderEnabled;
  
  SalaryPlan({
    required this.id,
    required this.userId,
    required this.monthlySalary,
    this.fixedExpensesData = '[]',
    required this.savingsGoal,
    this.isPercentage = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.incomeDay = 1,
    this.incomeReminderEnabled = true,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();
  
  // Get next income date
  DateTime get nextIncomeDate {
    final now = DateTime.now();
    var nextDate = DateTime(now.year, now.month, incomeDay);
    if (nextDate.isBefore(now) || nextDate.day == now.day) {
      nextDate = DateTime(now.year, now.month + 1, incomeDay);
    }
    return nextDate;
  }
  
  // Get days until next income
  int get daysUntilIncome {
    return nextIncomeDate.difference(DateTime.now()).inDays;
  }
  
  List<FixedExpense> get fixedExpenses {
    if (fixedExpensesData.isEmpty || fixedExpensesData == '[]') {
      return [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(fixedExpensesData);
      return decoded.map((e) => FixedExpense.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }
  
  double get totalFixedExpenses {
    return fixedExpenses.fold(0, (sum, item) => sum + item.amount);
  }
  
  double get savingsAmount => 
      isPercentage ? monthlySalary * (savingsGoal / 100) : savingsGoal;
  
  double get remainingBalance => 
      monthlySalary - totalFixedExpenses - savingsAmount;
  
  double get dailySpendingLimit {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final remainingDays = daysInMonth - now.day + 1;
    return remainingBalance / remainingDays;
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'monthlySalary': monthlySalary,
      'fixedExpenses': fixedExpenses.map((e) => e.toJson()).toList(),
      'savingsGoal': savingsGoal,
      'isPercentage': isPercentage,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
