import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/investment_provider.dart';
import '../../providers/auth_provider.dart';

class AddInvestmentScreen extends StatefulWidget {
  const AddInvestmentScreen({super.key});

  @override
  State<AddInvestmentScreen> createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends State<AddInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  
  String _selectedType = 'SIP';
  final List<String> _investmentTypes = [
    'SIP',
    'Mutual Fund',
    'Stocks',
    'Fixed Deposit',
    'Recurring Deposit',
    'Other'
  ];

  int _investDay = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveInvestment() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId == null) throw Exception("User not logged in");

      final amount = double.tryParse(_amountController.text) ?? 0.0;

      await context.read<InvestmentProvider>().addInvestment(
        userId: userId,
        name: _nameController.text.trim(),
        amount: amount,
        investDay: _investDay,
        type: _selectedType,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Investment tracked successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving investment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Investment'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                   width: 20,
                   height: 20,
                   child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveInvestment,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Investment Name (e.g., HDFC Midcap)',
                  prefixIcon: Icon(Icons.account_balance),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Amount is required';
                  if (double.tryParse(value) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Investment Type',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _investmentTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedType = val);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _investDay,
                decoration: const InputDecoration(
                  labelText: 'Investment/Reminder Day',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                items: List.generate(31, (index) => index + 1).map((day) {
                  return DropdownMenuItem(
                    value: day,
                    child: Text('$day of the month'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _investDay = val);
                  }
                },
              ),
              const SizedBox(height: 24),
              const Card(
                color: Color(0xFFF0FDF4), // Light green tint
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active, color: Colors.green),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'A reminder will be automatically sent to you 1 day before the investment date.',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
