import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/trip_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import 'package:intl/intl.dart';

class TripPlanListScreen extends StatefulWidget {
  const TripPlanListScreen({super.key});

  @override
  State<TripPlanListScreen> createState() => _TripPlanListScreenState();
}

class _TripPlanListScreenState extends State<TripPlanListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        context.read<TripProvider>().loadTripPlans(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Planner'),
      ),
      body: Consumer<TripProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.tripPlans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flight_takeoff, size: 80, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('No trip plans yet.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Tap + to start planning your next adventure!'),
                ],
              ),
            );
          }

          final currency = context.watch<SettingsProvider>().currencySymbol;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.tripPlans.length,
            itemBuilder: (context, index) {
              final trip = provider.tripPlans[index];
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
                            child: Text(
                              trip.name + (trip.isEdited ? ' (Edited)' : ''),
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                                fontStyle: trip.isEdited ? FontStyle.italic : FontStyle.normal,
                                color: trip.isEdited ? Colors.grey[700] : null,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor, size: 20),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.addTripPlan,
                                arguments: {'tripPlan': trip},
                              ).then((_) {
                                final userId = context.read<AuthProvider>().user?.id;
                                if (userId != null) {
                                  context.read<TripProvider>().loadTripPlans(userId);
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
                                  title: const Text('Delete Trip?'),
                                  content: const Text('Are you sure you want to delete this trip plan?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        provider.deleteTripPlan(trip.id);
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
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(DateFormat('dd MMM yyyy').format(trip.date), style: const TextStyle(color: Colors.grey)),
                          const SizedBox(width: 16),
                          const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                          Text('$currency${trip.cost.toStringAsFixed(0)}', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      if (trip.dietPlan.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.restaurant_menu, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(child: Text('Diet: ${trip.dietPlan}', style: const TextStyle(color: Colors.grey))),
                          ],
                        ),
                      ],
                      if (trip.friends.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.people, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(child: Text('Friends: ${trip.friends.join(", ")}', style: const TextStyle(color: Colors.grey))),
                          ],
                        ),
                      ],
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
          Navigator.pushNamed(context, AppRoutes.addTripPlan);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
