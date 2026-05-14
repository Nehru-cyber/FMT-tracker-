import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/expense_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/export_service.dart';
import '../../services/premium_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isExporting = false;

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _exportPDF() async {
    final canAccess = await PremiumService.canAccessFeature('export');
    if (!canAccess) {
      _showPremiumDialog();
      return;
    }

    setState(() => _isExporting = true);
    try {
      final expenses = context.read<ExpenseProvider>().expenses;

      final file = await ExportService.exportToPDF(
        expenses: expenses,
        title: 'FMT Tracker Report',
        startDate: _startDate,
        endDate: _endDate,
      );

      await ExportService.shareFile(file);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF exported successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
    setState(() => _isExporting = false);
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Feature'),
        content: const Text('Export to PDF is a premium feature. Upgrade to unlock!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/premium');
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final expense = context.watch<ExpenseProvider>();
    final isPremium = context.watch<AuthProvider>().isPremium;

    return Scaffold(
      appBar: AppBar(title: const Text('Export Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!isPremium)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Upgrade to Premium', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('Unlock PDF exports', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/premium'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primaryColor),
                    child: const Text('Upgrade'),
                  ),
                ],
              ),
            ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Date Range'),
              subtitle: Text('${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}'),
              trailing: const Icon(Icons.edit),
              onTap: _selectDateRange,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Export Summary', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _buildSummaryRow('Total Transactions', '${expense.expenses.length}'),
                  _buildSummaryRow('Total Income', '${settings.currencySymbol}${expense.totalIncome.toStringAsFixed(0)}'),
                  _buildSummaryRow('Total Expense', '${settings.currencySymbol}${expense.totalExpense.toStringAsFixed(0)}'),
                  _buildSummaryRow('Net Balance', '${settings.currencySymbol}${expense.balance.toStringAsFixed(0)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Export Options', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildExportOption(
            icon: Icons.picture_as_pdf,
            title: 'Export as PDF',
            subtitle: 'Generate a PDF report',
            color: Colors.red,
            onTap: _isExporting ? null : _exportPDF,
            isPremium: !isPremium,
          ),
          if (_isExporting) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
    required bool isPremium,
  }) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color),
        ),
        title: Row(
          children: [
            Text(title),
            if (isPremium) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('PRO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
