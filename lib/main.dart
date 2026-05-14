import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/auth_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/salary_provider.dart';
import 'providers/emi_provider.dart';
import 'providers/business_provider.dart';
import 'providers/trip_provider.dart';
import 'providers/investment_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/settings_provider.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Database
  try {
    await DatabaseService.initialize();
  } catch (e) {
    debugPrint('Database initialization failed: $e');
  }
  
  // Initialize Notifications
  try {
    await NotificationService.initialize();
    await NotificationService.requestPermissions();
  } catch (e) {
    debugPrint('Notification initialization failed: $e');
  }
  
  // Set preferred orientations
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e) {
    debugPrint('Orientation setup failed: $e');
  }
  
  runApp(const FMTTrackerApp());
}

class FMTTrackerApp extends StatelessWidget {
  const FMTTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => SalaryProvider()),
        ChangeNotifierProvider(create: (_) => EMIProvider()),
        ChangeNotifierProvider(create: (_) => BusinessProvider()),
        ChangeNotifierProvider(create: (_) => TripProvider()),
        ChangeNotifierProvider(create: (_) => InvestmentProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'FMT Tracker',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
            onGenerateRoute: AppRoutes.generateRoute,
          );
        },
      ),
    );
  }
}
