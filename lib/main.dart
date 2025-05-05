import 'package:flutter/material.dart';
import 'package:mobile_app_assignment/budgeting&goal_management/budget_detail_screen.dart';
import 'package:mobile_app_assignment/budgeting&goal_management/budget_overview_screen.dart';
import 'package:mobile_app_assignment/budgeting&goal_management/budget_add_screen.dart';
import 'package:mobile_app_assignment/budgeting&goal_management/budget_edit_screen.dart';
import 'package:mobile_app_assignment/budgeting&goal_management/budget_history_screen.dart';
import 'package:mobile_app_assignment/budgeting&goal_management/savings_goal_screen.dart';
import 'package:mobile_app_assignment/budgeting&goal_management/savings_progress_screen.dart';
import 'package:mobile_app_assignment/budgeting&goal_management/savings_goal_add_screen.dart';
import 'package:mobile_app_assignment/budgeting&goal_management/savings_goal_edit_screen.dart';
import 'package:mobile_app_assignment/budgeting&goal_management/savings_goal_history_screen.dart';
import 'package:mobile_app_assignment/expense&income_tracking/transactions_screen.dart';
import 'package:mobile_app_assignment/expense&income_tracking/add_expense_screen.dart';
import 'package:mobile_app_assignment/expense&income_tracking/add_income_screen.dart';
import 'package:mobile_app_assignment/expense&income_tracking/edit_expense_screen.dart';
import 'package:mobile_app_assignment/expense&income_tracking/edit_income_screen.dart';
import 'package:mobile_app_assignment/expense&income_tracking/expense_list_screen.dart';
import 'package:mobile_app_assignment/expense&income_tracking/income_list_screen.dart';
import 'package:mobile_app_assignment/reports&analytics/analytics_screen.dart';
import 'package:mobile_app_assignment/reports&analytics/daily_summary_screen.dart';
import 'package:mobile_app_assignment/reports&analytics/export_screen.dart';
import 'package:mobile_app_assignment/reports&analytics/monthly_summary_screen.dart';
import 'package:mobile_app_assignment/reports&analytics/reports_overview_screen.dart';
import 'package:mobile_app_assignment/user_management&security/change_password_screen.dart';
import 'package:mobile_app_assignment/user_management&security/forgot_password_screen.dart';
import 'package:mobile_app_assignment/user_management&security/login_screen.dart';
import 'package:mobile_app_assignment/user_management&security/profile_management_screen.dart';
import 'package:mobile_app_assignment/user_management&security/setting_screen.dart';
import 'package:mobile_app_assignment/user_management&security/sign_up_screen.dart';
import 'package:mobile_app_assignment/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(FinanceApp());
}

class FinanceApp extends StatefulWidget {
  const FinanceApp({super.key});

  @override
  FinanceAppState createState() => FinanceAppState();
}

class FinanceAppState extends State<FinanceApp> {
  // Track the current theme mode
  ThemeMode _themeMode = ThemeMode.system;

  // Method to update the theme mode
  void _updateThemeMode(bool isDarkMode) {
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clarity Finance',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      themeMode: _themeMode, // Use the dynamic theme mode
      home: AuthenticationWrapper(onThemeChanged: _updateThemeMode),
      routes: {
        // Module 1: Expense & Income Tracking
        '/transactions': (context) => AuthGuard(child: TransactionsScreen()),
        '/expense_list': (context) => AuthGuard(child: ExpenseListScreen()),
        '/add_expense': (context) => AuthGuard(child: AddExpenseScreen()),
        '/edit_expense': (context) => AuthGuard(child: EditExpenseScreen()),
        '/income_list': (context) => AuthGuard(child: IncomeListScreen()),
        '/add_income': (context) => AuthGuard(child: AddIncomeScreen()),
        '/edit_income': (context) => AuthGuard(child: EditIncomeScreen()),

        // Module 2: Budgeting & Goal Management
        '/budget_overview': (context) => AuthGuard(child: BudgetOverviewScreen()),
        '/budget_add': (context) => AuthGuard(child: BudgetAddScreen()),
        '/budget_edit': (context) => AuthGuard(child: BudgetEditScreen()),
        '/budget_detail': (context) => AuthGuard(child: BudgetDetailScreen()),
        '/budget_history': (context) => AuthGuard(child: BudgetHistoryScreen()),
        '/savings_goal': (context) => AuthGuard(child: SavingsGoalScreen()),
        '/savings_progress': (context) => AuthGuard(child: SavingsProgressScreen()),
        '/savings_add': (context) => AuthGuard(child: SavingsGoalAddScreen()),
        '/savings_edit': (context) => AuthGuard(child: SavingsGoalEditScreen()),
        '/savings_history': (context) => AuthGuard(child: SavingsGoalHistoryScreen()),

        // Module 3: Reports & Analytics
        '/reports_overview': (context) => AuthGuard(child: ReportsOverviewScreen()),
        '/daily_summary': (context) => AuthGuard(child: DailySummaryScreen()),
        '/monthly_summary': (context) => AuthGuard(child: MonthlySummaryScreen()),
        '/analytics': (context) => AuthGuard(child: AnalyticsScreen()),
        '/export': (context) => AuthGuard(child: ExportScreen()),

        // Module 4: User Management & Security
        '/login': (context) => LoginScreen(onThemeChanged: _updateThemeMode),
        '/signup': (context) => SignUpScreen(onThemeChanged: _updateThemeMode),
        '/profile': (context) => AuthGuard(child: ProfileManagementScreen()),
        '/change_password': (context) => AuthGuard(child: ChangePasswordScreen()),
        '/forgot_password': (context) => ForgotPasswordScreen(),
        '/settings': (context) => AuthGuard(child: SettingsScreen(onThemeChanged: _updateThemeMode)),
        '/home': (context) => AuthGuard(child: HomeScreen()),
      },
    );
  }
}

// Wrapper to check authentication status
class AuthenticationWrapper extends StatelessWidget {
  final Function(bool) onThemeChanged;
  
  const AuthenticationWrapper({super.key, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the snapshot has user data, then they're already signed in
        if (snapshot.hasData && snapshot.data != null) {
          return HomeScreen();
        }
        // Otherwise, they're not signed in
        return LoginScreen(onThemeChanged: onThemeChanged);
      },
    );
  }
}

// Guard to protect routes that require authentication
class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasData && snapshot.data != null) {
          return child;
        } else {
          // If not logged in, redirect to login page
          // Use a microtask to avoid calling Navigator during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          
          // Return loading indicator to show while navigation is happening
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
      },
    );
  }
}