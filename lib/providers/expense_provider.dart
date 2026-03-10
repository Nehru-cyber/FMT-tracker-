import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _selectedCategory;
  DateTime _selectedMonth = DateTime.now();
  
  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get selectedCategory => _selectedCategory;
  DateTime get selectedMonth => _selectedMonth;
  
  double get totalIncome => _expenses
      .where((e) => e.type == ExpenseType.income)
      .fold(0, (sum, e) => sum + e.amount);
  
  double get totalExpense => _expenses
      .where((e) => e.type == ExpenseType.expense)
      .fold(0, (sum, e) => sum + e.amount);
  
  double get balance => totalIncome - totalExpense;
  
  List<Expense> get filteredExpenses {
    if (_selectedCategory == null) return _expenses;
    return _expenses.where((e) => e.category == _selectedCategory).toList();
  }
  
  void loadExpenses(String userId) {
    _isLoading = true;
    notifyListeners();
    
    _expenses = ExpenseService.getExpensesByMonth(
      userId,
      _selectedMonth.year,
      _selectedMonth.month,
    );
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> addExpense({
    required String userId,
    required double amount,
    required String category,
    required DateTime date,
    required ExpenseType type,
    String note = '',
  }) async {
    await ExpenseService.addExpense(
      userId: userId,
      amount: amount,
      category: category,
      date: date,
      type: type,
      note: note,
    );
    loadExpenses(userId);
  }
  
  Future<void> deleteExpense(String id, String userId) async {
    await ExpenseService.deleteExpense(id);
    loadExpenses(userId);
  }
  
  void setSelectedCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }
  
  void setSelectedMonth(DateTime month, String userId) {
    _selectedMonth = month;
    loadExpenses(userId);
  }
  
  Map<String, double> getCategoryBreakdown({ExpenseType? type}) {
    return ExpenseService.getCategoryBreakdown(_expenses, type: type);
  }
}
