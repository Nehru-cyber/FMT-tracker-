import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../config/constants.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../models/quick_action.dart';

class SettingsProvider extends ChangeNotifier {
  String _currency = AppConstants.defaultCurrency;
  bool _notificationsEnabled = true;
  List<String> _activeQuickActions = ['add_expense', 'wishlist', 'salary_planner'];

  String get currency => _currency;
  String get currencySymbol => AppConstants.currencies[_currency] ?? '₹';
  bool get notificationsEnabled => _notificationsEnabled;
  List<String> get activeQuickActionIds => _activeQuickActions;

  final List<QuickActionModel> allQuickActions = [
    QuickActionModel(id: 'add_expense', title: 'Add Expense', icon: Icons.add_circle, route: AppRoutes.addExpense, color: AppTheme.errorColor),
    QuickActionModel(id: 'wishlist', title: 'Wishes', icon: Icons.star, route: AppRoutes.wishlist, color: Colors.amber),
    QuickActionModel(id: 'salary_planner', title: 'Salary Plan', icon: Icons.savings, route: AppRoutes.salaryPlanner, color: AppTheme.secondaryColor),
    QuickActionModel(id: 'trip_planner', title: 'Trip Planner', icon: Icons.flight_takeoff, route: AppRoutes.tripPlanner, color: Colors.deepOrange),
    QuickActionModel(id: 'investments', title: 'Investments', icon: Icons.trending_up, route: AppRoutes.investments, color: Colors.green),
    QuickActionModel(id: 'gym_tracker', title: 'Gym Tracker', icon: Icons.fitness_center, route: AppRoutes.gymTracker, color: Colors.deepPurple),
    QuickActionModel(id: 'diet_tracker', title: 'Diet Tracker', icon: Icons.restaurant_menu, route: AppRoutes.dietTracker, color: Colors.teal),
    QuickActionModel(id: 'clock', title: 'Clock', icon: Icons.access_time, route: AppRoutes.clock, color: Colors.orange),
    QuickActionModel(id: 'business', title: 'Business', icon: Icons.store, route: AppRoutes.business, color: AppTheme.primaryColor),
    QuickActionModel(id: 'analytics', title: 'Analytics', icon: Icons.analytics, route: AppRoutes.analytics, color: Colors.purple),
    QuickActionModel(id: 'export', title: 'Export', icon: Icons.file_download, route: AppRoutes.export, color: Colors.teal.shade700),
  ];

  List<QuickActionModel> get activeQuickActions {
    return _activeQuickActions
        .map((id) => allQuickActions.firstWhere((a) => a.id == id))
        .toList();
  }

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _currency = await DatabaseService.getSetting('currency', defaultValue: 'INR');
    _notificationsEnabled = await DatabaseService.getSetting('notifications', defaultValue: true);
    final savedActions = await DatabaseService.getSetting('quickActions');
    if (savedActions != null) {
      _activeQuickActions = List<String>.from(savedActions);
    }
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

  Future<void> toggleQuickAction(String id) async {
    if (_activeQuickActions.contains(id)) {
      if (_activeQuickActions.length > 1) {
        _activeQuickActions.remove(id);
      }
    } else {
      if (_activeQuickActions.length < 3) {
        _activeQuickActions.add(id);
      }
    }
    await DatabaseService.saveSetting('quickActions', _activeQuickActions);
    notifyListeners();
  }

  Future<void> updateQuickActions(List<String> actionIds) async {
    _activeQuickActions = actionIds;
    await DatabaseService.saveSetting('quickActions', _activeQuickActions);
    notifyListeners();
  }
}
