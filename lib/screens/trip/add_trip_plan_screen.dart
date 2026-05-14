import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/trip_plan.dart';
import '../../providers/trip_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../config/constants.dart';
import 'package:intl/intl.dart';

class AddTripPlanScreen extends StatefulWidget {
  final TripPlan? tripPlan;
  const AddTripPlanScreen({super.key, this.tripPlan});

  @override
  State<AddTripPlanScreen> createState() => _AddTripPlanScreenState();
}

class _AddTripPlanScreenState extends State<AddTripPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _costController;
  late TextEditingController _friendController;

  DateTime _selectedDate = DateTime.now();
  late List<String> _friends;
  bool _isLoading = false;

  bool get _isEditing => widget.tripPlan != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tripPlan?.name ?? '');
    _costController = TextEditingController(
      text: widget.tripPlan != null && widget.tripPlan!.cost > 0
          ? widget.tripPlan!.cost.toString()
          : '',
    );
    _friendController = TextEditingController();
    if (widget.tripPlan != null) {
      _selectedDate = widget.tripPlan!.date;
      _friends = List<String>.from(widget.tripPlan!.friends);
    } else {
      _friends = [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _friendController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _addFriend() {
    final friendName = _friendController.text.trim();
    if (friendName.isNotEmpty) {
      setState(() {
        _friends.add(friendName);
        _friendController.clear();
      });
    }
  }

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId == null) throw Exception("User not logged in");

      final cost = double.tryParse(_costController.text) ?? 0.0;

      if (_isEditing) {
        await context.read<TripProvider>().updateTripPlan(
          widget.tripPlan!.id,
          _nameController.text.trim(),
          cost,
          '',
          _friends,
          _selectedDate,
        );
      } else {
        await context.read<TripProvider>().addTripPlan(
          userId,
          _nameController.text.trim(),
          cost,
          '',
          _friends,
          _selectedDate,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Trip plan updated!' : 'Trip plan saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving trip plan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Trip Plan' : 'Add Trip Plan'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                   width: 20,
                   height: 20,
                   child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveTrip,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Trip Name',
                  prefixIcon: Icon(Icons.flight_takeoff),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Trip name is required' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 16),
              Consumer<SettingsProvider>(
                builder: (context, settings, _) {
                  return TextFormField(
                    controller: _costController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    decoration: InputDecoration(
                      labelText: 'Estimated Cost',
                      prefixIcon: const Icon(Icons.attach_money),
                      prefixText: '${settings.currencySymbol} ',
                      suffixIcon: PopupMenuButton<String>(
                        icon: const Icon(Icons.currency_exchange, size: 20),
                        tooltip: 'Change currency',
                        onSelected: (value) => settings.setCurrency(value),
                        itemBuilder: (context) => AppConstants.currencies.entries.map((entry) {
                          return PopupMenuItem<String>(
                            value: entry.key,
                            child: Text('${entry.value} (${entry.key})'),
                          );
                        }).toList(),
                      ),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text('Friends', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _friendController,
                      decoration: const InputDecoration(
                        labelText: 'Add Friend Name',
                        prefixIcon: Icon(Icons.person_add),
                      ),
                      onFieldSubmitted: (_) => _addFriend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle, size: 40),
                    color: Theme.of(context).primaryColor,
                    onPressed: _addFriend,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _friends.map((friend) {
                  return Chip(
                    label: Text(friend),
                    onDeleted: () {
                      setState(() {
                        _friends.remove(friend);
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
