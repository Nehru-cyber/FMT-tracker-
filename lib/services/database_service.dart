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
  static late Box<User> _userBox;
  static late Box<Expense> _expenseBox;
  static late Box<Category> _categoryBox;
  static late Box<SalaryPlan> _salaryBox;
  static late Box<EMI> _emiBox;
  static late Box<Business> _businessBox;
  static late Box<Customer> _customerBox;
  static late Box<BusinessTransaction> _transactionBox;
  static late Box<TripPlan> _tripBox;
  static late Box<Investment> _investmentBox;
  static late Box _settingsBox;
  
  static Future<void> initialize() async {
    // Register adapters
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(ExpenseTypeAdapter());
    Hive.registerAdapter(ExpenseAdapter());
    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(SalaryPlanAdapter());
    Hive.registerAdapter(EMIAdapter());
    Hive.registerAdapter(BusinessAdapter());
    Hive.registerAdapter(CustomerAdapter());
    Hive.registerAdapter(TransactionTypeAdapter());
    Hive.registerAdapter(BusinessTransactionAdapter());
    Hive.registerAdapter(TripPlanAdapter());
    Hive.registerAdapter(InvestmentAdapter());
    
    // Open boxes
    _userBox = await Hive.openBox<User>(AppConstants.userBox);
    _expenseBox = await Hive.openBox<Expense>(AppConstants.expenseBox);
    _categoryBox = await Hive.openBox<Category>(AppConstants.categoryBox);
    _salaryBox = await Hive.openBox<SalaryPlan>(AppConstants.salaryBox);
    _emiBox = await Hive.openBox<EMI>(AppConstants.emiBox);
    _businessBox = await Hive.openBox<Business>(AppConstants.businessBox);
    _customerBox = await Hive.openBox<Customer>(AppConstants.customerBox);
    _transactionBox = await Hive.openBox<BusinessTransaction>(AppConstants.transactionBox);
    _tripBox = await Hive.openBox<TripPlan>(AppConstants.tripBox);
    _investmentBox = await Hive.openBox<Investment>(AppConstants.investmentBox);
    _settingsBox = await Hive.openBox(AppConstants.settingsBox);
    
    // Initialize default categories if empty
    if (_categoryBox.isEmpty) {
      await _initializeDefaultCategories();
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
      await _categoryBox.put(category.id, category);
    }
  }
  
  // User operations
  static Box<User> get userBox => _userBox;
  
  static Future<void> saveUser(User user) async {
    await _userBox.put(user.id, user);
  }
  
  static User? getUser(String id) {
    return _userBox.get(id);
  }
  
  static User? getCurrentUser() {
    return getLoggedInUser();
  }
  
  static User? getLoggedInUser() {
    final currentUserId = _settingsBox.get('currentUserId');
    if (currentUserId == null) return null;
    return _userBox.get(currentUserId);
  }
  
  static Future<void> deleteUser(String id) async {
    await _userBox.delete(id);
  }
  
  // Expense operations
  static Box<Expense> get expenseBox => _expenseBox;
  
  static Future<void> saveExpense(Expense expense) async {
    await _expenseBox.put(expense.id, expense);
  }
  
  static List<Expense> getExpenses(String userId) {
    return _expenseBox.values
        .where((e) => e.userId == userId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
  
  static List<Expense> getExpensesByDateRange(String userId, DateTime start, DateTime end) {
    return _expenseBox.values
        .where((e) => 
            e.userId == userId &&
            e.date.isAfter(start.subtract(const Duration(days: 1))) &&
            e.date.isBefore(end.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
  
  static List<Expense> getExpensesByMonth(String userId, int year, int month) {
    return _expenseBox.values
        .where((e) => 
            e.userId == userId &&
            e.date.year == year &&
            e.date.month == month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
  
  static Future<void> deleteExpense(String id) async {
    await _expenseBox.delete(id);
  }
  
  // Category operations
  static Box<Category> get categoryBox => _categoryBox;
  
  static List<Category> getCategories({bool? isIncome}) {
    if (isIncome == null) {
      return _categoryBox.values.toList();
    }
    return _categoryBox.values.where((c) => c.isIncome == isIncome).toList();
  }
  
  static Future<void> saveCategory(Category category) async {
    await _categoryBox.put(category.id, category);
  }
  
  static Future<void> deleteCategory(String id) async {
    await _categoryBox.delete(id);
  }
  
  // Salary Plan operations
  static Box<SalaryPlan> get salaryBox => _salaryBox;
  
  static Future<void> saveSalaryPlan(SalaryPlan plan) async {
    await _salaryBox.put(plan.id, plan);
  }
  
  static SalaryPlan? getSalaryPlan(String userId) {
    try {
      return _salaryBox.values.firstWhere((p) => p.userId == userId);
    } catch (_) {
      return null;
    }
  }
  
  static Future<void> deleteSalaryPlan(String id) async {
    await _salaryBox.delete(id);
  }
  
  // EMI operations
  static Box<EMI> get emiBox => _emiBox;
  
  static Future<void> saveEMI(EMI emi) async {
    await _emiBox.put(emi.id, emi);
  }
  
  static List<EMI> getEMIs(String userId) {
    return _emiBox.values
        .where((e) => e.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  
  static Future<void> deleteEMI(String id) async {
    await _emiBox.delete(id);
  }
  
  // Business operations
  static Box<Business> get businessBox => _businessBox;
  
  static Future<void> saveBusiness(Business business) async {
    await _businessBox.put(business.id, business);
  }
  
  static List<Business> getBusinesses(String userId) {
    return _businessBox.values
        .where((b) => b.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  
  static Future<void> deleteBusiness(String id) async {
    await _businessBox.delete(id);
  }
  
  // Customer operations
  static Box<Customer> get customerBox => _customerBox;
  
  static Future<void> saveCustomer(Customer customer) async {
    await _customerBox.put(customer.id, customer);
  }
  
  static List<Customer> getCustomers(String businessId) {
    return _customerBox.values
        .where((c) => c.businessId == businessId)
        .toList();
  }
  
  static Future<void> deleteCustomer(String id) async {
    await _customerBox.delete(id);
  }
  
  // Business Transaction operations
  static Box<BusinessTransaction> get transactionBox => _transactionBox;
  
  static Future<void> saveTransaction(BusinessTransaction transaction) async {
    await _transactionBox.put(transaction.id, transaction);
  }
  
  static List<BusinessTransaction> getTransactions(String businessId) {
    return _transactionBox.values
        .where((t) => t.businessId == businessId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
  
  static Future<void> deleteTransaction(String id) async {
    await _transactionBox.delete(id);
  }
  
  // Trip Plan operations
  static Box<TripPlan> get tripBox => _tripBox;
  
  static Future<void> saveTripPlan(TripPlan trip) async {
    await _tripBox.put(trip.id, trip);
  }
  
  static List<TripPlan> getTripPlans(String userId) {
    return _tripBox.values
        .where((t) => t.userId == userId)
        .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  
  static Future<void> deleteTripPlan(String id) async {
    await _tripBox.delete(id);
  }
  
  // Investment operations
  static Box<Investment> get investmentBox => _investmentBox;
  
  static Future<void> saveInvestment(Investment investment) async {
    await _investmentBox.put(investment.id, investment);
  }
  
  static List<Investment> getInvestments(String userId) {
    return _investmentBox.values
        .where((i) => i.userId == userId)
        .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  
  static Future<void> deleteInvestment(String id) async {
    await _investmentBox.delete(id);
  }
  
  // Settings operations
  static Box get settingsBox => _settingsBox;
  
  static dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }
  
  static Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }
  
  // Clear all data
  static Future<void> clearAllData() async {
    await _userBox.clear();
    await _expenseBox.clear();
    await _salaryBox.clear();
    await _emiBox.clear();
    await _businessBox.clear();
    await _customerBox.clear();
    await _transactionBox.clear();
    await _tripBox.clear();
    await _investmentBox.clear();
  }
  
  // Backup data to JSON
  static Map<String, dynamic> exportData(String userId) {
    return {
      'user': getCurrentUser()?.toJson(),
      'expenses': getExpenses(userId).map((e) => e.toJson()).toList(),
      'categories': getCategories().where((c) => c.isCustom).map((c) => c.toJson()).toList(),
      'salaryPlan': getSalaryPlan(userId)?.toJson(),
      'emis': getEMIs(userId).map((e) => e.toJson()).toList(),
      'businesses': getBusinesses(userId).map((b) => b.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }
}
