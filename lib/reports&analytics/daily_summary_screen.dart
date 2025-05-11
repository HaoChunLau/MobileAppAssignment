import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app_assignment/models/transaction_model.dart';
import 'package:mobile_app_assignment/category_utils.dart';

class DailySummaryScreen extends StatefulWidget {
  const DailySummaryScreen({super.key});

  @override
  DailySummaryScreenState createState() => DailySummaryScreenState();
}

class DailySummaryScreenState extends State<DailySummaryScreen> {
  DateTime _selectedDate = DateTime.now();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  double _income = 0.0;
  double _expense = 0.0;
  double _balance = 0.0;
  List<Map<String, dynamic>> _transactions = [];
  Map<String, double> _categoryBreakdown = {};
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchDailyData();
  }

  Future<void> _fetchDailyData() async {
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

    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

    try {
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      double totalIncome = 0.0;
      double totalExpense = 0.0;
      List<Map<String, dynamic>> transactions = [];
      Map<String, double> categoryTotals = {
        for (var category in CategoryUtils.expenseCategories) category: 0.0
      };

      for (var doc in querySnapshot.docs) {
        final transaction = TransactionModel.fromFirestore(doc);
        final amount = transaction.amount;
        final category = transaction.category;
        final isExpense = transaction.isExpense;

        // Add transaction to the list for display (without time)
        transactions.add({
          'title': transaction.title,
          'amount': 'RM ${amount.toStringAsFixed(2)}',
          'icon': CategoryUtils.getCategoryIcon(category),
          'color': CategoryUtils.getCategoryColor(category),
          'isExpense': isExpense,
        });

        // Calculate totals
        if (isExpense) {
          totalExpense += amount;
          if (categoryTotals.containsKey(category)) {
            categoryTotals[category] = categoryTotals[category]! + amount;
          } else {
            categoryTotals['Other'] = categoryTotals['Other']! + amount;
          }
        } else {
          totalIncome += amount;
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

      setState(() {
        _income = totalIncome;
        _expense = totalExpense;
        _balance = totalIncome - totalExpense;
        _transactions = transactions;
        _categoryBreakdown = breakdown;
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
        title: Text('Daily Summary'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateSelector(),
            SizedBox(height: 20),
            _buildSummaryCard(),
            SizedBox(height: 20),
            _buildDailyTransactions(context),
            SizedBox(height: 20),
            _buildCategoryBreakdown(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
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
                  _selectedDate = _selectedDate.subtract(Duration(days: 1));
                  _fetchDailyData();
                });
              },
            ),
            GestureDetector(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null && picked != _selectedDate) {
                  setState(() {
                    _selectedDate = picked;
                    _fetchDailyData();
                  });
                }
              },
              child: Column(
                children: [
                  Text(
                    DateFormat('EEEE').format(_selectedDate),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('MMMM d, y').format(_selectedDate),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward_ios),
              onPressed: () {
                final tomorrow = DateTime.now().add(Duration(days: 1));
                if (_selectedDate.isBefore(tomorrow)) {
                  setState(() {
                    _selectedDate = _selectedDate.add(Duration(days: 1));
                    _fetchDailyData();
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
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
              'Daily Summary',
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
                              'No transactions recorded for this day',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSummaryItem(
                              'Income', 'RM ${_income.toStringAsFixed(2)}', Colors.green),
                          _buildSummaryItem(
                              'Expense', 'RM ${_expense.toStringAsFixed(2)}', Colors.red),
                          _buildSummaryItem(
                              'Balance',
                              '${_balance >= 0 ? '' : '-'}RM ${_balance.abs().toStringAsFixed(2)}',
                              Colors.blue),
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

  Widget _buildDailyTransactions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transactions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        _transactions.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No transactions for this day',
                        style: TextStyle(color: Colors.grey[600]),
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
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final transaction = _transactions[index];
                  return Card(
                    elevation: 1,
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: transaction['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          transaction['icon'],
                          color: transaction['color'],
                        ),
                      ),
                      title: Text(transaction['title']),
                      trailing: Text(
                        transaction['amount'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: transaction['isExpense'] ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Breakdown',
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
                          'No expenses recorded for this day',
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
              '$amount (${(percentage * 100).toInt()}%)',
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
          ],
        ),
      ],
    );
  }
}