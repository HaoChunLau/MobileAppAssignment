import 'package:flutter/material.dart';
import 'package:mobile_app_assignment/budgeting&goal_management/budget_overview_screen.dart';
import 'package:mobile_app_assignment/expense&income_tracking/expense_list_screen.dart';
import 'package:mobile_app_assignment/expense&income_tracking/income_list_screen.dart';
import 'package:mobile_app_assignment/reports&analytics/reports_overview_screen.dart';
import 'package:mobile_app_assignment/user_management&security/login_screen.dart';
import 'package:mobile_app_assignment/user_management&security/setting_screen.dart';
import 'package:mobile_app_assignment/user_management&security/sign_up_screen.dart';

void main() {
  runApp(const FinanceApp());
}

class FinanceApp extends StatefulWidget {
  const FinanceApp({super.key});

  @override
  FinanceAppState createState() => FinanceAppState();
}

class FinanceAppState extends State<FinanceApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleDarkMode(bool isDarkMode) {
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Finance App',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: HomeScreen(onThemeChanged: _toggleDarkMode),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final Function(bool) onThemeChanged;

  const HomeScreen({super.key, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Finance Manager")),
      drawer: AppDrawer(onThemeChanged: onThemeChanged), // Integrated Drawer
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Welcome to Your Finance App",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExpenseListScreen()),
                );
              },
              child: const Text("View Expenses"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const IncomeListScreen()),
                );
              },
              child: const Text("View Income"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BudgetOverviewScreen()),
                );
              },
              child: const Text("Budget Overview"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReportsOverviewScreen()),
                );
              },
              child: const Text("Reports & Analytics"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen(onThemeChanged: onThemeChanged)),
                );
              },
              child: const Text("Login"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpScreen(onThemeChanged: onThemeChanged)),
                );
              },
              child: const Text("Sign Up"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SettingsScreen(onThemeChanged: onThemeChanged)),
                );
              },
              child: const Text("Settings"),
            ),
          ],
        ),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  final Function(bool) onThemeChanged;

  const AppDrawer({super.key, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text("Menu", style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            title: const Text("Expenses"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExpenseListScreen()),
              );
            },
          ),
          ListTile(
            title: const Text("Income"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IncomeListScreen()),
              );
            },
          ),
          ListTile(
            title: const Text("Budgeting"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BudgetOverviewScreen()),
              );
            },
          ),
          ListTile(
            title: const Text("Reports"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportsOverviewScreen()),
              );
            },
          ),
          ListTile(
            title: const Text("Settings"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SettingsScreen(onThemeChanged: onThemeChanged)),
              );
            },
          ),
        ],
      ),
    );
  }
}
