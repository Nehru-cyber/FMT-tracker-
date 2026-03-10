import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/emi_provider.dart';
import '../../providers/salary_provider.dart';
import '../../models/expense.dart';
import '../../widgets/charts/pie_chart_widget.dart';
import '../../widgets/common/stat_card.dart';
import '../../widgets/home/alerts_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId != null) {
      context.read<ExpenseProvider>().loadExpenses(userId);
      context.read<EMIProvider>().loadEMIs(userId);
      context.read<SalaryProvider>().loadSalaryPlan(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(),
          _buildExpensesTab(),
          _buildToolsTab(),
          _buildSettingsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addExpense).then((_) => _loadData()),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.dashboard, 'Home', 0),
            _buildNavItem(Icons.receipt_long, 'Expenses', 1),
            const SizedBox(width: 40),
            _buildNavItem(Icons.calculate, 'Tools', 2),
            _buildNavItem(Icons.settings, 'Settings', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? AppTheme.primaryColor : Colors.grey, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppTheme.primaryColor : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final settings = context.watch<SettingsProvider>();
    final expense = context.watch<ExpenseProvider>();
    final auth = context.watch<AuthProvider>();
    final currencyFormat = NumberFormat.currency(symbol: settings.currencySymbol, decimalDigits: 0);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          floating: true,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeaderAvatar(auth),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Hello, ${auth.user?.name.split(' ').first ?? 'User'}!',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            background: Container(
              decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                settings.notificationsEnabled
                    ? Icons.notifications
                    : Icons.notifications_off_outlined,
                color: Colors.white,
              ),
              onPressed: () {
                final newValue = !settings.notificationsEnabled;
                settings.setNotifications(newValue);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(newValue
                        ? 'Notifications turned on'
                        : 'Notifications turned off'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Balance Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(expense.balance),
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildBalanceItem(
                            'Income',
                            currencyFormat.format(expense.totalIncome),
                            Icons.arrow_downward,
                            Colors.greenAccent,
                          ),
                        ),
                        Container(width: 1, height: 40, color: Colors.white24),
                        Expanded(
                          child: _buildBalanceItem(
                            'Expense',
                            currencyFormat.format(expense.totalExpense),
                            Icons.arrow_upward,
                            Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Alerts Section
              const AlertsSection(),
              const SizedBox(height: 16),
              // Monthly Budget Progress
              _buildBudgetProgress(expense, settings),
              const SizedBox(height: 24),
              // Quick Actions
              Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildQuickAction(Icons.add_circle, 'Add Expense', AppTheme.errorColor, () => Navigator.pushNamed(context, AppRoutes.addExpense))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildQuickAction(Icons.savings, 'Salary Plan', AppTheme.secondaryColor, () => Navigator.pushNamed(context, AppRoutes.salaryPlanner))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildQuickAction(Icons.calculate, 'EMI Calc', AppTheme.accentColor, () => Navigator.pushNamed(context, AppRoutes.emiCalculator))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildQuickAction(Icons.add, 'More', AppTheme.primaryColor, () => _showMoreActions(context))),
                ],
              ),
              const SizedBox(height: 24),
              // Expense Chart
              if (expense.expenses.isNotEmpty) ...[
                Text('Spending by Category', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: ExpensePieChart(
                    data: expense.getCategoryBreakdown(type: ExpenseType.expense),
                    currency: settings.currencySymbol,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Recent Transactions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Transactions', style: Theme.of(context).textTheme.titleLarge),
                  TextButton(onPressed: () => setState(() => _currentIndex = 1), child: const Text('See All')),
                ],
              ),
              const SizedBox(height: 8),
              ...expense.expenses.take(5).map((e) => _buildTransactionItem(e, settings.currencySymbol)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderAvatar(AuthProvider auth) {
    final photoPath = auth.user?.photoPath;
    final initial = (auth.user?.name ?? 'U')[0].toUpperCase();
    return CircleAvatar(
      radius: 14,
      backgroundColor: Colors.white24,
      backgroundImage: photoPath != null && photoPath.isNotEmpty
          ? FileImage(File(photoPath))
          : null,
      child: photoPath == null || photoPath.isEmpty
          ? Text(initial, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))
          : null,
    );
  }

  Widget _buildBalanceItem(String label, String amount, IconData icon, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 1),
            ],
          ),
        ),
      ],
    );
  }

  void _showMoreActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('More Actions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildMoreActionItem(Icons.flight_takeoff, 'Trip Planner', Colors.deepOrange, () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.tripPlanner); }),
                _buildMoreActionItem(Icons.trending_up, 'Investments', Colors.green, () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.investments); }),
                _buildMoreActionItem(Icons.fitness_center, 'Gym Tracker', Colors.deepPurple, () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.gymTracker); }),
                _buildMoreActionItem(Icons.restaurant_menu, 'Diet Tracker', Colors.teal, () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.dietTracker); }),
                _buildMoreActionItem(Icons.access_time, 'Clock', Colors.orange, () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.clock); }),
                _buildMoreActionItem(Icons.store, 'Business', AppTheme.primaryColor, () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.business); }),
                _buildMoreActionItem(Icons.analytics, 'Analytics', Colors.purple, () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.analytics); }),
                _buildMoreActionItem(Icons.file_download, 'Export', Colors.teal.shade700, () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.export); }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreActionItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: 90,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Expense expense, String currency) {
    final isIncome = expense.type == ExpenseType.income;
    return Card(
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
        subtitle: Text(DateFormat('dd MMM').format(expense.date)),
        trailing: Text(
          '${isIncome ? '+' : '-'}$currency${expense.amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isIncome ? AppTheme.secondaryColor : AppTheme.errorColor,
          ),
        ),
      ),
    );
  }

  Widget _buildExpensesTab() {
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: Consumer<ExpenseProvider>(
        builder: (context, expense, _) {
          if (expense.expenses.isEmpty) {
            return const Center(child: Text('No expenses yet. Add your first expense!'));
          }
          final filtered = _searchQuery.isEmpty
              ? expense.expenses
              : expense.expenses.where((e) {
                  final query = _searchQuery.toLowerCase();
                  return e.category.toLowerCase().contains(query) ||
                      e.note.toLowerCase().contains(query);
                }).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by category or note...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text('No matching expenses', style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final e = filtered[index];
                          return _buildTransactionItem(e, context.read<SettingsProvider>().currencySymbol);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToolsTab() {
    return Scaffold(
      appBar: AppBar(title: const Text('Financial Tools')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildToolCard('SIP & Investments', 'Track wealth growth', Icons.trending_up, Colors.green, () => Navigator.pushNamed(context, AppRoutes.investments)),
          _buildToolCard('Trip Planner', 'Plan your next adventure', Icons.flight_takeoff, Colors.deepOrange, () => Navigator.pushNamed(context, AppRoutes.tripPlanner)),
          _buildToolCard('Salary Planner', 'Plan your monthly budget', Icons.savings, AppTheme.secondaryColor, () => Navigator.pushNamed(context, AppRoutes.salaryPlanner)),
          _buildToolCard('EMI Calculator', 'Calculate loan EMIs', Icons.calculate, AppTheme.accentColor, () => Navigator.pushNamed(context, AppRoutes.emiCalculator)),
          _buildToolCard('Clock & Alarm', 'Exact time & timers', Icons.access_time, Colors.orange, () => Navigator.pushNamed(context, AppRoutes.clock)),
          _buildToolCard('Business Accounting', 'Track business finances', Icons.store, AppTheme.primaryColor, () => Navigator.pushNamed(context, AppRoutes.business)),
          _buildToolCard('Analytics', 'View detailed reports', Icons.analytics, Colors.purple, () => Navigator.pushNamed(context, AppRoutes.analytics)),
          _buildToolCard('Gym Tracker', 'Track your workouts', Icons.fitness_center, Colors.deepPurple, () => Navigator.pushNamed(context, AppRoutes.gymTracker)),
          _buildToolCard('Diet Tracker', 'Log meals & calories', Icons.restaurant_menu, Colors.teal, () => Navigator.pushNamed(context, AppRoutes.dietTracker)),
          _buildToolCard('Export Reports', 'Export to PDF/Excel', Icons.file_download, Colors.teal.shade700, () => Navigator.pushNamed(context, AppRoutes.export)),
        ],
      ),
    );
  }

  Widget _buildToolCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildBudgetProgress(ExpenseProvider expense, SettingsProvider settings) {
    final salary = context.watch<SalaryProvider>();
    final budget = salary.hasPlan ? salary.salaryPlan!.monthlySalary : 0.0;
    final spent = expense.totalExpense;
    final percent = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final currencyFormat = NumberFormat.currency(symbol: settings.currencySymbol, decimalDigits: 0);

    Color progressColor;
    if (percent < 0.5) {
      progressColor = AppTheme.successColor;
    } else if (percent < 0.8) {
      progressColor = AppTheme.accentColor;
    } else {
      progressColor = AppTheme.errorColor;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.pie_chart, color: progressColor, size: 20),
                  const SizedBox(width: 8),
                  Text('Monthly Budget', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              Text(
                '${(percent * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontWeight: FontWeight.bold, color: progressColor, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              backgroundColor: progressColor.withOpacity(0.15),
              color: progressColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ${currencyFormat.format(spent)}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              Text(
                'Budget: ${budget > 0 ? currencyFormat.format(budget) : "Not set"}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Appearance'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
          ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: const Text('Premium'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.premium),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppTheme.primaryColor),
            title: const Text('About'),
            subtitle: const Text('v1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'FMT Tracker',
                applicationVersion: '1.0.0',
                applicationIcon: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/images/logo.png', width: 48, height: 48, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_balance_wallet, color: AppTheme.primaryColor),
                    ),
                  ),
                ),
                children: const [
                  Text('Your complete finance management companion. Track expenses, plan budgets, calculate EMIs, and manage business finances — all in one app.'),
                ],
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.errorColor),
            title: const Text('Logout', style: TextStyle(color: AppTheme.errorColor)),
            onTap: () async {
              await context.read<AuthProvider>().logout();
              if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),
        ],
      ),
    );
  }
}
