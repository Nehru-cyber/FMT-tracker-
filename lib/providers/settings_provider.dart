import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../config/constants.dart';

class SettingsProvider extends ChangeNotifier {
  String _currency = AppConstants.defaultCurrency;
  bool _notificationsEnabled = true;
  
  String get currency => _currency;
  String get currencySymbol => AppConstants.currencies[_currency] ?? '₹';
  bool get notificationsEnabled => _notificationsEnabled;
  
  SettingsProvider() {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    _currency = await DatabaseService.getSetting('currency', defaultValue: 'INR');
    _notificationsEnabled = await DatabaseService.getSetting('notifications', defaultValue: true);
    notifyListeners();
  }
  
  Future<void> setCurrency(String currency) async {
    _currency = currency;
    await DatabaseService.saveSetting('currency', currency);
    notifyListeners();
  }
  
  Future<void> setNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    await DatabaseService.saveSetting('notifications', enabled);
    notifyListeners();
  }
}
