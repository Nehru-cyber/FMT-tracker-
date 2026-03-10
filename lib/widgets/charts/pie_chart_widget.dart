import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme.dart';

class ExpensePieChart extends StatelessWidget {
  final Map<String, double> data;
  final String currency;

  const ExpensePieChart({
    super.key,
    required this.data,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = data.values.fold(0.0, (sum, v) => sum + v);

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: sortedEntries.asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value.key;
                final value = entry.value.value;
                final percentage = (value / total * 100);
                final color = _getCategoryColor(category, index);

                return PieChartSectionData(
                  color: color,
                  value: value,
                  title: '${percentage.toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sortedEntries.take(5).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value.key;
            final value = entry.value.value;
            final color = _getCategoryColor(category, index);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category, int index) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.accentColor,
      AppTheme.errorColor,
      Colors.purple,
      Colors.teal,
      Colors.orange,
      Colors.pink,
    ];

    if (AppTheme.categoryColors.containsKey(category)) {
      return AppTheme.categoryColors[category]!;
    }
    return colors[index % colors.length];
  }
}
