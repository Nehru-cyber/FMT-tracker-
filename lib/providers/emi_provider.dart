import 'package:flutter/material.dart';
import '../models/emi.dart';
import '../services/emi_service.dart';

class EMIProvider extends ChangeNotifier {
  List<EMI> _emis = [];
  EMI? _previewEMI;
  bool _isLoading = false;
  
  List<EMI> get emis => _emis;
  EMI? get previewEMI => _previewEMI;
  bool get isLoading => _isLoading;
  double get totalMonthlyEMI => _emis.fold(0, (sum, e) => sum + e.monthlyEMI);
  
  void loadEMIs(String userId) {
    _isLoading = true;
    notifyListeners();
    
    _emis = EMIService.getEMIs(userId);
    
    _isLoading = false;
    notifyListeners();
  }
  
  void calculatePreview({
    required double loanAmount,
    required double interestRate,
    required int tenureMonths,
  }) {
    _previewEMI = EMIService.calculateEMIPreview(
      loanAmount: loanAmount,
      interestRate: interestRate,
      tenureMonths: tenureMonths,
    );
    notifyListeners();
  }
  
  Future<void> saveEMI({
    required String userId,
    required String name,
    required double loanAmount,
    required double interestRate,
    required int tenureMonths,
    int paymentDay = 5,
    int reminderDaysBefore = 2,
    bool isReminderEnabled = true,
  }) async {
    await EMIService.calculateAndSaveEMI(
      userId: userId,
      name: name,
      loanAmount: loanAmount,
      interestRate: interestRate,
      tenureMonths: tenureMonths,
      paymentDay: paymentDay,
      reminderDaysBefore: reminderDaysBefore,
      isReminderEnabled: isReminderEnabled,
    );
    loadEMIs(userId);
  }
  
  Future<void> deleteEMI(String id, String userId) async {
    await EMIService.deleteEMI(id);
    loadEMIs(userId);
  }
  
  void clearPreview() {
    _previewEMI = null;
    notifyListeners();
  }
}
