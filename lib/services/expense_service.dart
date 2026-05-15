import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import 'database_service.dart';

class ExpenseService {
  static const _uuid = Uuid();
  
  // Add expense
  static Future<Expense> addExpense({
    required String userId,
    required double amount,
    required String category,
    required DateTime date,
    required ExpenseType type,
    String note = '',
    String? mood,
  }) async {
    final expense = Expense(
      id: _uuid.v4(),
      userId: userId,
      amount: amount,
      category: category,
      date: date,
      type: type,
      note: note,
      mood: mood,
    );
    
    await DatabaseService.saveExpense(expense);
    return expense;
  }
  
  // Update expense
  static Future<Expense?> updateExpense({
    required String id,
    required String userId,
    double? amount,
    String? category,
    DateTime? date,
    ExpenseType? type,
    String? note,
    String? mood,
  }) async {
    final expenses = await DatabaseService.getExpenses(userId);
    final expense = expenses.where((e) => e.id == id).firstOrNull;
    if (expense == null) return null;
    
    final updated = expense.copyWith(
      amount: amount,
      category: category,
      date: date,
      type: type,
      note: note,
      mood: mood,
      isEdited: true,
    );
    
    await DatabaseService.saveExpense(updated);
    return updated;
  }
  
  // Delete expense
  static Future<void> deleteExpense(String id) async {
    await DatabaseService.deleteExpense(id);
  }
  
  // Get all expenses for user
  static Future<List<Expense>> getExpenses(String userId) async {
    return await DatabaseService.getExpenses(userId);
  }
  
  // Get expenses by date range
  static Future<List<Expense>> getExpensesByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    return await DatabaseService.getExpensesByDateRange(userId, start, end);
  }
  
  // Get expenses by month
  static Future<List<Expense>> getExpensesByMonth(String userId, int year, int month) async {
    return await DatabaseService.getExpensesByMonth(userId, year, month);
  }
  
  // Get today's expenses
  static Future<List<Expense>> getTodayExpenses(String userId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return await getExpensesByDateRange(userId, today, tomorrow);
  }
  
  // Get this week's expenses
  static Future<List<Expense>> getThisWeekExpenses(String userId) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return await getExpensesByDateRange(userId, start, now);
  }
  
  // Get this month's expenses
  static Future<List<Expense>> getThisMonthExpenses(String userId) async {
    final now = DateTime.now();
    return await getExpensesByMonth(userId, now.year, now.month);
  }
  
  // Calculate totals
  static Map<String, double> calculateTotals(List<Expense> expenses) {
    double totalIncome = 0;
    double totalExpense = 0;
    
    for (final expense in expenses) {
      if (expense.type == ExpenseType.income) {
        totalIncome += expense.amount;
      } else {
        totalExpense += expense.amount;
      }
    }
    
    return {
      'income': totalIncome,
      'expense': totalExpense,
      'balance': totalIncome - totalExpense,
    };
  }
  
  // Get category-wise breakdown
  static Map<String, double> getCategoryBreakdown(List<Expense> expenses, {ExpenseType? type}) {
    final breakdown = <String, double>{};
    
    for (final expense in expenses) {
      if (type != null && expense.type != type) continue;
      
      breakdown[expense.category] = (breakdown[expense.category] ?? 0) + expense.amount;
    }
    
    return breakdown;
  }
  
  // Get daily breakdown for a month
  static Future<Map<int, Map<String, double>>> getDailyBreakdown(String userId, int year, int month) async {
    final expenses = await getExpensesByMonth(userId, year, month);
    final breakdown = <int, Map<String, double>>{};
    
    for (final expense in expenses) {
      final day = expense.date.day;
      breakdown[day] ??= {'income': 0, 'expense': 0};
      
      if (expense.type == ExpenseType.income) {
        breakdown[day]!['income'] = (breakdown[day]!['income'] ?? 0) + expense.amount;
      } else {
        breakdown[day]!['expense'] = (breakdown[day]!['expense'] ?? 0) + expense.amount;
      }
    }
    
    return breakdown;
  }
  
  // Get monthly breakdown for a year
  static Future<Map<int, Map<String, double>>> getMonthlyBreakdown(String userId, int year) async {
    final breakdown = <int, Map<String, double>>{};
    
    for (int month = 1; month <= 12; month++) {
      final expenses = await getExpensesByMonth(userId, year, month);
      final totals = calculateTotals(expenses);
      breakdown[month] = totals;
    }
    
    return breakdown;
  }
  
  // Search expenses
  static Future<List<Expense>> searchExpenses(String userId, String query) async {
    final expenses = await getExpenses(userId);
    final lowerQuery = query.toLowerCase();
    
    return expenses.where((e) =>
      e.category.toLowerCase().contains(lowerQuery) ||
      e.note.toLowerCase().contains(lowerQuery)
    ).toList();
  }
}
