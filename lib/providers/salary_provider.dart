import 'package:flutter/material.dart';
import '../models/salary_plan.dart';
import '../services/salary_service.dart';

class SalaryProvider extends ChangeNotifier {
  SalaryPlan? _salaryPlan;
  Map<String, dynamic> _analysis = {};
  bool _isLoading = false;
  
  SalaryPlan? get salaryPlan => _salaryPlan;
  Map<String, dynamic> get analysis => _analysis;
  bool get isLoading => _isLoading;
  bool get hasPlan => _salaryPlan != null;
  
  void loadSalaryPlan(String userId) {
    _isLoading = true;
    notifyListeners();
    
    _salaryPlan = SalaryService.getSalaryPlan(userId);
    _analysis = SalaryService.getSpendingAnalysis(userId);
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> saveSalaryPlan({
    required String userId,
    required double monthlySalary,
    required List<FixedExpense> fixedExpenses,
    required double savingsGoal,
    bool isPercentage = true,
    int incomeDay = 1,
    bool incomeReminderEnabled = true,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    _salaryPlan = await SalaryService.saveSalaryPlan(
      userId: userId,
      monthlySalary: monthlySalary,
      fixedExpenses: fixedExpenses,
      savingsGoal: savingsGoal,
      isPercentage: isPercentage,
      existingId: _salaryPlan?.id,
      incomeDay: incomeDay,
      incomeReminderEnabled: incomeReminderEnabled,
    );
    
    _analysis = SalaryService.getSpendingAnalysis(userId);
    _isLoading = false;
    notifyListeners();
  }
  
  double get remainingBalance => _analysis['remaining'] ?? 0;
  double get dailyLimit => _analysis['dailyLimit'] ?? 0;
  bool get isOverspending => _analysis['isOverspending'] ?? false;
  String get suggestion => SalaryService.getSavingsSuggestion(
    _salaryPlan?.userId ?? '',
  );
}
