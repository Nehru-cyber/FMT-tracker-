import 'package:flutter/foundation.dart' show debugPrint;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/salary_plan.dart';
import '../models/emi.dart';
import '../models/business.dart';
import '../models/business_transaction.dart';
import '../models/trip_plan.dart';
import '../models/investment.dart';
import '../config/constants.dart';

class DatabaseService {
  static late Box _usersBox;
  static late Box _expensesBox;
  static late Box _categoriesBox;
  static late Box _salaryBox;
  static late Box _emiBox;
  static late Box _businessBox;
  static late Box _customerBox;
  static late Box _transactionBox;
  static late Box _tripBox;
  static late Box _investmentBox;
  static late Box _settingsBox;

  static bool _isInitialized = false;
  
  static bool get isInitialized => _isInitialized;

  static Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      
      _usersBox = await Hive.openBox(AppConstants.userCollection);
      _expensesBox = await Hive.openBox(AppConstants.expenseCollection);
      _categoriesBox = await Hive.openBox(AppConstants.categoryCollection);
      _salaryBox = await Hive.openBox(AppConstants.salaryCollection);
      _emiBox = await Hive.openBox(AppConstants.emiCollection);
      _businessBox = await Hive.openBox(AppConstants.businessCollection);
      _customerBox = await Hive.openBox(AppConstants.customerCollection);
      _transactionBox = await Hive.openBox(AppConstants.transactionCollection);
      _tripBox = await Hive.openBox(AppConstants.tripCollection);
      _investmentBox = await Hive.openBox(AppConstants.investmentCollection);
      _settingsBox = await Hive.openBox(AppConstants.settingsCollection);

