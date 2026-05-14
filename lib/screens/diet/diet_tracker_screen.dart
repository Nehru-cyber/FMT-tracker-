import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';

class DietTrackerScreen extends StatefulWidget {
  const DietTrackerScreen({super.key});

  @override
  State<DietTrackerScreen> createState() => _DietTrackerScreenState();
}

class _DietTrackerScreenState extends State<DietTrackerScreen> {
  final List<Map<String, dynamic>> _meals = [];
  static const List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  void _addMeal() {
    final nameCtrl = TextEditingController();
    final caloriesCtrl = TextEditingController();
    String selectedType = 'Breakfast';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add Meal', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Meal / Food Name',
                  prefixIcon: Icon(Icons.restaurant_menu),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: caloriesCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Calories (kcal)',
                  prefixIcon: Icon(Icons.local_fire_department),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Meal Type',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _mealTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (v) => setSheetState(() => selectedType = v!),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  setState(() {
                    _meals.insert(0, {
                      'name': nameCtrl.text.trim(),
                      'calories': int.tryParse(caloriesCtrl.text) ?? 0,
                      'type': selectedType,
                      'date': DateTime.now(),
                    });
                  });
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check),
                label: const Text('Save Meal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editMeal(int index) {
    final m = _meals[index];
    final nameCtrl = TextEditingController(text: m['name']);
    final caloriesCtrl = TextEditingController(text: m['calories'].toString());
    String selectedType = m['type'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Edit Meal', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Meal / Food Name',
                  prefixIcon: Icon(Icons.restaurant_menu),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: caloriesCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Calories (kcal)',
                  prefixIcon: Icon(Icons.local_fire_department),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Meal Type',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _mealTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (v) => setSheetState(() => selectedType = v!),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  setState(() {
                    _meals[index] = {
                      'name': nameCtrl.text.trim(),
                      'calories': int.tryParse(caloriesCtrl.text) ?? 0,
                      'type': selectedType,
                      'date': m['date'],
                    };
                  });
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check),
                label: const Text('Update Meal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _mealTypeIcon(String type) {
    switch (type) {
      case 'Breakfast': return Icons.free_breakfast;
      case 'Lunch': return Icons.lunch_dining;
      case 'Dinner': return Icons.dinner_dining;
      case 'Snack': return Icons.cookie;
      default: return Icons.restaurant;
    }
  }

  Color _mealTypeColor(String type) {
    switch (type) {
      case 'Breakfast': return const Color(0xFFF59E0B);
      case 'Lunch': return const Color(0xFF10B981);
      case 'Dinner': return const Color(0xFF6366F1);
      case 'Snack': return const Color(0xFFEC4899);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCalories = _meals.fold<int>(0, (sum, m) => sum + (m['calories'] as int));
    final goalCalories = 2000;

    return Scaffold(
      appBar: AppBar(title: const Text('Diet Tracker')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMeal,
        child: const Icon(Icons.add),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.restaurant_menu, color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Text('Daily Summary', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Icon(Icons.local_fire_department, color: Colors.white70, size: 20),
                            const SizedBox(height: 6),
                            Text('$totalCalories', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            const Text('Calories', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Icon(Icons.flag, color: Colors.white70, size: 20),
                            const SizedBox(height: 6),
                            Text('$goalCalories', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            const Text('Goal', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Icon(Icons.restaurant, color: Colors.white70, size: 20),
                            const SizedBox(height: 6),
                            Text('${_meals.length}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            const Text('Meals', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (totalCalories / goalCalories).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.white24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(totalCalories / goalCalories * 100).toStringAsFixed(0)}% of daily goal',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          if (_meals.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No meals logged yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    SizedBox(height: 4),
                    Text('Tap + to log your first meal', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final m = _meals[index];
                    final color = _mealTypeColor(m['type']);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_mealTypeIcon(m['type']), color: color),
                        ),
                        title: Text(m['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${m['type']} • ${m['calories']} kcal'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit_outlined, color: color, size: 20),
                              onPressed: () => _editMeal(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                              onPressed: () => setState(() => _meals.removeAt(index)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _meals.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
