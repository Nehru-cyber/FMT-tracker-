import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/routes.dart';
import '../../providers/emi_provider.dart';
import '../../providers/salary_provider.dart';
import '../../providers/settings_provider.dart';
import 'alert_card.dart';

class AlertsSection extends StatelessWidget {
  const AlertsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final emiProvider = context.watch<EMIProvider>();
    final salaryProvider = context.watch<SalaryProvider>();
    final settings = context.watch<SettingsProvider>();
    final currencyFormat = NumberFormat.currency(symbol: settings.currencySymbol, decimalDigits: 0);
    
    final alerts = <Widget>[];
    
    // EMI alerts - show EMIs due within 7 days
    for (final emi in emiProvider.emis) {
      if (emi.daysUntilPayment <= 7) {
        alerts.add(AlertCard(
          type: AlertType.emiDue,
          title: emi.name,
          subtitle: currencyFormat.format(emi.monthlyEMI),
          daysRemaining: emi.daysUntilPayment,
          onTap: () => Navigator.pushNamed(context, AppRoutes.emiCalculator),
        ));
      }
    }
    
    // Income day alert - show if within 5 days
    if (salaryProvider.hasPlan) {
      final plan = salaryProvider.salaryPlan!;
      if (plan.daysUntilIncome <= 5) {
        alerts.add(AlertCard(
          type: AlertType.incomeSoon,
          title: 'Salary Day',
          subtitle: currencyFormat.format(plan.monthlySalary),
          daysRemaining: plan.daysUntilIncome,
          onTap: () => Navigator.pushNamed(context, AppRoutes.salaryPlanner),
        ));
      }
      
      // Low balance warning
      if (salaryProvider.remainingBalance < plan.monthlySalary * 0.1) {
        alerts.add(AlertCard(
          type: AlertType.lowBalance,
          title: 'Low Balance',
          subtitle: 'Only ${currencyFormat.format(salaryProvider.remainingBalance)} left',
          onTap: () => Navigator.pushNamed(context, AppRoutes.salaryPlanner),
        ));
      }
      
      // Overspending warning
      if (salaryProvider.isOverspending) {
        alerts.add(AlertCard(
          type: AlertType.overspending,
          title: 'Overspending!',
          subtitle: 'You\'ve exceeded your budget',
          onTap: () => Navigator.pushNamed(context, AppRoutes.analytics),
        ));
      }
    }
    
    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.notifications_active, size: 20, color: Colors.orange),
              const SizedBox(width: 8),
              Text('Upcoming Alerts', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: alerts,
          ),
        ),
      ],
    );
  }
}
