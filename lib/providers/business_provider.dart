import 'package:flutter/material.dart';
import '../models/business.dart';
import '../models/business_transaction.dart';
import '../services/business_service.dart';

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
  
  Map<String, double> get profitLoss {
    if (_selectedBusiness == null) return {'income': 0, 'expense': 0, 'profit': 0};
    return BusinessService.calculateProfitLoss(_selectedBusiness!.id);
  }
  
  void loadBusinesses(String userId) {
    _isLoading = true;
    notifyListeners();
    
    _businesses = BusinessService.getBusinesses(userId);
    if (_businesses.isNotEmpty && _selectedBusiness == null) {
      selectBusiness(_businesses.first);
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  void selectBusiness(Business business) {
    _selectedBusiness = business;
    _customers = BusinessService.getCustomers(business.id);
    _transactions = BusinessService.getTransactions(business.id);
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
    selectBusiness(business);
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
    _transactions = BusinessService.getTransactions(_selectedBusiness!.id);
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
    _customers = BusinessService.getCustomers(_selectedBusiness!.id);
    notifyListeners();
  }
}
