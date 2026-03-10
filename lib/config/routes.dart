import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/expense/expense_list_screen.dart';
import '../screens/expense/add_expense_screen.dart';
import '../screens/salary/salary_planner_screen.dart';
import '../screens/emi/emi_calculator_screen.dart';
import '../screens/business/business_home_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/export/export_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/premium_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/trip/trip_plan_list_screen.dart';
import '../screens/trip/add_trip_plan_screen.dart';
import '../screens/investment/investment_list_screen.dart';
import '../screens/investment/add_investment_screen.dart';
import '../screens/gym/gym_tracker_screen.dart';
import '../screens/diet/diet_tracker_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String expenses = '/expenses';
  static const String addExpense = '/add-expense';
  static const String salaryPlanner = '/salary-planner';
  static const String emiCalculator = '/emi-calculator';
  static const String business = '/business';
  static const String analytics = '/analytics';
  static const String export = '/export';
  static const String settings = '/settings';
  static const String premium = '/premium';
  static const String profile = '/profile';
  static const String tripPlanner = '/trip-planner';
  static const String addTripPlan = '/add-trip-plan';
  static const String investments = '/investments';
  static const String addInvestment = '/add-investment';
  static const String gymTracker = '/gym-tracker';
  static const String dietTracker = '/diet-tracker';
  
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), settings);
      case onboarding:
        return _buildRoute(const OnboardingScreen(), settings);
      case login:
        return _buildRoute(const LoginScreen(), settings);
      case register:
        return _buildRoute(const RegisterScreen(), settings);
      case home:
        return _buildRoute(const HomeScreen(), settings);
      case expenses:
        return _buildRoute(const ExpenseListScreen(), settings);
      case addExpense:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(AddExpenseScreen(expense: args?['expense']), settings);
      case salaryPlanner:
        return _buildRoute(const SalaryPlannerScreen(), settings);
      case emiCalculator:
        return _buildRoute(const EMICalculatorScreen(), settings);
      case business:
        return _buildRoute(const BusinessHomeScreen(), settings);
      case analytics:
        return _buildRoute(const AnalyticsScreen(), settings);
      case export:
        return _buildRoute(const ExportScreen(), settings);
      case AppRoutes.settings:
        return _buildRoute(const SettingsScreen(), settings);
      case premium:
        return _buildRoute(const PremiumScreen(), settings);
      case profile:
        return _buildRoute(const ProfileScreen(), settings);
      case tripPlanner:
        return _buildRoute(const TripPlanListScreen(), settings);
      case addTripPlan:
        return _buildRoute(const AddTripPlanScreen(), settings);
      case investments:
        return _buildRoute(const InvestmentListScreen(), settings);
      case addInvestment:
        return _buildRoute(const AddInvestmentScreen(), settings);
      case gymTracker:
        return _buildRoute(const GymTrackerScreen(), settings);
      case dietTracker:
        return _buildRoute(const DietTrackerScreen(), settings);
      default:
        return _buildRoute(
          Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
          settings,
        );
    }
  }
  
  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        
        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
