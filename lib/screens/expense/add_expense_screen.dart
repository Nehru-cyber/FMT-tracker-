import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../providers/auth_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;
  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  ExpenseType _type = ExpenseType.expense;
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  String? _selectedMood;

  final List<String> _moods = ['😊', '😔', '😤', '🥳', '🤔', '🍕', '💸'];

  final List<Map<String, dynamic>> _expenseCategories = [
    {'name': 'Food', 'icon': Icons.restaurant, 'color': const Color(0xFFFF6B6B)},
    {'name': 'Travel', 'icon': Icons.directions_car, 'color': const Color(0xFF4ECDC4)},
    {'name': 'Rent', 'icon': Icons.home, 'color': const Color(0xFF45B7D1)},
    {'name': 'Shopping', 'icon': Icons.shopping_bag, 'color': const Color(0xFFDDA0DD)},
    {'name': 'Medical', 'icon': Icons.medical_services, 'color': const Color(0xFF98D8C8)},
    {'name': 'Entertainment', 'icon': Icons.movie, 'color': const Color(0xFFF7DC6F)},
    {'name': 'Bills', 'icon': Icons.receipt, 'color': const Color(0xFFBB8FCE)},
    {'name': 'Education', 'icon': Icons.school, 'color': const Color(0xFF85C1E9)},
    {'name': 'Other', 'icon': Icons.more_horiz, 'color': const Color(0xFF95A5A6)},
  ];

  final List<Map<String, dynamic>> _incomeCategories = [
    {'name': 'Salary', 'icon': Icons.account_balance_wallet, 'color': const Color(0xFF10B981)},
    {'name': 'Freelance', 'icon': Icons.work, 'color': const Color(0xFF6366F1)},
    {'name': 'Investment', 'icon': Icons.trending_up, 'color': const Color(0xFF22C55E)},
    {'name': 'Gift', 'icon': Icons.card_giftcard, 'color': const Color(0xFFF59E0B)},
    {'name': 'Other', 'icon': Icons.more_horiz, 'color': const Color(0xFF95A5A6)},
  ];

  List<Map<String, dynamic>> get _categories => 
      _type == ExpenseType.income ? _incomeCategories : _expenseCategories;

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _amountController.text = widget.expense!.amount.toString();
      _noteController.text = widget.expense!.note;
      _type = widget.expense!.type;
      _selectedCategory = widget.expense!.category;
      _selectedDate = widget.expense!.date;
      _selectedMood = widget.expense!.mood;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    if (widget.expense != null) {
      await context.read<ExpenseProvider>().updateExpense(
        userId: userId,
        id: widget.expense!.id,
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        date: _selectedDate,
        type: _type,
        note: _noteController.text,
        mood: _selectedMood,
      );
    } else {
      await context.read<ExpenseProvider>().addExpense(
        userId: userId,
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        date: _selectedDate,
        type: _type,
        note: _noteController.text,
        mood: _selectedMood,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense == null ? 'Add Transaction' : 'Edit Transaction'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type Toggle
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _type = ExpenseType.expense;
                        _selectedCategory = _expenseCategories.first['name'];
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _type == ExpenseType.expense ? AppTheme.errorColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Expense',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _type == ExpenseType.expense ? Colors.white : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _type = ExpenseType.income;
                        _selectedCategory = _incomeCategories.first['name'];
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _type == ExpenseType.income ? AppTheme.secondaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Income',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _type == ExpenseType.income ? Colors.white : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Amount Field
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                prefixStyle: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Amount is required';
                if (double.tryParse(value) == null) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 24),
            // Category Selection
            Text('Category', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat['name'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat['name']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? cat['color'] : cat['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat['icon'], size: 18, color: isSelected ? Colors.white : cat['color']),
                        const SizedBox(width: 8),
                        Text(
                          cat['name'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : cat['color'],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Date Picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate)),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
            ),
            const SizedBox(height: 16),
            // Note Field
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            // Mood Selector
            Text('How do you feel about this?', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _moods.map((mood) {
                final isSelected = _selectedMood == mood;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMood = isSelected ? null : mood),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor.withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.transparent),
                    ),
                    child: Text(mood, style: const TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            // Save Button
            ElevatedButton(
              onPressed: _saveExpense,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _type == ExpenseType.income ? AppTheme.secondaryColor : AppTheme.errorColor,
              ),
              child: Text('Save ${_type == ExpenseType.income ? 'Income' : 'Expense'}'),
            ),
          ],
        ),
      ),
    );
  }
}
