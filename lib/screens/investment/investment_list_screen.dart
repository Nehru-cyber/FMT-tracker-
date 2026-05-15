import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/investment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';

class InvestmentListScreen extends StatefulWidget {
  const InvestmentListScreen({super.key});

  @override
  State<InvestmentListScreen> createState() => _InvestmentListScreenState();
}

class _InvestmentListScreenState extends State<InvestmentListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        context.read<InvestmentProvider>().loadInvestments(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SIP & Investments'),
      ),
      body: Consumer<InvestmentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.investments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up, size: 80, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('No investments tracked yet.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Tap + to start tracking your wealth growth!'),
                ],
              ),
            );
          }

          final currency = context.watch<SettingsProvider>().currencySymbol;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.investments.length,
            itemBuilder: (context, index) {
              final investment = provider.investments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.trending_up, color: AppTheme.successColor),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        investment.name + (investment.isEdited ? ' (Edited)' : ''),
                                        style: TextStyle(
                                          fontSize: 18, 
                                          fontWeight: FontWeight.bold,
                                          fontStyle: investment.isEdited ? FontStyle.italic : FontStyle.normal,
                                          color: investment.isEdited ? Colors.grey[700] : null,
                                        ),
                                      ),
                                      Text(
                                        investment.type,
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor, size: 20),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.addInvestment,
                                arguments: {'investment': investment},
                              ).then((_) {
                                final userId = context.read<AuthProvider>().user?.id;
                                if (userId != null) {
                                  context.read<InvestmentProvider>().loadInvestments(userId);
                                }
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Investment?'),
                                  content: const Text('Are you sure you want to stop tracking this investment?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        provider.deleteInvestment(investment.id);
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
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Amount', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text(
                                '$currency${investment.amount.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Reminder Date', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text(
                                '${investment.investDay} of every month',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.addInvestment);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
