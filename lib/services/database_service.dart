import 'package:mongo_dart/mongo_dart.dart';
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
  static late Db _db;
  static bool _isInitialized = false;
  
  static bool get isInitialized => _isInitialized;

  static Future<void> initialize() async {
    try {
      _db = await Db.create(AppConstants.mongoUrl);
      // Add a timeout so it doesn't hang indefinitely on unreachable IPs (like 10.0.2.2 on a physical device)
      await _db.open().timeout(const Duration(seconds: 3));

      // Initialize default categories if empty
      final catCol = _db.collection(AppConstants.categoryCollection);
      final count = await catCol.count();
      if (count == 0) {
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
    final col = _db.collection(AppConstants.categoryCollection);
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
      await col.updateOne(
        where.eq('id', category.id),
        {'\$set': category.toJson()},
        upsert: true,
      );
    }
  }

  // User operations
  static Future<void> saveUser(User user) async {
    final col = _db.collection(AppConstants.userCollection);
    await col.updateOne(
      where.eq('id', user.id),
      {'\$set': user.toJson()},
      upsert: true,
    );
  }

  static Future<User?> getUser(String id) async {
    if (!_isInitialized) return null;
    try {
      final col = _db.collection(AppConstants.userCollection);
      final doc = await col.findOne(where.eq('id', id));
      if (doc == null) return null;
      return User.fromJson(doc);
    } catch (e) {
      return null;
    }
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
    final col = _db.collection(AppConstants.userCollection);
    await col.deleteOne(where.eq('id', id));
  }

  // Expense operations
  static Future<void> saveExpense(Expense expense) async {
    final col = _db.collection(AppConstants.expenseCollection);
    await col.updateOne(
      where.eq('id', expense.id),
      {'\$set': expense.toJson()},
      upsert: true,
    );
  }

  static Future<List<Expense>> getExpenses(String userId) async {
    final col = _db.collection(AppConstants.expenseCollection);
    final docs = await col.find(where.eq('userId', userId).sortBy('date', descending: true)).toList();
    return docs.map((doc) => Expense.fromJson(doc)).toList();
  }

  static Future<List<Expense>> getExpensesByDateRange(String userId, DateTime start, DateTime end) async {
    final col = _db.collection(AppConstants.expenseCollection);
    final docs = await col.find(
      where.eq('userId', userId)
        .gte('date', start.subtract(const Duration(days: 1)).toIso8601String())
        .lte('date', end.add(const Duration(days: 1)).toIso8601String())
        .sortBy('date', descending: true),
    ).toList();
    return docs.map((doc) => Expense.fromJson(doc)).toList();
  }

  static Future<List<Expense>> getExpensesByMonth(String userId, int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return await getExpensesByDateRange(userId, start, end);
  }

  static Future<void> deleteExpense(String id) async {
    final col = _db.collection(AppConstants.expenseCollection);
    await col.deleteOne(where.eq('id', id));
  }

  // Category operations
  static Future<List<Category>> getCategories({bool? isIncome}) async {
    final col = _db.collection(AppConstants.categoryCollection);
    SelectorBuilder query;
    if (isIncome != null) {
      query = where.eq('isIncome', isIncome);
    } else {
      query = where;
    }
    final docs = await col.find(query).toList();
    return docs.map((doc) => Category.fromJson(doc)).toList();
  }

  static Future<void> saveCategory(Category category) async {
    final col = _db.collection(AppConstants.categoryCollection);
    await col.updateOne(
      where.eq('id', category.id),
      {'\$set': category.toJson()},
      upsert: true,
    );
  }

  static Future<void> deleteCategory(String id) async {
    final col = _db.collection(AppConstants.categoryCollection);
    await col.deleteOne(where.eq('id', id));
  }

  // Salary Plan operations
  static Future<void> saveSalaryPlan(SalaryPlan plan) async {
    final col = _db.collection(AppConstants.salaryCollection);
    await col.updateOne(
      where.eq('id', plan.id),
      {'\$set': plan.toJson()},
      upsert: true,
    );
  }

  static Future<SalaryPlan?> getSalaryPlan(String userId) async {
    final col = _db.collection(AppConstants.salaryCollection);
    final doc = await col.findOne(where.eq('userId', userId));
    if (doc == null) return null;
    return SalaryPlan.fromJson(doc);
  }

  static Future<void> deleteSalaryPlan(String id) async {
    final col = _db.collection(AppConstants.salaryCollection);
    await col.deleteOne(where.eq('id', id));
  }

  // EMI operations
  static Future<void> saveEMI(EMI emi) async {
    final col = _db.collection(AppConstants.emiCollection);
    await col.updateOne(
      where.eq('id', emi.id),
      {'\$set': emi.toJson()},
      upsert: true,
    );
  }

  static Future<List<EMI>> getEMIs(String userId) async {
    final col = _db.collection(AppConstants.emiCollection);
    final docs = await col.find(where.eq('userId', userId).sortBy('createdAt', descending: true)).toList();
    return docs.map((doc) => EMI.fromJson(doc)).toList();
  }

  static Future<void> deleteEMI(String id) async {
    final col = _db.collection(AppConstants.emiCollection);
    await col.deleteOne(where.eq('id', id));
  }

  // Business operations
  static Future<void> saveBusiness(Business business) async {
    final col = _db.collection(AppConstants.businessCollection);
    await col.updateOne(
      where.eq('id', business.id),
      {'\$set': business.toJson()},
      upsert: true,
    );
  }

  static Future<List<Business>> getBusinesses(String userId) async {
    final col = _db.collection(AppConstants.businessCollection);
    final docs = await col.find(where.eq('userId', userId).sortBy('createdAt', descending: true)).toList();
    return docs.map((doc) => Business.fromJson(doc)).toList();
  }

  static Future<void> deleteBusiness(String id) async {
    final col = _db.collection(AppConstants.businessCollection);
    await col.deleteOne(where.eq('id', id));
  }

  // Customer operations
  static Future<void> saveCustomer(Customer customer) async {
    final col = _db.collection(AppConstants.customerCollection);
    await col.updateOne(
      where.eq('id', customer.id),
      {'\$set': customer.toJson()},
      upsert: true,
    );
  }

  static Future<List<Customer>> getCustomers(String businessId) async {
    final col = _db.collection(AppConstants.customerCollection);
    final docs = await col.find(where.eq('businessId', businessId)).toList();
    return docs.map((doc) => Customer.fromJson(doc)).toList();
  }

  static Future<void> deleteCustomer(String id) async {
    final col = _db.collection(AppConstants.customerCollection);
    await col.deleteOne(where.eq('id', id));
  }

  // Business Transaction operations
  static Future<void> saveTransaction(BusinessTransaction transaction) async {
    final col = _db.collection(AppConstants.transactionCollection);
    await col.updateOne(
      where.eq('id', transaction.id),
      {'\$set': transaction.toJson()},
      upsert: true,
    );
  }

  static Future<List<BusinessTransaction>> getTransactions(String businessId) async {
    final col = _db.collection(AppConstants.transactionCollection);
    final docs = await col.find(where.eq('businessId', businessId).sortBy('date', descending: true)).toList();
    return docs.map((doc) => BusinessTransaction.fromJson(doc)).toList();
  }

  static Future<void> deleteTransaction(String id) async {
    final col = _db.collection(AppConstants.transactionCollection);
    await col.deleteOne(where.eq('id', id));
  }

  // Trip Plan operations
  static Future<void> saveTripPlan(TripPlan trip) async {
    final col = _db.collection(AppConstants.tripCollection);
    await col.updateOne(
      where.eq('id', trip.id),
      {'\$set': trip.toJson()},
      upsert: true,
    );
  }

  static Future<List<TripPlan>> getTripPlans(String userId) async {
    final col = _db.collection(AppConstants.tripCollection);
    final docs = await col.find(where.eq('userId', userId).sortBy('createdAt', descending: true)).toList();
    return docs.map((doc) => TripPlan.fromJson(doc)).toList();
  }

  static Future<void> deleteTripPlan(String id) async {
    final col = _db.collection(AppConstants.tripCollection);
    await col.deleteOne(where.eq('id', id));
  }

  // Investment operations
  static Future<void> saveInvestment(Investment investment) async {
    final col = _db.collection(AppConstants.investmentCollection);
    await col.updateOne(
      where.eq('id', investment.id),
      {'\$set': investment.toJson()},
      upsert: true,
    );
  }

  static Future<List<Investment>> getInvestments(String userId) async {
    final col = _db.collection(AppConstants.investmentCollection);
    final docs = await col.find(where.eq('userId', userId).sortBy('createdAt', descending: true)).toList();
    return docs.map((doc) => Investment.fromJson(doc)).toList();
  }

  static Future<void> deleteInvestment(String id) async {
    final col = _db.collection(AppConstants.investmentCollection);
    await col.deleteOne(where.eq('id', id));
  }

  // Settings operations
  static Future<dynamic> getSetting(String key, {dynamic defaultValue}) async {
    if (!_isInitialized) return defaultValue;
    try {
      final col = _db.collection(AppConstants.settingsCollection);
      final doc = await col.findOne(where.eq('key', key));
      if (doc == null) return defaultValue;
      return doc['value'] ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  static Future<void> saveSetting(String key, dynamic value) async {
    if (!_isInitialized) return;
    try {
      final col = _db.collection(AppConstants.settingsCollection);
      await col.updateOne(
        where.eq('key', key),
        {'\$set': {'key': key, 'value': value}},
        upsert: true,
      );
    } catch (e) {
      debugPrint('Error saving setting: $e');
    }
  }

  // Find user by email (for login)
  static Future<User?> findUserByEmail(String email) async {
    final col = _db.collection(AppConstants.userCollection);
    final doc = await col.findOne(where.eq('email', email));
    if (doc == null) return null;
    return User.fromJson(doc);
  }

  // Clear all data
  static Future<void> clearAllData() async {
    await _db.collection(AppConstants.userCollection).drop();
    await _db.collection(AppConstants.expenseCollection).drop();
    await _db.collection(AppConstants.salaryCollection).drop();
    await _db.collection(AppConstants.emiCollection).drop();
    await _db.collection(AppConstants.businessCollection).drop();
    await _db.collection(AppConstants.customerCollection).drop();
    await _db.collection(AppConstants.transactionCollection).drop();
    await _db.collection(AppConstants.tripCollection).drop();
    await _db.collection(AppConstants.investmentCollection).drop();
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
