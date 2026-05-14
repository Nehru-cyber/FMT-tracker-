import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/expense_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/expense.dart';

class ExpenseListScreen extends StatelessWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final expense = context.watch<ExpenseProvider>();
    final currencyFormat = NumberFormat.currency(symbol: settings.currencySymbol, decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Month Selector
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    final userId = context.read<AuthProvider>().user?.id;
                    if (userId != null) {
                      final newMonth = DateTime(
                        expense.selectedMonth.year,
                        expense.selectedMonth.month - 1,
                      );
                      expense.setSelectedMonth(newMonth, userId);
                    }
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy').format(expense.selectedMonth),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    final userId = context.read<AuthProvider>().user?.id;
                    if (userId != null) {
                      final newMonth = DateTime(
                        expense.selectedMonth.year,
                        expense.selectedMonth.month + 1,
                      );
                      expense.setSelectedMonth(newMonth, userId);
                    }
                  },
                ),
              ],
            ),
          ),
          // Summary Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Income',
                    currencyFormat.format(expense.totalIncome),
                    AppTheme.secondaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Expense',
                    currencyFormat.format(expense.totalExpense),
                    AppTheme.errorColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Expense List
          Expanded(
            child: expense.filteredExpenses.isEmpty
                ? const Center(child: Text('No expenses for this month'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: expense.filteredExpenses.length,
                    itemBuilder: (context, index) {
                      final e = expense.filteredExpenses[index];
                      return _buildExpenseItem(context, e, settings.currencySymbol);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 12)),
          const SizedBox(height: 4),
          Text(amount, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(BuildContext context, Expense expense, String currency) {
    final isIncome = expense.type == ExpenseType.income;
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppTheme.errorColor,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        final userId = context.read<AuthProvider>().user?.id;
        if (userId != null) {
          context.read<ExpenseProvider>().deleteExpense(expense.id, userId);
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isIncome ? AppTheme.secondaryColor : AppTheme.errorColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? AppTheme.secondaryColor : AppTheme.errorColor,
            ),
          ),
          title: Text(expense.category, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat('dd MMM yyyy').format(expense.date)),
              if (expense.note.isNotEmpty) Text(expense.note, style: const TextStyle(fontSize: 12)),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${isIncome ? '+' : '-'}$currency${expense.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isIncome ? AppTheme.secondaryColor : AppTheme.errorColor,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: AppTheme.primaryColor,
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.addExpense,
                    arguments: {'expense': expense},
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    final expense = context.read<ExpenseProvider>();
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter by Category', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('All Categories'),
              leading: Radio<String?>(
                value: null,
                groupValue: expense.selectedCategory,
                onChanged: (v) {
                  expense.setSelectedCategory(null);
                  Navigator.pop(context);
                },
              ),
            ),
            ...['Food', 'Travel', 'Shopping', 'Bills', 'Entertainment'].map((cat) => ListTile(
              title: Text(cat),
              leading: Radio<String?>(
                value: cat,
                groupValue: expense.selectedCategory,
                onChanged: (v) {
                  expense.setSelectedCategory(v);
                  Navigator.pop(context);
                },
              ),
            )),
          ],
        ),
      ),
    );
  }
}
