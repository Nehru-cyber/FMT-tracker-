import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/business.dart';
import '../../models/business_transaction.dart';
import '../../providers/business_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

class BusinessHomeScreen extends StatefulWidget {
  const BusinessHomeScreen({super.key});

  @override
  State<BusinessHomeScreen> createState() => _BusinessHomeScreenState();
}

class _BusinessHomeScreenState extends State<BusinessHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        context.read<BusinessProvider>().loadBusinesses(userId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final business = context.watch<BusinessProvider>();
    final settings = context.watch<SettingsProvider>();
    final currencyFormat = NumberFormat.currency(symbol: settings.currencySymbol, decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Accounting'),
        bottom: business.businesses.isNotEmpty
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Dashboard'),
                  Tab(text: 'Transactions'),
                  Tab(text: 'Customers'),
                ],
              )
            : null,
      ),
      body: business.businesses.isEmpty
          ? _buildEmptyState()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboard(business, currencyFormat),
                _buildTransactions(business, settings),
                _buildCustomers(business),
              ],
            ),
      floatingActionButton: business.businesses.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showAddTransactionDialog(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('No business added yet'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddBusinessDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Business'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BusinessProvider business, NumberFormat currencyFormat) {
    return FutureBuilder<Map<String, double>>(
      future: business.getProfitLoss(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final profitLoss = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Business Selector
            if (business.businesses.length > 1)
              DropdownButton<String>(
                value: business.selectedBusiness?.id,
                isExpanded: true,
                items: business.businesses.map((b) => DropdownMenuItem(
                  value: b.id,
                  child: Text(b.name),
                )).toList(),
                onChanged: (id) {
                  final selected = business.businesses.firstWhere((b) => b.id == id);
                  business.selectBusiness(selected);
                },
              ),
            const SizedBox(height: 16),
            // Summary Cards
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: profitLoss['profit']! >= 0 ? AppTheme.incomeGradient : AppTheme.expenseGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    profitLoss['profit']! >= 0 ? 'Total Profit' : 'Total Loss',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(profitLoss['profit']!.abs()),
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Income', currencyFormat.format(profitLoss['income']), AppTheme.secondaryColor, Icons.arrow_downward),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Expense', currencyFormat.format(profitLoss['expense']), AppTheme.errorColor, Icons.arrow_upward),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Transactions', business.transactions.length.toString(), AppTheme.primaryColor, Icons.receipt),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Customers', business.customers.length.toString(), AppTheme.accentColor, Icons.people),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactions(BusinessProvider business, SettingsProvider settings) {
    if (business.transactions.isEmpty) {
      return const Center(child: Text('No transactions yet'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: business.transactions.length,
      itemBuilder: (context, index) {
        final t = business.transactions[index];
        final isIncome = t.type == TransactionType.income;
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
            title: Text(t.note.isNotEmpty ? t.note : (isIncome ? 'Income' : 'Expense')),
            subtitle: Text(DateFormat('dd MMM yyyy').format(t.date)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${settings.currencySymbol}${t.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isIncome ? AppTheme.secondaryColor : AppTheme.errorColor,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppTheme.primaryColor,
                  onPressed: () => _showEditTransactionDialog(context, t),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppTheme.errorColor,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Transaction?'),
                        content: const Text('Are you sure you want to delete this transaction?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              business.deleteTransaction(t.id);
                            },
                            child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomers(BusinessProvider business) {
    if (business.customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No customers yet'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddCustomerDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Customer'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: business.customers.length,
      itemBuilder: (context, index) {
        final c = business.customers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(child: Text(c.name[0].toUpperCase())),
            title: Text(c.name),
            subtitle: Text(c.phone),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppTheme.primaryColor,
                  onPressed: () => _showEditCustomerDialog(context, c),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppTheme.errorColor,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Customer?'),
                        content: const Text('Are you sure you want to delete this customer?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              business.deleteCustomer(c.id);
                            },
                            child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddBusinessDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Business'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Business Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final userId = context.read<AuthProvider>().user?.id;
                if (userId != null) {
                  await context.read<BusinessProvider>().createBusiness(
                    userId: userId,
                    name: nameController.text,
                    type: 'General',
                  );
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    TransactionType type = TransactionType.income;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Transaction'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(value: TransactionType.income, label: Text('Income')),
                    ButtonSegment(value: TransactionType.expense, label: Text('Expense')),
                  ],
                  selected: {type},
                  onSelectionChanged: (v) => setState(() => type = v.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  decoration: const InputDecoration(labelText: 'Amount'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Amount is required';
                    if (double.tryParse(value) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: 'Note'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await context.read<BusinessProvider>().addTransaction(
                    amount: double.parse(amountController.text),
                    type: type,
                    date: DateTime.now(),
                    note: noteController.text,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                await context.read<BusinessProvider>().addCustomer(
                  name: nameController.text,
                  phone: phoneController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditTransactionDialog(BuildContext context, BusinessTransaction transaction) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(text: transaction.amount.toString());
    final noteController = TextEditingController(text: transaction.note);
    TransactionType type = transaction.type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Transaction'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(value: TransactionType.income, label: Text('Income')),
                    ButtonSegment(value: TransactionType.expense, label: Text('Expense')),
                  ],
                  selected: {type},
                  onSelectionChanged: (v) => setState(() => type = v.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  decoration: const InputDecoration(labelText: 'Amount'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Amount is required';
                    if (double.tryParse(value) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: 'Note'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await context.read<BusinessProvider>().updateTransaction(
                    id: transaction.id,
                    amount: double.parse(amountController.text),
                    type: type,
                    date: transaction.date,
                    note: noteController.text,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCustomerDialog(BuildContext context, Customer c) {
    final nameController = TextEditingController(text: c.name);
    final phoneController = TextEditingController(text: c.phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                await context.read<BusinessProvider>().updateCustomer(
                  id: c.id,
                  name: nameController.text,
                  phone: phoneController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
