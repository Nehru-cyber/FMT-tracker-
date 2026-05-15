import 'package:flutter/material.dart';
import '../models/wish.dart';
import '../services/database_service.dart';
import 'package:uuid/uuid.dart';

class WishProvider extends ChangeNotifier {
  List<Wish> _wishes = [];
  bool _isLoading = false;

  List<Wish> get wishes => _wishes;
  bool get isLoading => _isLoading;

  Future<void> loadWishes(String userId) async {
    _isLoading = true;
    notifyListeners();
    _wishes = await DatabaseService.getWishes(userId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addWish(String userId, String title, double targetAmount, {String? imageUrl}) async {
    final wish = Wish(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      targetAmount: targetAmount,
      imageUrl: imageUrl,
    );
    await DatabaseService.saveWish(wish);
    _wishes.insert(0, wish);
    notifyListeners();
  }

  Future<void> updateWishAmount(String wishId, double amount) async {
    final idx = _wishes.indexWhere((w) => w.id == wishId);
    if (idx != -1) {
      final updated = _wishes[idx].copyWith(
        savedAmount: _wishes[idx].savedAmount + amount,
      );
      if (updated.savedAmount >= updated.targetAmount) {
        updated.isCompleted = true;
      }
      await DatabaseService.saveWish(updated);
      _wishes[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> deleteWish(String wishId) async {
    await DatabaseService.deleteWish(wishId);
    _wishes.removeWhere((w) => w.id == wishId);
    notifyListeners();
  }
}
