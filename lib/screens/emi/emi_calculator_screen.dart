import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/emi_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

class EMICalculatorScreen extends StatefulWidget {
  const EMICalculatorScreen({super.key});

  @override
  State<EMICalculatorScreen> createState() => _EMICalculatorScreenState();
}

class _EMICalculatorScreenState extends State<EMICalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _rateController = TextEditingController();
  final _tenureController = TextEditingController();
  bool _isYears = true;
  int _paymentDay = 5;
  int _reminderDays = 2;
  bool _reminderEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        context.read<EMIProvider>().loadEMIs(userId);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _rateController.dispose();
    _tenureController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final tenure = int.parse(_tenureController.text);
    final months = _isYears ? tenure * 12 : tenure;

    context.read<EMIProvider>().calculatePreview(
      loanAmount: double.parse(_amountController.text),
      interestRate: double.parse(_rateController.text),
      tenureMonths: months,
    );
  }

  Future<void> _saveEMI() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    final tenure = int.parse(_tenureController.text);
    final months = _isYears ? tenure * 12 : tenure;

    await context.read<EMIProvider>().saveEMI(
      userId: userId,
      name: _nameController.text.isEmpty ? 'Loan' : _nameController.text,
      loanAmount: double.parse(_amountController.text),
      interestRate: double.parse(_rateController.text),
      tenureMonths: months,
      paymentDay: _paymentDay,
      reminderDaysBefore: _reminderDays,
      isReminderEnabled: _reminderEnabled,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_reminderEnabled 
            ? 'EMI saved! Reminder set for $_reminderDays days before due date.'
            : 'EMI saved!')),
      );
      _clearForm();
    }
  }

  void _clearForm() {
    _nameController.clear();
    _amountController.clear();
    _rateController.clear();
    _tenureController.clear();
    context.read<EMIProvider>().clearPreview();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final emi = context.watch<EMIProvider>();
    final currencyFormat = NumberFormat.currency(symbol: settings.currencySymbol, decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('EMI Calculator')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Loan Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Loan Name (optional)', prefixIcon: Icon(Icons.label)),
            ),
            const SizedBox(height: 16),
            // Loan Amount
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Loan Amount',
                prefixIcon: const Icon(Icons.currency_rupee),
                prefixText: '${settings.currencySymbol} ',
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 16),
            // Interest Rate
            TextFormField(
              controller: _rateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Interest Rate (% per annum)',
                prefixIcon: Icon(Icons.percent),
                suffixText: '%',
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 16),
            // Tenure
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tenureController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tenure',
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    onChanged: (_) => _calculate(),
                  ),
                ),
                const SizedBox(width: 12),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Years')),
                    ButtonSegment(value: false, label: Text('Months')),
                  ],
                  selected: {_isYears},
                  onSelectionChanged: (v) {
                    setState(() => _isYears = v.first);
                    _calculate();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Payment Day & Reminder Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notifications_active, size: 20),
                        const SizedBox(width: 8),
                        Text('Payment Reminder', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Payment Day', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<int>(
                                value: _paymentDay,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: List.generate(28, (i) => i + 1)
                                    .map((d) => DropdownMenuItem(value: d, child: Text('$d')))
                                    .toList(),
                                onChanged: (v) => setState(() => _paymentDay = v ?? 5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Remind Before', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<int>(
                                value: _reminderDays,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: [1, 2, 3, 5, 7]
                                    .map((d) => DropdownMenuItem(value: d, child: Text('$d days')))
                                    .toList(),
                                onChanged: (v) => setState(() => _reminderDays = v ?? 2),
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
                      subtitle: Text(_reminderEnabled 
                          ? 'You\'ll be notified $_reminderDays days before the ${_paymentDay}th'
                          : 'Reminder disabled'),
                      value: _reminderEnabled,
                      onChanged: (v) => setState(() => _reminderEnabled = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Results
            if (emi.previewEMI != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text('Monthly EMI', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(emi.previewEMI!.monthlyEMI),
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildResultCard('Principal', currencyFormat.format(emi.previewEMI!.loanAmount), AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildResultCard('Interest', currencyFormat.format(emi.previewEMI!.totalInterest), AppTheme.accentColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildResultCard('Total Payable', currencyFormat.format(emi.previewEMI!.totalPayable), AppTheme.secondaryColor),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _saveEMI,
                icon: const Icon(Icons.save),
                label: const Text('Save This EMI'),
              ),
            ],
            const SizedBox(height: 32),
            // Saved EMIs
            if (emi.emis.isNotEmpty) ...[
              Text('Saved EMIs', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...emi.emis.map((e) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${currencyFormat.format(e.loanAmount)} @ ${e.interestRate}%'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(currencyFormat.format(e.monthlyEMI), style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Text('/month', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
