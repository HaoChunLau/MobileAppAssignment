import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile_app_assignment/budgeting&goal_management/budget_detail_screen.dart';
import 'package:mobile_app_assignment/budgeting&goal_management/budget_overview_screen.dart';
import 'package:mobile_app_assignment/budgeting&goal_management/budget_add_screen.dart';
import 'package:mobile_app_assignment/budgeting&goal_management/budget_edit_screen.dart';
import 'package:mobile_app_assignment/budgeting&goal_management/savings_goal_screen.dart';
import 'package:mobile_app_assignment/budgeting&goal_management/savings_progress_screen.dart';
import 'package:mobile_app_assignment/budgeting&goal_management/savings_goal_add_screen.dart';
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
import 'package:mobile_app_assignment/user_management&security/email_verification_code_screen.dart';
import 'package:mobile_app_assignment/user_management&security/forgot_password_screen.dart';
import 'package:mobile_app_assignment/user_management&security/help_support_screen.dart';
import 'package:mobile_app_assignment/user_management&security/login_screen.dart';
import 'package:mobile_app_assignment/user_management&security/profile_management_screen.dart';
import 'package:mobile_app_assignment/user_management&security/setting_screen.dart';
import 'package:mobile_app_assignment/user_management&security/sign_up_screen.dart';
import 'package:mobile_app_assignment/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  initializeAuthService();
  runApp(FinanceApp());
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService() {
    // Set the default language code for Firebase Authentication
    _auth.setLanguageCode('en-US');
  }

  // Set up a listener to update the user's verification status in Firestore
  void setupEmailVerificationListener() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        // Reload user to get latest emailVerified status
        await user.reload();
        if (user.emailVerified) {
          await _firestore.collection('users').doc(user.uid).update({
            'emailVerified': true,
          });
        }
      }
    });
  }

  // Call this after successful login to check if email is verified
  Future<bool> checkEmailVerification() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // This method can be used in your login flow to ensure only verified emails can access the app
  Future<bool> requireEmailVerification() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      return false;
    }
    await user.reload();
    return user.emailVerified;
  }
}

// Initialize AuthService
void initializeAuthService() {
  final authService = AuthService();
  authService.setupEmailVerificationListener();
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
      themeMode: _themeMode,
      // Add locale configuration
      locale: const Locale('en', 'US'), // Default locale
      supportedLocales: const [
        Locale('en', 'US'), // English (United States)
        Locale('ms', 'MY'), // Malay (Malaysia, based on RM currency in your UI)
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AuthenticationWrapper(onThemeChanged: _updateThemeMode),
      routes: {
        '/home': (context) => AuthGuard(child: HomeScreen()),

        // Module 1: Expense & Income Tracking
        '/transactions': (context) => AuthGuard(child: TransactionsScreen()),
        '/expense_list': (context) => AuthGuard(child: ExpenseListScreen(selectedDate: DateTime.now())),
        '/add_expense': (context) => AuthGuard(child: AddExpenseScreen()),
        '/edit_expense': (context) => AuthGuard(child: EditExpenseScreen()),
        '/income_list': (context) => AuthGuard(child: IncomeListScreen(selectedDate: DateTime.now())),
        '/add_income': (context) => AuthGuard(child: AddIncomeScreen()),
        '/edit_income': (context) => AuthGuard(child: EditIncomeScreen()),

        // Module 2: Budgeting & Goal Management
        '/budget_overview': (context) => AuthGuard(child: BudgetOverviewScreen()),
        '/budget_add': (context) => AuthGuard(child: BudgetAddScreen()),
        '/budget_edit': (context) => AuthGuard(child: BudgetEditScreen()),
        '/budget_detail': (context) => AuthGuard(child: BudgetDetailScreen()),
        '/savings_goal': (context) => AuthGuard(child: SavingsGoalScreen()),
        '/savings_progress': (context) => AuthGuard(child: SavingsProgressScreen()),
        '/savings_add': (context) => AuthGuard(child: SavingsGoalAddScreen()),

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
        '/help_support': (context) => AuthGuard(child: HelpSupportScreen()),
        '/verify_email': (context) => AuthGuard(
              child: EmailVerificationInstructionsScreen(
                email: FirebaseAuth.instance.currentUser?.email ?? '',
                name: '',
                phoneNumber: '',
                onVerificationComplete: () async {
                  // This will be handled by the screen itself, but you can define additional logic if needed
                },
              ),
            ),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<bool>(
            future: AuthService().requireEmailVerification(),
            builder: (context, verificationSnapshot) {
              if (verificationSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (verificationSnapshot.hasData && verificationSnapshot.data == true) {
                return HomeScreen();
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context).pushReplacementNamed('/verify_email');
                });
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
            },
          );
        }
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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<bool>(
            future: AuthService().requireEmailVerification(),
            builder: (context, verificationSnapshot) {
              if (verificationSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (verificationSnapshot.hasData && verificationSnapshot.data == true) {
                return child;
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context).pushReplacementNamed('/verify_email');
                });
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
            },
          );
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
      },
    );
  }
}