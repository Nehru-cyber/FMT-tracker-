import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/expense_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    final currencyFormat = NumberFormat.currency(symbol: settings.currencySymbol, decimalDigits: 0);

    final userId = auth.user?.id ?? '';
    final monthlyData = ExpenseService.getMonthlyBreakdown(userId, _selectedYear);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          DropdownButton<int>(
            value: _selectedYear,
            underline: const SizedBox(),
            items: List.generate(5, (i) => DateTime.now().year - i)
                .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                .toList(),
            onChanged: (y) => setState(() => _selectedYear = y!),
          ),
        ],
      ),
      body: FutureBuilder<Map<int, Map<String, double>>>(
        future: ExpenseService.getMonthlyBreakdown(userId, _selectedYear),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final monthlyData = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Year Summary
              Text('Income vs Expense', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxValue(monthlyData) * 1.2,
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                            return Text(months[value.toInt()], style: const TextStyle(fontSize: 10));
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(12, (i) {
                      final data = monthlyData[i + 1] ?? {'income': 0.0, 'expense': 0.0};
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: data['income'] ?? 0,
                            color: AppTheme.secondaryColor,
                            width: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          BarChartRodData(
                            toY: data['expense'] ?? 0,
                            color: AppTheme.errorColor,
                            width: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegend('Income', AppTheme.secondaryColor),
                  const SizedBox(width: 24),
                  _buildLegend('Expense', AppTheme.errorColor),
                ],
              ),
              const SizedBox(height: 32),
              // Category Breakdown
              Text('Spending by Category', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Consumer<ExpenseProvider>(
                builder: (context, expense, _) {
                  final breakdown = expense.getCategoryBreakdown(type: ExpenseType.expense);
                  if (breakdown.isEmpty) {
                    return const Center(child: Text('No expense data'));
                  }
                  final sorted = breakdown.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
                  final total = breakdown.values.fold(0.0, (sum, v) => sum + v);

                  return Column(
                    children: sorted.take(6).map((entry) {
                      final percentage = (entry.value / total * 100);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                                Text(currencyFormat.format(entry.value)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation(_getCategoryColor(entry.key)),
                            ),
                            Text('${percentage.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 32),
              // Monthly Totals
              Text('Monthly Summary', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ...monthlyData.entries.where((e) => e.value['income']! > 0 || e.value['expense']! > 0).map((entry) {
                final monthName = DateFormat('MMMM').format(DateTime(_selectedYear, entry.key));
                final income = entry.value['income'] ?? 0.0;
                final expense = entry.value['expense'] ?? 0.0;
                final balance = income - expense;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(monthName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Income: ${currencyFormat.format(income)} • Expense: ${currencyFormat.format(expense)}'),
                    trailing: Text(
                      currencyFormat.format(balance),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: balance >= 0 ? AppTheme.secondaryColor : AppTheme.errorColor,
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  double _getMaxValue(Map<int, Map<String, double>> data) {
    double max = 0;
    for (final entry in data.values) {
      final income = entry['income'] ?? 0;
      final expense = entry['expense'] ?? 0;
      if (income > max) max = income;
      if (expense > max) max = expense;
    }
    return max > 0 ? max : 10000;
  }

  Color _getCategoryColor(String category) {
    return AppTheme.categoryColors[category] ?? AppTheme.primaryColor;
  }
}
