import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/salary_plan.dart';
import 'database_service.dart';
import 'notification_service.dart';

class SalaryService {
  static const _uuid = Uuid();
  
  // Create or update salary plan
  static Future<SalaryPlan> saveSalaryPlan({
    required String userId,
    required double monthlySalary,
    required List<FixedExpense> fixedExpenses,
    required double savingsGoal,
    bool isPercentage = true,
    String? existingId,
    int incomeDay = 1,
    bool incomeReminderEnabled = true,
  }) async {
    final fixedExpensesJson = jsonEncode(
      fixedExpenses.map((e) => e.toJson()).toList(),
    );
    
    final plan = SalaryPlan(
      id: existingId ?? _uuid.v4(),
      userId: userId,
      monthlySalary: monthlySalary,
      fixedExpensesData: fixedExpensesJson,
      savingsGoal: savingsGoal,
      isPercentage: isPercentage,
      incomeDay: incomeDay,
      incomeReminderEnabled: incomeReminderEnabled,
    );
    
    await DatabaseService.saveSalaryPlan(plan);
    
    // Schedule income notification if enabled
    if (incomeReminderEnabled) {
      await NotificationService.scheduleIncomeReminder(
        incomeDay: incomeDay,
        amount: monthlySalary,
      );
    } else {
      await NotificationService.cancelIncomeReminder();
    }
    
    return plan;
  }
  
  // Get salary plan
  static SalaryPlan? getSalaryPlan(String userId) {
    return DatabaseService.getSalaryPlan(userId);
  }
  
  // Delete salary plan
  static Future<void> deleteSalaryPlan(String id) async {
    await DatabaseService.deleteSalaryPlan(id);
  }
  
  // Calculate remaining balance for current month
  static double calculateRemainingBalance(String userId) {
    final plan = getSalaryPlan(userId);
    if (plan == null) return 0;
    return plan.remainingBalance;
  }
  
  // Calculate daily spending limit
  static double calculateDailySpendingLimit(String userId) {
    final plan = getSalaryPlan(userId);
    if (plan == null) return 0;
    return plan.dailySpendingLimit;
  }
  
  // Check if overspending
  static bool isOverspending(String userId) {
    return calculateRemainingBalance(userId) < 0;
  }
  
  // Get spending analysis
  static Map<String, dynamic> getSpendingAnalysis(String userId) {
    final plan = getSalaryPlan(userId);
    if (plan == null) {
      return {'hasPlan': false};
    }
    
    return {
      'hasPlan': true,
      'monthlySalary': plan.monthlySalary,
      'savingsGoal': plan.savingsAmount,
      'remaining': plan.remainingBalance,
      'dailyLimit': plan.dailySpendingLimit,
      'budgetUsed': 50.0, // Placeholder
      'isOverspending': plan.remainingBalance < 0,
    };
  }
  
  // Get savings suggestion
  static String getSavingsSuggestion(String userId) {
    final plan = getSalaryPlan(userId);
    if (plan == null) {
      return 'Create a salary plan to start tracking your finances!';
    }
    return 'Great progress! Keep tracking your expenses.';
  }
}
