import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../services/premium_service.dart';
import '../../providers/auth_provider.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<AuthProvider>().isPremium;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Premium'),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.workspace_premium,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (isPremium) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.successColor),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.successColor, size: 32),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('You\'re Premium!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              Text('Enjoy all premium features'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Text(
                  isPremium ? 'Your Benefits' : 'Unlock Premium Features',
                  style: Theme.of(context).textTheme.headlineSmall,
                ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                const SizedBox(height: 16),
                ...AppConstants.premiumFeatures.asMap().entries.map((entry) {
                  final index = entry.key;
                  final feature = entry.value;
                  return _buildFeatureItem(feature, index).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
                }),
                const SizedBox(height: 32),
                if (!isPremium) ...[
                  Text('Choose Your Plan', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _buildPlanCard(
                    context: context,
                    title: 'Monthly',
                    price: '₹${AppConstants.premiumMonthlyPrice.toStringAsFixed(0)}',
                    period: '/month',
                    isPopular: false,
                    onTap: () => _subscribe(context, false),
                  ),
                  const SizedBox(height: 12),
                  _buildPlanCard(
                    context: context,
                    title: 'Yearly',
                    price: '₹${AppConstants.premiumYearlyPrice.toStringAsFixed(0)}',
                    period: '/year',
                    isPopular: true,
                    savings: 'Save ₹${((AppConstants.premiumMonthlyPrice * 12) - AppConstants.premiumYearlyPrice).toStringAsFixed(0)}',
                    onTap: () => _subscribe(context, true),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Subscriptions will auto-renew. Cancel anytime.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature, int index) {
    final icons = [
      Icons.block,
      Icons.picture_as_pdf,
      Icons.cloud_upload,
      Icons.store,
      Icons.analytics,
      Icons.support_agent,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icons[index % icons.length], color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(feature, style: const TextStyle(fontSize: 16)),
          ),
          const Icon(Icons.check_circle, color: AppTheme.successColor),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required String title,
    required String price,
    required String period,
    required bool isPopular,
    String? savings,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isPopular ? AppTheme.primaryGradient : null,
          color: isPopular ? null : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isPopular ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isPopular ? Colors.white : null,
                        ),
                      ),
                      if (isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'BEST VALUE',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (savings != null)
                    Text(savings, style: TextStyle(color: isPopular ? Colors.white70 : AppTheme.successColor)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isPopular ? Colors.white : null,
                  ),
                ),
                Text(period, style: TextStyle(color: isPopular ? Colors.white70 : Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _subscribe(BuildContext context, bool isYearly) async {
    // Simulate subscription
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    await Future.delayed(const Duration(seconds: 2));
    await PremiumService.activatePremium(isYearly: isYearly);

    Navigator.pop(context); // Close loading
    Navigator.pop(context); // Go back

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Welcome to Premium! 🎉')),
    );
  }
}
