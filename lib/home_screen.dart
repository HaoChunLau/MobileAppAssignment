import 'package:flutter/material.dart';
import 'package:mobile_app_assignment/budgeting&goal_management/budget_overview_screen.dart';
import 'package:mobile_app_assignment/expense&income_tracking/transactions_screen.dart';
import 'package:mobile_app_assignment/reports&analytics/reports_overview_screen.dart';
import 'package:mobile_app_assignment/utils/category_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:mobile_app_assignment/models/budget_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeContent(),
    const TransactionsScreen(),
    const BudgetOverviewScreen(),
    const ReportsOverviewScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Clarity Finance'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
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
            if (index == 1) {
              Navigator.pushReplacementNamed(context, '/transactions');
            } else if (index == 2) {
              Navigator.pushReplacementNamed(context, '/budget_overview');
            } else if (index == 3) {
              Navigator.pushReplacementNamed(context, '/reports_overview');
            } else if (index == 4) {
              Navigator.pushReplacementNamed(context, '/savings_goal');
            } else {
              setState(() {
                _currentIndex = index;
              });
            }
          },
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Transactions'),
            BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Budget'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reports'),
            BottomNavigationBarItem(icon: Icon(Icons.savings), label: 'Savings'),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  HomeContentState createState() => HomeContentState();
}

class HomeContentState extends State<HomeContent> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _selectedDate = DateTime.now();
  double totalIncome = 0;
  double totalExpenses = 0;
  Future<Map<String, dynamic>>? _homeDataFuture; // Store the Future

  @override
  void initState() {
    super.initState();
    _refreshData(); // Initialize the Future
  }

  // Method to refresh data
  void _refreshData() {
    setState(() {
      _homeDataFuture = _fetchHomeData();
    });
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showMonthPicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _refreshData(); // Refresh data when month changes
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overview - ${DateFormat('MMM yyyy').format(_selectedDate)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectMonth(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, dynamic>>(
            future: _homeDataFuture, // Use the stored Future
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error loading data: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No data available'));
              }

              final data = snapshot.data!;
              final balance = data['balance'] as double;
              final recentTransactions = data['recentTransactions'] as List<Map<String, dynamic>>;
              final budgets = data['budgets'] as List<BudgetModel>;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBalanceCard(balance),
                  const SizedBox(height: 20),
                  _buildQuickActions(context),
                  const SizedBox(height: 20),
                  _buildRecentTransactions(recentTransactions),
                  const SizedBox(height: 20),
                  _buildBudgetSummary(budgets),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchHomeData() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('No user logged in');
    }

    final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final endOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59);

    // Fetch transactions
    final transactionSnapshot = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .get();

    totalIncome = 0;
    totalExpenses = 0;
    for (var doc in transactionSnapshot.docs) {
      final data = doc.data();
      final amount = (data['amount'] as num).toDouble();
      if (data['isExpense'] as bool) {
        totalExpenses += amount;
      } else {
        totalIncome += amount;
      }
    }
    final balance = totalIncome - totalExpenses;

    final recentSnapshot = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .orderBy('date', descending: true)
        .limit(5)
        .get();

    final recentTransactions = recentSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'title': data['title'] as String,
        'date': (data['date'] as Timestamp).toDate(),
        'amount': (data['amount'] as num).toDouble(),
        'isExpense': data['isExpense'] as bool,
        'category': data['category'] as String,
      };
    }).toList();

    // Fetch budgets
    final budgetSnapshot = await _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('status', isNotEqualTo: 'deleted')
        .get();

    final budgets = <BudgetModel>[];
    for (var doc in budgetSnapshot.docs) {
      final budget = BudgetModel.fromFirestore(doc);
      await budget.updateCurrentSpent(_firestore); // Calculate currentSpent
      budgets.add(budget);
    }

    return {
      'balance': balance,
      'recentTransactions': recentTransactions,
      'budgets': budgets,
    };
  }

  Widget _buildBalanceCard(double balance) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
            const SizedBox(height: 8),
            Text(
              'RM ${balance.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBalanceItem('Income', 'RM ${totalIncome.toStringAsFixed(2)}', Colors.green),
                _buildBalanceItem('Expense', 'RM ${totalExpenses.toStringAsFixed(2)}', Colors.red),
              ],
            ),
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
        const SizedBox(height: 4),
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
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
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
              '/savings_add',
              Colors.amber,
            ),
            _buildActionButton(
              context,
              Icons.pie_chart,
              'Add Budget',
              '/budget_add',
              Colors.blue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
      BuildContext context, IconData icon, String label, String route, Color color) {
    return InkWell(
      onTap: () async {
        await Navigator.pushNamed(context, route);
        _refreshData(); // Refresh data after returning
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 32,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(List<Map<String, dynamic>> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/transactions');
              },
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (transactions.isEmpty)
          const Center(child: Text('No transactions for this month'))
        else
          ...transactions.map((transaction) {
            final category = transaction['category'] as String;
            return _buildTransactionItem(
              transaction['title'] as String,
              _formatDate(transaction['date'] as DateTime),
              'RM ${transaction['amount'].toStringAsFixed(2)}',
              CategoryUtils.getCategoryIcon(category),
              CategoryUtils.getCategoryColor(category),
              isExpense: transaction['isExpense'] as bool,
            );
          }),
      ],
    );
  }

  Widget _buildTransactionItem(
      String title, String date, String amount, IconData icon, Color iconColor,
      {bool isExpense = true}) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withAlpha((0.1 * 255).round()),
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

  Widget _buildBudgetSummary(List<BudgetModel> budgets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Budget Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/budget_overview');
              },
              child: const Text('Details'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (budgets.isEmpty)
          const Center(child: Text('No budgets for this month'))
        else
          ...budgets.map((budget) {
            return _buildBudgetItem(
              budget.budgetCategory,
              budget.progress,
              CategoryUtils.getCategoryColor(budget.budgetCategory),
              totalSpent: budget.currentSpent,
              totalBudget: budget.targetAmount,
            );
          }),
      ],
    );
  }

  Widget _buildBudgetItem(String category, double progress, Color color,
      {required double totalSpent, required double totalBudget}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
                  color: progress > 0.8
                      ? Theme.of(context).colorScheme.error // Use theme's error color
                      : Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.onSurface // Light color in dark mode
                          : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'RM ${totalSpent.toStringAsFixed(2)} of RM ${totalBudget.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }
}