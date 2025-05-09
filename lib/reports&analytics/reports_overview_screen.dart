import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app_assignment/models/transaction_model.dart';

class ReportsOverviewScreen extends StatefulWidget {
  const ReportsOverviewScreen({super.key});

  @override
  State<ReportsOverviewScreen> createState() => _ReportsOverviewScreenState();
}

class _ReportsOverviewScreenState extends State<ReportsOverviewScreen> {
  int _currentIndex = 3;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  double _income = 0.0;
  double _expense = 0.0;
  double _savings = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMonthlySummary();
  }

  Future<void> _fetchMonthlySummary() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    try {
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
          .where('date',
              isLessThanOrEqualTo: Timestamp.fromDate(lastDayOfMonth))
          .get();

      double totalIncome = 0.0;
      double totalExpense = 0.0;

      for (var doc in querySnapshot.docs) {
        final transaction = TransactionModel.fromFirestore(doc);
        if (transaction.isExpense) {
          totalExpense += transaction.amount;
        } else {
          totalIncome += transaction.amount;
        }
      }

      setState(() {
        _income = totalIncome;
        _expense = totalExpense;
        _savings = totalIncome - totalExpense;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent default pop
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Reports & Analytics'),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportsSummaryCard(context),
              SizedBox(height: 20),
              _buildReportsCategories(context),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildReportsSummaryCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This Month\'s Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryItem(
                          'Income', 'RM ${_income.toStringAsFixed(2)}', Colors.green),
                      _buildSummaryItem(
                          'Expense', 'RM ${_expense.toStringAsFixed(2)}', Colors.red),
                      _buildSummaryItem(
                          'Savings', 'RM ${_savings.toStringAsFixed(2)}', Colors.blue),
                    ],
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/monthly_summary');
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 40),
                    ),
                    child: Text('View Detailed Monthly Report'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String amount, Color color) {
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildReportsCategories(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reports',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: [
            _buildReportCard(
              context,
              'Daily Summary',
              Icons.calendar_today,
              Colors.orange,
              '/daily_summary',
            ),
            _buildReportCard(
              context,
              'Monthly Summary',
              Icons.calendar_month,
              Colors.green,
              '/monthly_summary',
            ),
            _buildReportCard(
              context,
              'Analytics',
              Icons.analytics,
              Colors.purple,
              '/analytics',
            ),
            _buildReportCard(
              context,
              'Export Reports',
              Icons.download,
              Colors.teal,
              '/export',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String route,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, route);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== Bottom Navigation ==========
  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _handleBottomNavigationTap,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet), label: 'Transactions'),
        BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Budget'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reports'),
        BottomNavigationBarItem(icon: Icon(Icons.savings), label: 'Savings'),
      ],
    );
  }

  // ========== Navigation Methods ==========
  void _handleBottomNavigationTap(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/transactions');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/budget_overview');
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/savings_goal');
    } else {
      setState(() => _currentIndex = index);
    }
  }
}