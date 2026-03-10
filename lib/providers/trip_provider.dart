import 'package:flutter/material.dart';
import '../models/trip_plan.dart';
import '../services/database_service.dart';
import 'package:uuid/uuid.dart';

class TripProvider extends ChangeNotifier {
  List<TripPlan> _tripPlans = [];
  bool _isLoading = false;
  String? _error;

  List<TripPlan> get tripPlans => _tripPlans;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void loadTripPlans(String userId) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tripPlans = DatabaseService.getTripPlans(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTripPlan(String userId, String name, double cost, String dietPlan, List<String> friends, DateTime date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final trip = TripPlan(
        id: const Uuid().v4(),
        userId: userId,
        name: name,
        cost: cost,
        dietPlan: dietPlan,
        friends: friends,
        date: date,
      );

      await DatabaseService.saveTripPlan(trip);
      _tripPlans.insert(0, trip);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTripPlan(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await DatabaseService.deleteTripPlan(id);
      _tripPlans.removeWhere((t) => t.id == id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
