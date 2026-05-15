import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/wish_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../config/theme.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        context.read<WishProvider>().loadWishes(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishes'),
      ),
      body: Consumer<WishProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.wishes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_outline, size: 80, color: Colors.amber),
                  const SizedBox(height: 16),
                  const Text('No wishes yet.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Start saving for what you love!'),
                ],
              ),
            );
          }

          final settings = context.watch<SettingsProvider>();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.wishes.length,
            itemBuilder: (context, index) {
              final wish = provider.wishes[index];
              return _buildWishCard(context, wish, settings.currencySymbol);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWishDialog(context),
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildWishCard(BuildContext context, wish, String currency) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    wish.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => context.read<WishProvider>().deleteWish(wish.id),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Goal: $currency${wish.targetAmount.toStringAsFixed(0)}'),
                Text('Saved: $currency${wish.savedAmount.toStringAsFixed(0)}'),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: wish.progress,
                minHeight: 12,
                backgroundColor: Colors.grey[200],
                color: wish.isCompleted ? Colors.green : Colors.amber,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(wish.progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (!wish.isCompleted)
                  TextButton.icon(
                    onPressed: () => _showUpdateAmountDialog(context, wish),
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text('Add Savings'),
                  )
                else
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text('Goal Reached!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWishDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Wish'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'What is your wish?')),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Target Amount'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                final userId = context.read<AuthProvider>().user?.id;
                if (userId != null) {
                  context.read<WishProvider>().addWish(
                    userId,
                    titleController.text,
                    double.parse(amountController.text),
                  );
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Save Wish'),
          ),
        ],
      ),
    );
  }

  void _showUpdateAmountDialog(BuildContext context, wish) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Save for ${wish.title}'),
        content: TextField(
          controller: amountController,
          decoration: const InputDecoration(labelText: 'Amount to add'),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (amountController.text.isNotEmpty) {
                context.read<WishProvider>().updateWishAmount(
                  wish.id,
                  double.parse(amountController.text),
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
}
