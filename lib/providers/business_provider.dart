import 'package:flutter/material.dart';
import '../models/business.dart';
import '../models/business_transaction.dart';
import '../services/business_service.dart';
import '../services/database_service.dart';

class BusinessProvider extends ChangeNotifier {
  List<Business> _businesses = [];
  Business? _selectedBusiness;
  List<Customer> _customers = [];
  List<BusinessTransaction> _transactions = [];
  bool _isLoading = false;
  
  List<Business> get businesses => _businesses;
  Business? get selectedBusiness => _selectedBusiness;
  List<Customer> get customers => _customers;
  List<BusinessTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  
  Future<Map<String, double>> getProfitLoss() async {
    if (_selectedBusiness == null) return {'income': 0, 'expense': 0, 'profit': 0};
    return await BusinessService.calculateProfitLoss(_selectedBusiness!.id);
  }
  
  Future<void> loadBusinesses(String userId) async {
    _isLoading = true;
    notifyListeners();
    
    _businesses = await BusinessService.getBusinesses(userId);
    if (_businesses.isNotEmpty && _selectedBusiness == null) {
      await selectBusiness(_businesses.first);
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> selectBusiness(Business business) async {
    _selectedBusiness = business;
    _customers = await BusinessService.getCustomers(business.id);
    _transactions = await BusinessService.getTransactions(business.id);
    notifyListeners();
  }
  
  Future<void> createBusiness({
    required String userId,
    required String name,
    required String type,
  }) async {
    final business = await BusinessService.createBusiness(
      userId: userId,
      name: name,
      type: type,
    );
    _businesses.add(business);
    await selectBusiness(business);
  }
  
  Future<void> addTransaction({
    required double amount,
    required TransactionType type,
    required DateTime date,
    String? customerId,
    String note = '',
  }) async {
    if (_selectedBusiness == null) return;
    
    await BusinessService.addTransaction(
      businessId: _selectedBusiness!.id,
      customerId: customerId,
      amount: amount,
      type: type,
      date: date,
      note: note,
    );
    _transactions = await BusinessService.getTransactions(_selectedBusiness!.id);
    notifyListeners();
  }
  
  Future<void> updateTransaction({
    required String id,
    required double amount,
    required TransactionType type,
    required DateTime date,
    String note = '',
  }) async {
    if (_selectedBusiness == null) return;
    final existing = _transactions.firstWhere((t) => t.id == id);
    final updated = existing.copyWith(
      amount: amount,
      type: type,
      date: date,
      note: note,
    );
    await DatabaseService.saveTransaction(updated);
    _transactions = await BusinessService.getTransactions(_selectedBusiness!.id);
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    if (_selectedBusiness == null) return;
    await DatabaseService.deleteTransaction(id);
    _transactions = await BusinessService.getTransactions(_selectedBusiness!.id);
    notifyListeners();
  }

  Future<void> addCustomer({
    required String name,
    required String phone,
  }) async {
    if (_selectedBusiness == null) return;
    
    await BusinessService.addCustomer(
      businessId: _selectedBusiness!.id,
      name: name,
      phone: phone,
    );
    _customers = await BusinessService.getCustomers(_selectedBusiness!.id);
    notifyListeners();
  }

  Future<void> updateCustomer({
    required String id,
    required String name,
    required String phone,
  }) async {
    if (_selectedBusiness == null) return;
    final existing = _customers.firstWhere((c) => c.id == id);
    final updated = existing.copyWith(name: name, phone: phone);
    await DatabaseService.saveCustomer(updated);
    _customers = await BusinessService.getCustomers(_selectedBusiness!.id);
    notifyListeners();
  }

  Future<void> deleteCustomer(String id) async {
    if (_selectedBusiness == null) return;
    await DatabaseService.deleteCustomer(id);
    _customers = await BusinessService.getCustomers(_selectedBusiness!.id);
    notifyListeners();
  }
}
