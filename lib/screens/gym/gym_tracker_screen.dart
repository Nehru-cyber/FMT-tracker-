import 'package:flutter/material.dart';
import '../../config/theme.dart';

class GymTrackerScreen extends StatefulWidget {
  const GymTrackerScreen({super.key});

  @override
  State<GymTrackerScreen> createState() => _GymTrackerScreenState();
}

class _GymTrackerScreenState extends State<GymTrackerScreen> {
  final List<Map<String, dynamic>> _workouts = [];

  void _addWorkout() {
    final nameCtrl = TextEditingController();
    final setsCtrl = TextEditingController();
    final repsCtrl = TextEditingController();
    final weightCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add Workout', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Exercise Name',
                prefixIcon: Icon(Icons.fitness_center),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: setsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Sets'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: repsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Reps'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Weight (kg)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                setState(() {
                  _workouts.insert(0, {
                    'name': nameCtrl.text.trim(),
                    'sets': int.tryParse(setsCtrl.text) ?? 0,
                    'reps': int.tryParse(repsCtrl.text) ?? 0,
                    'weight': double.tryParse(weightCtrl.text) ?? 0.0,
                    'date': DateTime.now(),
                  });
                });
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check),
              label: const Text('Save Workout'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalSets = _workouts.fold<int>(0, (sum, w) => sum + (w['sets'] as int));
    final totalReps = _workouts.fold<int>(0, (sum, w) => sum + ((w['sets'] as int) * (w['reps'] as int)));

    return Scaffold(
      appBar: AppBar(title: const Text('Gym Tracker')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addWorkout,
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
                  colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.3),
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
                      Icon(Icons.fitness_center, color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Text('Today\'s Summary', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildSummaryItem('Exercises', '${_workouts.length}', Icons.list_alt)),
                      Expanded(child: _buildSummaryItem('Total Sets', '$totalSets', Icons.repeat)),
                      Expanded(child: _buildSummaryItem('Total Reps', '$totalReps', Icons.loop)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_workouts.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No workouts yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    SizedBox(height: 4),
                    Text('Tap + to log your first exercise', style: TextStyle(color: Colors.grey)),
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
                    final w = _workouts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.fitness_center, color: Color(0xFF7C3AED)),
                        ),
                        title: Text(w['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${w['sets']} sets × ${w['reps']} reps • ${w['weight']} kg'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                          onPressed: () => setState(() => _workouts.removeAt(index)),
                        ),
                      ),
                    );
                  },
                  childCount: _workouts.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
