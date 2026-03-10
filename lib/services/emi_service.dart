import 'package:uuid/uuid.dart';
import '../models/emi.dart';
import 'database_service.dart';
import 'notification_service.dart';

class EMIService {
  static const _uuid = Uuid();
  
  // Calculate and save EMI
  static Future<EMI> calculateAndSaveEMI({
    required String userId,
    required String name,
    required double loanAmount,
    required double interestRate,
    required int tenureMonths,
    DateTime? startDate,
    int paymentDay = 5,
    int reminderDaysBefore = 2,
    bool isReminderEnabled = true,
  }) async {
    final emi = EMI.calculate(
      id: _uuid.v4(),
      userId: userId,
      name: name,
      loanAmount: loanAmount,
      interestRate: interestRate,
      tenureMonths: tenureMonths,
      startDate: startDate,
      paymentDay: paymentDay,
      reminderDaysBefore: reminderDaysBefore,
      isReminderEnabled: isReminderEnabled,
    );
    
    await DatabaseService.saveEMI(emi);
    
    // Schedule notification if enabled
    if (isReminderEnabled) {
      await NotificationService.scheduleEMIReminder(
        emiId: emi.id,
        emiName: name,
        amount: emi.monthlyEMI,
        paymentDay: paymentDay,
        reminderDaysBefore: reminderDaysBefore,
      );
    }
    
    return emi;
  }
  
  // Calculate EMI without saving (for preview)
  static EMI calculateEMIPreview({
    required double loanAmount,
    required double interestRate,
    required int tenureMonths,
  }) {
    return EMI.calculate(
      id: 'preview',
      userId: '',
      name: 'Preview',
      loanAmount: loanAmount,
      interestRate: interestRate,
      tenureMonths: tenureMonths,
    );
  }
  
  // Get all EMIs for user
  static List<EMI> getEMIs(String userId) {
    return DatabaseService.getEMIs(userId);
  }
  
  // Get EMI by ID
  static EMI? getEMI(String id) {
    return DatabaseService.emiBox.get(id);
  }
  
  // Delete EMI
  static Future<void> deleteEMI(String id) async {
    await DatabaseService.deleteEMI(id);
  }
  
  // Get total monthly EMI burden
  static double getTotalMonthlyEMI(String userId) {
    final emis = getEMIs(userId);
    return emis.fold(0.0, (sum, emi) => sum + emi.monthlyEMI);
  }
  
  // Get upcoming EMI payments
  static List<Map<String, dynamic>> getUpcomingPayments(String userId) {
    final emis = getEMIs(userId);
    final now = DateTime.now();
    final payments = <Map<String, dynamic>>[];
    
    for (final emi in emis) {
      if (emi.startDate == null) continue;
      
      // Calculate next payment date
      final startDate = emi.startDate!;
      var nextPaymentDate = DateTime(startDate.year, startDate.month + 1, startDate.day);
      
      while (nextPaymentDate.isBefore(now)) {
        nextPaymentDate = DateTime(nextPaymentDate.year, nextPaymentDate.month + 1, nextPaymentDate.day);
      }
      
      // Check if EMI is still active
      final endDate = DateTime(startDate.year, startDate.month + emi.tenureMonths, startDate.day);
      if (nextPaymentDate.isBefore(endDate)) {
        payments.add({
          'emi': emi,
          'dueDate': nextPaymentDate,
          'amount': emi.monthlyEMI,
          'daysUntil': nextPaymentDate.difference(now).inDays,
        });
      }
    }
    
    payments.sort((a, b) => (a['dueDate'] as DateTime).compareTo(b['dueDate'] as DateTime));
    return payments;
  }
  
  // Calculate EMI affordability
  static Map<String, dynamic> calculateAffordability({
    required double monthlyIncome,
    required double existingEMIs,
    required double newEMI,
  }) {
    final totalEMI = existingEMIs + newEMI;
    final emiToIncomeRatio = totalEMI / monthlyIncome * 100;
    
    String status;
    String advice;
    
    if (emiToIncomeRatio <= 30) {
      status = 'excellent';
      advice = 'Your EMI burden is well within healthy limits.';
    } else if (emiToIncomeRatio <= 40) {
      status = 'good';
      advice = 'Your EMI burden is manageable but consider this carefully.';
    } else if (emiToIncomeRatio <= 50) {
      status = 'warning';
      advice = 'Your EMI burden is getting high. Be cautious with additional loans.';
    } else {
      status = 'danger';
      advice = 'Your EMI burden is too high. This loan is not advisable.';
    }
    
    return {
      'totalEMI': totalEMI,
      'emiToIncomeRatio': emiToIncomeRatio,
      'status': status,
      'advice': advice,
      'remainingIncome': monthlyIncome - totalEMI,
    };
  }
  
  // Compare loan options
  static List<Map<String, dynamic>> compareLoanOptions({
    required double loanAmount,
    required List<Map<String, dynamic>> options,
  }) {
    final comparisons = <Map<String, dynamic>>[];
    
    for (final option in options) {
      final emi = calculateEMIPreview(
        loanAmount: loanAmount,
        interestRate: option['interestRate'],
        tenureMonths: option['tenureMonths'],
      );
      
      comparisons.add({
        'name': option['name'],
        'interestRate': option['interestRate'],
        'tenureMonths': option['tenureMonths'],
        'monthlyEMI': emi.monthlyEMI,
        'totalInterest': emi.totalInterest,
        'totalPayable': emi.totalPayable,
      });
    }
    
    return comparisons;
  }
  
  // Get EMI summary
  static Map<String, dynamic> getEMISummary(String userId) {
    final emis = getEMIs(userId);
    
    if (emis.isEmpty) {
      return {
        'hasEMIs': false,
        'count': 0,
        'totalMonthlyEMI': 0.0,
        'totalOutstanding': 0.0,
        'totalInterest': 0.0,
      };
    }
    
    double totalMonthlyEMI = 0;
    double totalOutstanding = 0;
    double totalInterest = 0;
    
    for (final emi in emis) {
      totalMonthlyEMI += emi.monthlyEMI;
      totalOutstanding += emi.totalPayable;
      totalInterest += emi.totalInterest;
    }
    
    return {
      'hasEMIs': true,
      'count': emis.length,
      'totalMonthlyEMI': totalMonthlyEMI,
      'totalOutstanding': totalOutstanding,
      'totalInterest': totalInterest,
      'emis': emis,
    };
  }
}
