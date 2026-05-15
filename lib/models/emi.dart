import 'package:hive/hive.dart';

part 'emi.g.dart';

class AmortizationEntry {
  int month;
  double emi;
  double principal;
  double interest;
  double balance;
  
  AmortizationEntry({
    required this.month,
    required this.emi,
    required this.principal,
    required this.interest,
    required this.balance,
  });
}

@HiveType(typeId: 7)
class EMI extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String userId;
  
  @HiveField(2)
  String name;
  
  @HiveField(3)
  double loanAmount;
  
  @HiveField(4)
  double interestRate;
  
  @HiveField(5)
  int tenureMonths;
  
  @HiveField(6)
  double monthlyEMI;
  
  @HiveField(7)
  double totalInterest;
  
  @HiveField(8)
  double totalPayable;
  
  @HiveField(9)
  DateTime createdAt;
  
  @HiveField(10)
  DateTime? startDate;
  
  @HiveField(11)
  int paymentDay; // Day of month when EMI is due (1-28)
  
  @HiveField(12)
  int reminderDaysBefore; // Days before due date to remind
  
  @HiveField(13)
  bool isReminderEnabled;
  
  @HiveField(14)
  bool isEdited;
  
  EMI({
    required this.id,
    required this.userId,
    required this.name,
    required this.loanAmount,
    required this.interestRate,
    required this.tenureMonths,
    required this.monthlyEMI,
    required this.totalInterest,
    required this.totalPayable,
    DateTime? createdAt,
    this.startDate,
    this.paymentDay = 5,
    this.reminderDaysBefore = 2,
    this.isReminderEnabled = true,
    this.isEdited = false,
  }) : createdAt = createdAt ?? DateTime.now();
  
  List<AmortizationEntry> get schedule {
    final entries = <AmortizationEntry>[];
    final monthlyRate = interestRate / 12 / 100;
    double balance = loanAmount;
    
    for (int i = 1; i <= tenureMonths; i++) {
      final interest = balance * monthlyRate;
      final principal = monthlyEMI - interest;
      balance = balance - principal;
      
      entries.add(AmortizationEntry(
        month: i,
        emi: monthlyEMI,
        principal: principal,
        interest: interest,
        balance: balance > 0 ? balance : 0,
      ));
    }
    return entries;
  }
  
  // Calculate EMI using the formula: EMI = P * r * (1+r)^n / ((1+r)^n - 1)
  static EMI calculate({
    required String id,
    required String userId,
    required String name,
    required double loanAmount,
    required double interestRate,
    required int tenureMonths,
    DateTime? startDate,
    int paymentDay = 5,
    int reminderDaysBefore = 2,
    bool isReminderEnabled = true,
  }) {
    final monthlyRate = interestRate / 12 / 100;
    final factor = (1 + monthlyRate);
    final factorPow = _pow(factor, tenureMonths);
    
    double monthlyEMI;
    if (monthlyRate == 0) {
      monthlyEMI = loanAmount / tenureMonths;
    } else {
      monthlyEMI = loanAmount * monthlyRate * factorPow / (factorPow - 1);
    }
    
    final totalPayable = monthlyEMI * tenureMonths;
    final totalInterest = totalPayable - loanAmount;
    
    return EMI(
      id: id,
      userId: userId,
      name: name,
      loanAmount: loanAmount,
      interestRate: interestRate,
      tenureMonths: tenureMonths,
      monthlyEMI: monthlyEMI,
      totalInterest: totalInterest,
      totalPayable: totalPayable,
      startDate: startDate,
      paymentDay: paymentDay,
      reminderDaysBefore: reminderDaysBefore,
      isReminderEnabled: isReminderEnabled,
    );
  }
  
  // Get next payment date
  DateTime get nextPaymentDate {
    final now = DateTime.now();
    var nextDate = DateTime(now.year, now.month, paymentDay);
    if (nextDate.isBefore(now) || nextDate.day == now.day) {
      nextDate = DateTime(now.year, now.month + 1, paymentDay);
    }
    return nextDate;
  }
  
  // Get days until next payment
  int get daysUntilPayment {
    return nextPaymentDate.difference(DateTime.now()).inDays;
  }
  
  static double _pow(double base, int exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'loanAmount': loanAmount,
      'interestRate': interestRate,
      'tenureMonths': tenureMonths,
      'monthlyEMI': monthlyEMI,
      'totalInterest': totalInterest,
      'totalPayable': totalPayable,
      'createdAt': createdAt.toIso8601String(),
      'paymentDay': paymentDay,
      'reminderDaysBefore': reminderDaysBefore,
      'isReminderEnabled': isReminderEnabled,
      'isEdited': isEdited,
    };
  }

  factory EMI.fromJson(Map<String, dynamic> json) {
    return EMI(
      id: json['id'],
      userId: json['userId'],
      name: json['name'] ?? '',
      loanAmount: (json['loanAmount'] as num).toDouble(),
      interestRate: (json['interestRate'] as num).toDouble(),
      tenureMonths: json['tenureMonths'],
      monthlyEMI: (json['monthlyEMI'] as num).toDouble(),
      totalInterest: (json['totalInterest'] as num).toDouble(),
      totalPayable: (json['totalPayable'] as num).toDouble(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      paymentDay: json['paymentDay'] ?? 5,
      reminderDaysBefore: json['reminderDaysBefore'] ?? 2,
      isReminderEnabled: json['isReminderEnabled'] ?? true,
      isEdited: json['isEdited'] ?? false,
    );
  }
}
