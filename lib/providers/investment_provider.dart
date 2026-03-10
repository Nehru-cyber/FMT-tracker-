import 'package:flutter/material.dart';
import '../models/investment.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'package:uuid/uuid.dart';

class InvestmentProvider extends ChangeNotifier {
  List<Investment> _investments = [];
  bool _isLoading = false;
  String? _error;

  List<Investment> get investments => _investments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void loadInvestments(String userId) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _investments = DatabaseService.getInvestments(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addInvestment({
    required String userId,
    required String name,
    required double amount,
    required int investDay,
    required String type,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final investment = Investment(
        id: const Uuid().v4(),
        userId: userId,
        name: name,
        amount: amount,
        investDay: investDay,
        type: type,
      );

      await DatabaseService.saveInvestment(investment);
      _investments.insert(0, investment);

      // Schedule reminder
      await NotificationService.scheduleInvestmentReminder(
        id: investment.id,
        name: investment.name,
        amount: investment.amount,
        investDay: investment.investDay,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteInvestment(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await DatabaseService.deleteInvestment(id);
      _investments.removeWhere((i) => i.id == id);
      
      // Cancel reminder
      await NotificationService.cancelInvestmentReminder(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
