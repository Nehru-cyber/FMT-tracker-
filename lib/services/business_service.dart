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
    final transactions = DatabaseService.getTransactions(id);
    for (final t in transactions) {
      await DatabaseService.deleteTransaction(t.id);
    }
    final customers = DatabaseService.getCustomers(id);
    for (final c in customers) {
      await DatabaseService.deleteCustomer(c.id);
    }
    await DatabaseService.deleteBusiness(id);
  }
  
  static List<Business> getBusinesses(String userId) {
    return DatabaseService.getBusinesses(userId);
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
  
  static List<Customer> getCustomers(String businessId) {
    return DatabaseService.getCustomers(businessId);
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
  
  static List<BusinessTransaction> getTransactions(String businessId) {
    return DatabaseService.getTransactions(businessId);
  }
  
  static Map<String, double> calculateProfitLoss(String businessId) {
    final transactions = getTransactions(businessId);
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
  
  static Map<String, dynamic> getBusinessSummary(String businessId) {
    final business = DatabaseService.businessBox.get(businessId);
    if (business == null) return {'exists': false};
    
    final transactions = getTransactions(businessId);
    final customers = getCustomers(businessId);
    final profitLoss = calculateProfitLoss(businessId);
    
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