      // Initialize default categories if empty
      if (_categoriesBox.isEmpty) {
        await _initializeDefaultCategories();
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('DatabaseService.initialize error: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  static Future<void> _initializeDefaultCategories() async {
    for (int i = 0; i < AppConstants.defaultCategories.length; i++) {
      final cat = AppConstants.defaultCategories[i];
      final category = Category(
        id: 'cat_$i',
        name: cat['name'],
        icon: cat['icon'],
        colorValue: cat['color'],
        isCustom: false,
        isIncome: ['Salary', 'Freelance', 'Investment', 'Gift'].contains(cat['name']),
      );
      await _categoriesBox.put(category.id, category.toJson());
    }
  }

  // User operations
  static Future<void> saveUser(User user) async {
    await _usersBox.put(user.id, user.toJson());
  }

  static Future<User?> getUser(String id) async {
    if (!_isInitialized) return null;
    final doc = _usersBox.get(id);
    if (doc == null) return null;
    return User.fromJson(Map<String, dynamic>.from(doc));
  }

  static Future<User?> getCurrentUser() async {
    return await getLoggedInUser();
  }

  static Future<User?> getLoggedInUser() async {
    final currentUserId = await getSetting('currentUserId');
    if (currentUserId == null) return null;
    return await getUser(currentUserId);
  }

  static Future<void> deleteUser(String id) async {
    await _usersBox.delete(id);
  }

  // Expense operations
  static Future<void> saveExpense(Expense expense) async {
    await _expensesBox.put(expense.id, expense.toJson());
  }

  static Future<List<Expense>> getExpenses(String userId) async {
    final docs = _expensesBox.values.where((doc) => doc['userId'] == userId).toList();
    docs.sort((a, b) => b['date'].compareTo(a['date']));
    return docs.map((doc) => Expense.fromJson(Map<String, dynamic>.from(doc))).toList();
  }

  static Future<List<Expense>> getExpensesByDateRange(String userId, DateTime start, DateTime end) async {
    final docs = _expensesBox.values.where((doc) {
      if (doc['userId'] != userId) return false;
      final date = DateTime.parse(doc['date']);
      return date.isAfter(start.subtract(const Duration(days: 1))) && 
             date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
    docs.sort((a, b) => b['date'].compareTo(a['date']));
    return docs.map((doc) => Expense.fromJson(Map<String, dynamic>.from(doc))).toList();
  }

  static Future<List<Expense>> getExpensesByMonth(String userId, int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return await getExpensesByDateRange(userId, start, end);
  }

  static Future<void> deleteExpense(String id) async {
    await _expensesBox.delete(id);
  }

  // Category operations
  static Future<List<Category>> getCategories({bool? isIncome}) async {
    var docs = _categoriesBox.values;
    if (isIncome != null) {
      docs = docs.where((doc) => doc['isIncome'] == isIncome);
    }
    return docs.map((doc) => Category.fromJson(Map<String, dynamic>.from(doc))).toList();
  }

  static Future<void> saveCategory(Category category) async {
    await _categoriesBox.put(category.id, category.toJson());
  }

  static Future<void> deleteCategory(String id) async {
    await _categoriesBox.delete(id);
  }

  // Salary Plan operations
  static Future<void> saveSalaryPlan(SalaryPlan plan) async {
    await _salaryBox.put(plan.id, plan.toJson());
  }

  static Future<SalaryPlan?> getSalaryPlan(String userId) async {
    final docs = _salaryBox.values.where((doc) => doc['userId'] == userId);
    if (docs.isEmpty) return null;
    return SalaryPlan.fromJson(Map<String, dynamic>.from(docs.first));
  }

  static Future<void> deleteSalaryPlan(String id) async {
    await _salaryBox.delete(id);
  }

  // EMI operations
  static Future<void> saveEMI(EMI emi) async {
    await _emiBox.put(emi.id, emi.toJson());
  }

  static Future<List<EMI>> getEMIs(String userId) async {
    final docs = _emiBox.values.where((doc) => doc['userId'] == userId).toList();
    docs.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
    return docs.map((doc) => EMI.fromJson(Map<String, dynamic>.from(doc))).toList();
  }

  static Future<void> deleteEMI(String id) async {
    await _emiBox.delete(id);
  }

  // Business operations
  static Future<void> saveBusiness(Business business) async {
    await _businessBox.put(business.id, business.toJson());
  }

  static Future<List<Business>> getBusinesses(String userId) async {
    final docs = _businessBox.values.where((doc) => doc['userId'] == userId).toList();
    docs.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
    return docs.map((doc) => Business.fromJson(Map<String, dynamic>.from(doc))).toList();
  }

  static Future<void> deleteBusiness(String id) async {
    await _businessBox.delete(id);
  }

  // Customer operations
  static Future<void> saveCustomer(Customer customer) async {
    await _customerBox.put(customer.id, customer.toJson());
  }

  static Future<List<Customer>> getCustomers(String businessId) async {
    final docs = _customerBox.values.where((doc) => doc['businessId'] == businessId).toList();
    return docs.map((doc) => Customer.fromJson(Map<String, dynamic>.from(doc))).toList();
  }

  static Future<void> deleteCustomer(String id) async {
    await _customerBox.delete(id);
  }

  // Business Transaction operations
  static Future<void> saveTransaction(BusinessTransaction transaction) async {
    await _transactionBox.put(transaction.id, transaction.toJson());
  }

  static Future<List<BusinessTransaction>> getTransactions(String businessId) async {
    final docs = _transactionBox.values.where((doc) => doc['businessId'] == businessId).toList();
    docs.sort((a, b) => b['date'].compareTo(a['date']));
    return docs.map((doc) => BusinessTransaction.fromJson(Map<String, dynamic>.from(doc))).toList();
  }

  static Future<void> deleteTransaction(String id) async {
    await _transactionBox.delete(id);
  }

  // Trip Plan operations
  static Future<void> saveTripPlan(TripPlan trip) async {
    await _tripBox.put(trip.id, trip.toJson());
  }

  static Future<List<TripPlan>> getTripPlans(String userId) async {
    final docs = _tripBox.values.where((doc) => doc['userId'] == userId).toList();
    docs.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
    return docs.map((doc) => TripPlan.fromJson(Map<String, dynamic>.from(doc))).toList();
  }

  static Future<void> deleteTripPlan(String id) async {
    await _tripBox.delete(id);
  }

  // Investment operations
  static Future<void> saveInvestment(Investment investment) async {
    await _investmentBox.put(investment.id, investment.toJson());
  }

  static Future<List<Investment>> getInvestments(String userId) async {
    final docs = _investmentBox.values.where((doc) => doc['userId'] == userId).toList();
    docs.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
    return docs.map((doc) => Investment.fromJson(Map<String, dynamic>.from(doc))).toList();
  }

  static Future<void> deleteInvestment(String id) async {
    await _investmentBox.delete(id);
  }

  // Settings operations
  static Future<dynamic> getSetting(String key, {dynamic defaultValue}) async {
    if (!_isInitialized) return defaultValue;
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  static Future<void> saveSetting(String key, dynamic value) async {
    if (!_isInitialized) return;
    await _settingsBox.put(key, value);
  }

  // Find user by email (for login)
  static Future<User?> findUserByEmail(String email) async {
    final docs = _usersBox.values.where((doc) => doc['email'] == email);
    if (docs.isEmpty) return null;
    return User.fromJson(Map<String, dynamic>.from(docs.first));
  }

  // Clear all data
  static Future<void> clearAllData() async {
    await _usersBox.clear();
    await _expensesBox.clear();
    await _salaryBox.clear();
    await _emiBox.clear();
    await _businessBox.clear();
    await _customerBox.clear();
    await _transactionBox.clear();
    await _tripBox.clear();
    await _investmentBox.clear();
  }

  // Backup data to JSON
  static Future<Map<String, dynamic>> exportData(String userId) async {
    return {
      'user': (await getCurrentUser())?.toJson(),
      'expenses': (await getExpenses(userId)).map((e) => e.toJson()).toList(),
      'categories': (await getCategories()).where((c) => c.isCustom).map((c) => c.toJson()).toList(),
      'salaryPlan': (await getSalaryPlan(userId))?.toJson(),
      'emis': (await getEMIs(userId)).map((e) => e.toJson()).toList(),
      'businesses': (await getBusinesses(userId)).map((b) => b.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }
}
