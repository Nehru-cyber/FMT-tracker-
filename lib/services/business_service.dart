import 'package:uuid/uuid.dart';
import '../models/business.dart';
import '../models/business_transaction.dart';
import 'database_service.dart';

class BusinessService {
  static const _uuid = Uuid();
  
  static Future<Business> createBusiness({
    required String userId,
    required String name,
    required String type,
    String? description,
  }) async {
    final business = Business(
      id: _uuid.v4(),
      userId: userId,
      name: name,
      type: type,
      description: description,
    );
    await DatabaseService.saveBusiness(business);
    return business;
  }
  
  static Future<void> deleteBusiness(String id) async {
    final transactions = await DatabaseService.getTransactions(id);
    for (final t in transactions) {
      await DatabaseService.deleteTransaction(t.id);
    }
    final customers = await DatabaseService.getCustomers(id);
    for (final c in customers) {
      await DatabaseService.deleteCustomer(c.id);
    }
    await DatabaseService.deleteBusiness(id);
  }
  
  static Future<List<Business>> getBusinesses(String userId) async {
    return await DatabaseService.getBusinesses(userId);
  }
  
  static Future<Customer> addCustomer({
    required String businessId,
    required String name,
    required String phone,
    String? email,
    String? address,
  }) async {
    final customer = Customer(
      id: _uuid.v4(),
      businessId: businessId,
      name: name,
      phone: phone,
      email: email,
      address: address,
    );
    await DatabaseService.saveCustomer(customer);
    return customer;
  }
  
  static Future<List<Customer>> getCustomers(String businessId) async {
    return await DatabaseService.getCustomers(businessId);
  }
  
  static Future<BusinessTransaction> addTransaction({
    required String businessId,
    String? customerId,
    required double amount,
    required TransactionType type,
    required DateTime date,
    String note = '',
  }) async {
    final transaction = BusinessTransaction(
      id: _uuid.v4(),
      businessId: businessId,
      customerId: customerId,
      amount: amount,
      type: type,
      date: date,
      note: note,
    );
    await DatabaseService.saveTransaction(transaction);
    return transaction;
  }
  
  static Future<List<BusinessTransaction>> getTransactions(String businessId) async {
    return await DatabaseService.getTransactions(businessId);
  }
  
  static Future<Map<String, double>> calculateProfitLoss(String businessId) async {
    final transactions = await getTransactions(businessId);
    double totalIncome = 0;
    double totalExpense = 0;
    for (final t in transactions) {
      if (t.type == TransactionType.income) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }
    return {
      'income': totalIncome,
      'expense': totalExpense,
      'profit': totalIncome - totalExpense,
    };
  }
  
  static Future<Map<String, dynamic>> getBusinessSummary(String businessId, String userId) async {
    final businesses = await getBusinesses(userId);
    final business = businesses.where((b) => b.id == businessId).firstOrNull;
    if (business == null) return {'exists': false};
    
    final transactions = await getTransactions(businessId);
    final customers = await getCustomers(businessId);
    final profitLoss = await calculateProfitLoss(businessId);
    
    return {
      'exists': true,
      'business': business,
      'totalTransactions': transactions.length,
      'totalCustomers': customers.length,
      'totalIncome': profitLoss['income'],
      'totalExpense': profitLoss['expense'],
      'totalProfit': profitLoss['profit'],
    };
  }
}
