import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/salary_plan.dart';
import '../../providers/salary_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

class SalaryPlannerScreen extends StatefulWidget {
  const SalaryPlannerScreen({super.key});

  @override
  State<SalaryPlannerScreen> createState() => _SalaryPlannerScreenState();
}

class _SalaryPlannerScreenState extends State<SalaryPlannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _salaryController = TextEditingController();
  final _savingsController = TextEditingController();
  bool _isPercentage = true;
  List<FixedExpense> _fixedExpenses = [];
  int _incomeDay = 1;
  bool _incomeReminderEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        context.read<SalaryProvider>().loadSalaryPlan(userId);
        _loadExistingPlan();
      }
    });
  }

  void _loadExistingPlan() {
    final plan = context.read<SalaryProvider>().salaryPlan;
    if (plan != null) {
      _salaryController.text = plan.monthlySalary.toString();
      _savingsController.text = plan.savingsGoal.toString();
      _isPercentage = plan.isPercentage;
      _fixedExpenses = plan.fixedExpenses;
      _incomeDay = plan.incomeDay;
      _incomeReminderEnabled = plan.incomeReminderEnabled;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _salaryController.dispose();
    _savingsController.dispose();
    super.dispose();
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    await context.read<SalaryProvider>().saveSalaryPlan(
      userId: userId,
      monthlySalary: double.parse(_salaryController.text),
      fixedExpenses: _fixedExpenses,
      savingsGoal: double.parse(_savingsController.text),
      isPercentage: _isPercentage,
      incomeDay: _incomeDay,
      incomeReminderEnabled: _incomeReminderEnabled,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_incomeReminderEnabled 
            ? 'Salary plan saved! Reminder set for income day.'
            : 'Salary plan saved!')),
      );
    }
  }

  void _addFixedExpense() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Fixed Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name (e.g., Rent, EMI)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                setState(() {
                  _fixedExpenses.add(FixedExpense(
                    name: nameController.text,
                    amount: double.parse(amountController.text),
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  String _getOrdinalSuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final salary = context.watch<SalaryProvider>();
    final currencyFormat = NumberFormat.currency(symbol: settings.currencySymbol, decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Salary Planner')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary Card (if plan exists)
            if (salary.hasPlan) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.savingsGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Daily Spending Limit', style: TextStyle(color: Colors.white70)),
                            Text(
                              currencyFormat.format(salary.dailyLimit),
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            salary.isOverspending ? Icons.warning : Icons.check_circle,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: ((salary.analysis['budgetUsed'] ?? 0) / 100).clamp(0.0, 1.0),
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Remaining: ${currencyFormat.format(salary.remainingBalance)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            // Salary Input
            Text('Monthly Salary', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _salaryController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(prefixText: '${settings.currencySymbol} '),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            // Fixed Expenses
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Fixed Expenses', style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  onPressed: _addFixedExpense,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (_fixedExpenses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No fixed expenses added', style: TextStyle(color: Colors.grey)),
              )
            else
              ..._fixedExpenses.asMap().entries.map((entry) {
                final index = entry.key;
                final expense = entry.value;
                return Card(
                  child: ListTile(
                    title: Text(expense.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(currencyFormat.format(expense.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                          onPressed: () => setState(() => _fixedExpenses.removeAt(index)),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 24),
            // Savings Goal
            Text('Savings Goal', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _savingsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      suffixText: _isPercentage ? '%' : settings.currencySymbol,
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('%')),
                    ButtonSegment(value: false, label: Text('₹')),
                  ],
                  selected: {_isPercentage},
                  onSelectionChanged: (v) => setState(() => _isPercentage = v.first),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Income Day & Reminder Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.celebration, size: 20, color: Colors.green),
                        const SizedBox(width: 8),
                        Text('Income Day Reminder', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Salary Credit Day', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<int>(
                                value: _incomeDay,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: List.generate(28, (i) => i + 1)
                                    .map((d) => DropdownMenuItem(value: d, child: Text('$d${_getOrdinalSuffix(d)} of month')))
                                    .toList(),
                                onChanged: (v) => setState(() => _incomeDay = v ?? 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable Reminder'),
                      subtitle: Text(_incomeReminderEnabled 
                          ? 'You\'ll be notified 1 day before the ${_incomeDay}${_getOrdinalSuffix(_incomeDay)}'
                          : 'Reminder disabled'),
                      value: _incomeReminderEnabled,
                      onChanged: (v) => setState(() => _incomeReminderEnabled = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _savePlan,
              child: const Text('Save Plan'),
            ),
          ],
        ),
      ),
    );
  }
}
