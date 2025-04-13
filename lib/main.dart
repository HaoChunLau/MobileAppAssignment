import 'package:flutter/material.dart';
import 'package:mobile_app_assignment/budgeting&goal_management/budget_overview_screen.dart';
import 'package:mobile_app_assignment/budgeting&goal_management/budget_setting_screen.dart';
import 'package:mobile_app_assignment/budgeting&goal_management/savings_goal_screen.dart';
import 'package:mobile_app_assignment/budgeting&goal_management/savings_progress_screen.dart';
import 'package:mobile_app_assignment/expense&income_tracking/add_expense_screen.dart';
import 'package:mobile_app_assignment/expense&income_tracking/add_income_screen.dart';
import 'package:mobile_app_assignment/expense&income_tracking/edit_expense_screen.dart';
import 'package:mobile_app_assignment/expense&income_tracking/edit_income_screen.dart';
import 'package:mobile_app_assignment/expense&income_tracking/expense_list_screen.dart';
import 'package:mobile_app_assignment/expense&income_tracking/income_list_screen.dart';
import 'package:mobile_app_assignment/reports&analytics/analytics_screen.dart';
import 'package:mobile_app_assignment/reports&analytics/daily_summary_screen.dart';
import 'package:mobile_app_assignment/reports&analytics/export_screen.dart';
import 'package:mobile_app_assignment/reports&analytics/filter_screen.dart';
import 'package:mobile_app_assignment/reports&analytics/monthly_summary_screen.dart';
import 'package:mobile_app_assignment/reports&analytics/reports_overview_screen.dart';
import 'package:mobile_app_assignment/user_management&security/change_password_screen.dart';
import 'package:mobile_app_assignment/user_management&security/forgot_password_screen.dart';
import 'package:mobile_app_assignment/user_management&security/login_screen.dart';
import 'package:mobile_app_assignment/user_management&security/profile_management_screen';
import 'package:mobile_app_assignment/user_management&security/setting_screen.dart';
import 'package:mobile_app_assignment/user_management&security/sign_up_screen.dart';

void main() {
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
      home: HomeScreen(),
      routes: {
        // Module 1: Expense & Income Tracking
        '/expense_list': (context) => ExpenseListScreen(),
        '/add_expense': (context) => AddExpenseScreen(),
        '/edit_expense': (context) => EditExpenseScreen(),
        '/income_list': (context) => IncomeListScreen(),
        '/add_income': (context) => AddIncomeScreen(),
        '/edit_income': (context) => EditIncomeScreen(),
        
        // Module 2: Budgeting & Goal Management
        '/budget_overview': (context) => BudgetOverviewScreen(),
        '/budget_setting': (context) => BudgetSettingScreen(),
        '/savings_goal': (context) => SavingsGoalScreen(),
        '/savings_progress': (context) => SavingsProgressScreen(),
        
        // Module 3: Reports & Analytics
        '/reports_overview': (context) => ReportsOverviewScreen(),
        '/daily_summary': (context) => DailySummaryScreen(),
        '/monthly_summary': (context) => MonthlySummaryScreen(),
        '/analytics': (context) => AnalyticsScreen(),
        '/filter': (context) => FilterScreen(),
        '/export': (context) => ExportScreen(),
        
        // Module 4: User Management & Security
        '/login': (context) => LoginScreen(onThemeChanged: _updateThemeMode),
        '/signup': (context) => SignUpScreen(onThemeChanged: _updateThemeMode),
        '/profile': (context) => ProfileManagementScreen(),
        '/change_password': (context) => ChangePasswordScreen(),
        '/forgot_password': (context) => ForgotPasswordScreen(),
        '/settings': (context) => SettingsScreen(onThemeChanged: _updateThemeMode),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // The different screens to show based on bottom navigation bar selection
  final List<Widget> _screens = [
    HomeContent(),
    ExpenseListScreen(),
    IncomeListScreen(),
    BudgetOverviewScreen(),
    ReportsOverviewScreen(),
    ProfileManagementScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clarity Finance'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Expense',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monetization_on),
            label: 'Income',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceCard(),
          SizedBox(height: 20),
          _buildQuickActions(context),
          SizedBox(height: 20),
          _buildRecentTransactions(),
          SizedBox(height: 20),
          _buildBudgetSummary(),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Balance',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'RM 3,580.42',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBalanceItem('Income', 'RM 5,240.00', Colors.green),
                _buildBalanceItem('Expense', 'RM 1,659.58', Colors.red),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem(String title, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildActionButton(
              context,
              Icons.add_circle,
              'Add Expense',
              '/add_expense',
              Colors.red,
            ),
            _buildActionButton(
              context,
              Icons.attach_money,
              'Add Income',
              '/add_income',
              Colors.green,
            ),
            _buildActionButton(
              context,
              Icons.savings,
              'Add Goal',
              '/savings_goal',
              Colors.amber,
            ),
            _buildActionButton(
              context,
              Icons.pie_chart,
              'Budget',
              '/budget_overview',
              Colors.blue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, String route, Color color) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 32,
              color: color,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text('See All'),
            ),
          ],
        ),
        SizedBox(height: 12),
        _buildTransactionItem(
          'Groceries',
          'Yesterday',
          'RM 85.40',
          Icons.shopping_cart,
          Colors.blue,
          isExpense: true,
        ),
        _buildTransactionItem(
          'Salary',
          'Mar 15',
          'RM 4,500.00',
          Icons.account_balance,
          Colors.green,
          isExpense: false,
        ),
        _buildTransactionItem(
          'Restaurant',
          'Mar 14',
          'RM 124.80',
          Icons.restaurant,
          Colors.orange,
          isExpense: true,
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
    String title,
    String date,
    String amount,
    IconData icon,
    Color iconColor,
    {bool isExpense = true}
  ) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
          ),
        ),
        title: Text(title),
        subtitle: Text(date),
        trailing: Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isExpense ? Colors.red : Colors.green,
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Budget Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text('Details'),
            ),
          ],
        ),
        SizedBox(height: 12),
        _buildBudgetItem('Food & Drinks', 0.7, Colors.orange),
        _buildBudgetItem('Transportation', 0.5, Colors.blue),
        _buildBudgetItem('Entertainment', 0.9, Colors.red),
        _buildBudgetItem('Utilities', 0.3, Colors.green),
      ],
    );
  }

  Widget _buildBudgetItem(String category, double progress, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: progress > 0.8 ? Colors.red : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}