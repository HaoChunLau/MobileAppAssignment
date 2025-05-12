import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app_assignment/models/transaction_model.dart';
import 'package:mobile_app_assignment/utils/category_utils.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:mobile_app_assignment/models/budget_model.dart';

class MonthlySummaryScreen extends StatefulWidget {
  const MonthlySummaryScreen({super.key});

  @override
  MonthlySummaryScreenState createState() => MonthlySummaryScreenState();
}

class MonthlySummaryScreenState extends State<MonthlySummaryScreen> {
  DateTime _selectedMonth = DateTime.now();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  double _income = 0.0;
  double _expense = 0.0;
  double _savings = 0.0;
  double _budget = 0.0; // New state variable for budget
  Map<String, double> _categoryBreakdown = {};
  List<Map<String, dynamic>> _insights = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchMonthlyData();
  }

  Future<void> _fetchMonthlyData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No user logged in';
      });
      return;
    }

    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    try {
      // Fetch transactions
      final transactionSnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
          .where('date',
              isLessThanOrEqualTo: Timestamp.fromDate(lastDayOfMonth))
          .get();

      double totalIncome = 0.0;
      double totalExpense = 0.0;
      Map<String, double> categoryTotals = {
        for (var category in CategoryUtils.expenseCategories) category: 0.0
      };

      for (var doc in transactionSnapshot.docs) {
        final transaction = TransactionModel.fromFirestore(doc);
        if (transaction.isExpense) {
          totalExpense += transaction.amount;
          if (categoryTotals.containsKey(transaction.category)) {
            categoryTotals[transaction.category] =
                categoryTotals[transaction.category]! + transaction.amount;
          } else {
            categoryTotals['Other'] = (categoryTotals['Other'] ?? 0.0) + transaction.amount;
          }
        } else {
          totalIncome += transaction.amount;
        }
      }

      // Calculate category percentages
      Map<String, double> breakdown = {};
      categoryTotals.forEach((category, amount) {
        if (totalExpense > 0) {
          breakdown[category] = amount / totalExpense;
        } else {
          breakdown[category] = 0.0;
        }
      });

      // Generate insights
      List<Map<String, dynamic>> insights = [];
      if (breakdown['Food']! > 0.4) {
        insights.add({
          'icon': Icons.trending_up,
          'color': Colors.red,
          'text': 'Food expenses account for over 40% of your expenses.',
        });
      }
      if (totalIncome > 0 && totalExpense / totalIncome < 0.5) {
        insights.add({
          'icon': Icons.savings,
          'color': Colors.blue,
          'text': 'You saved over 50% of your income this month - great job!',
        });
      }
      if (breakdown['Entertainment']! > 0.2) {
        insights.add({
          'icon': Icons.trending_up,
          'color': Colors.orange,
          'text': 'Entertainment spending is higher than average this month.',
        });
      }

      // Fetch budgets
      final budgetSnapshot = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      double totalBudget = 0.0;
      for (var doc in budgetSnapshot.docs) {
        final budget = BudgetModel.fromFirestore(doc);
        final budgetStart = budget.startDate;
        final budgetEnd = budget.endDate;
        if ((budgetStart.isBefore(lastDayOfMonth) || budgetStart.isAtSameMomentAs(lastDayOfMonth)) &&
            (budgetEnd.isAfter(firstDayOfMonth) || budgetEnd.isAtSameMomentAs(firstDayOfMonth))) {
          totalBudget += budget.targetAmount;
        }
      }

      setState(() {
        _income = totalIncome;
        _expense = totalExpense;
        _savings = totalIncome - totalExpense;
        _budget = totalBudget; // Store the fetched budget
        _categoryBreakdown = breakdown;
        _insights = insights;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Monthly Summary'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthSelector(),
            SizedBox(height: 20),
            _buildMonthlySummaryCard(context),
            SizedBox(height: 20),
            _buildMonthlyChart(),
            SizedBox(height: 20),
            _buildCategoryBreakdown(),
            SizedBox(height: 20),
            _buildMonthlyInsights(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios),
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(
                    _selectedMonth.year,
                    _selectedMonth.month - 1,
                    1,
                  );
                  _fetchMonthlyData();
                });
              },
            ),
            GestureDetector(
              onTap: () => _showMonthPicker(context),
              child: Text(
                DateFormat('MMMM yyyy').format(_selectedMonth),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward_ios),
              onPressed: () {
                final nextMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month + 1,
                  1,
                );
                if (nextMonth.isBefore(DateTime.now()) ||
                    (nextMonth.month == DateTime.now().month &&
                        nextMonth.year == DateTime.now().year)) {
                  setState(() {
                    _selectedMonth = nextMonth;
                    _fetchMonthlyData();
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMonthPicker(BuildContext context) async {
    final DateTime? picked = await showMonthPicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedMonth) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
        _fetchMonthlyData();
      });
    }
  }

  Widget _buildMonthlySummaryCard(BuildContext context) {
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
              'Monthly Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : (_income == 0.0 && _expense == 0.0)
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No transactions recorded for this month',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/add_expense');
                              },
                              icon: Icon(Icons.add),
                              label: Text('Add a Transaction'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSummaryItem('Income',
                                  'RM ${_income.toStringAsFixed(2)}', Colors.green),
                              _buildSummaryItem('Expense',
                                  'RM ${_expense.toStringAsFixed(2)}', Colors.red),
                              _buildSummaryItem('Savings',
                                  'RM ${_savings.toStringAsFixed(2)}', Colors.blue),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSummaryItem(
                                  'Budget', 'RM ${_budget.toStringAsFixed(2)}', Colors.purple),
                              _buildSummaryItem(
                                  'vs Budget',
                                  '${_budget > 0 ? ((_expense / _budget) * 100).toStringAsFixed(0) : 0}% of budget',
                                  Colors.orange),
                            ],
                          ),
                        ],
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String amount, Color color) {
    return Expanded(
      child: Column(
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
      ),
    );
  }

  Widget _buildMonthlyChart() {
    if (_income == 0.0 && _expense == 0.0) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Income vs Expense',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Icon(
                  Icons.bar_chart_outlined,
                  size: 40,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 8),
                Text(
                  'No data to display for this month',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final maxValue = [
      _income,
      _expense,
      _savings > 0 ? _savings : 0.0
    ].reduce((a, b) => a > b ? a : b);
    final scale = maxValue > 0 ? 1.0 / maxValue : 1.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Income vs Expense',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.5,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildChartBar('Income', _income * scale, Colors.green),
                          _buildChartBar('Expense', _expense * scale, Colors.red),
                          _buildChartBar('Savings', (_savings > 0 ? _savings : 0.0) * scale,
                              Colors.blue),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildChartLabel('Income', Colors.green),
                        _buildChartLabel('Expense', Colors.red),
                        _buildChartLabel('Savings', Colors.blue),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartBar(String label, double value, Color color) {
    return Container(
      width: 60,
      height: 150 * value.clamp(0.0, 1.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
    );
  }

  Widget _buildChartLabel(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expense Categories',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: _expense == 0.0
                ? Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 24,
                          color: Colors.grey[400],
                        ),
                        SizedBox(width: 8),
                        Text(
                          'No expenses recorded for this month',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: _categoryBreakdown.entries
                        .where((entry) => entry.value > 0)
                        .map((entry) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: _buildCategoryItem(
                          entry.key,
                          'RM ${(_expense * entry.value).toStringAsFixed(2)}',
                          entry.value,
                          CategoryUtils.getCategoryColor(entry.key),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(String category, String amount, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(category),
            Text(
              amount,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(width: 8),
            Text(
              '${(percentage * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthlyInsights(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Insights',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: _insights.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 24,
                              color: Colors.grey[400],
                            ),
                            SizedBox(width: 8),
                            Text(
                              'No insights available for this month',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/add_expense');
                          },
                          child: Text(
                            'Add transactions to get insights',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: _insights.asMap().entries.map((entry) {
                      final insight = entry.value;
                      return Column(
                        children: [
                          _buildInsightItem(
                            insight['icon'],
                            insight['color'],
                            insight['text'],
                          ),
                          if (entry.key < _insights.length - 1) Divider(height: 24),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightItem(IconData icon, Color color, String text) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Text(text),
        ),
      ],
    );
  }
}