import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app_assignment/models/transaction_model.dart';
import 'package:mobile_app_assignment/category_utils.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  AnalyticsScreenState createState() => AnalyticsScreenState();
}

class AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _timeRange = 'This Month';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String _errorMessage = '';

  // Data for Spending Tab
  double _totalSpending = 0.0;
  double _avgDailySpending = 0.0;
  Map<String, double> _spendingCategories = {};
  Map<String, double> _spendingByDay = {};

  // Data for Income Tab
  double _totalIncome = 0.0;
  double _avgMonthlyIncome = 0.0;
  Map<String, double> _incomeSources = {};

  // Data for Savings Tab
  double _savingsRate = 0.0;
  double _avgSavingsRate = 0.0;
  Map<String, double> _savingsByMonth = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
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

    try {
      DateTime startDate;
      DateTime endDate = DateTime.now();
      int daysInRange = 0;
      int monthsInRange = 0;

      switch (_timeRange) {
        case 'This Week':
          startDate = endDate.subtract(Duration(days: endDate.weekday - 1));
          daysInRange = (endDate.difference(startDate).inDays) + 1;
          break;
        case 'This Month':
          startDate = DateTime(endDate.year, endDate.month, 1);
          daysInRange = endDate.day;
          monthsInRange = 1;
          break;
        case 'Last Month':
          startDate = DateTime(endDate.year, endDate.month - 1, 1);
          endDate = DateTime(endDate.year, endDate.month, 0);
          daysInRange = endDate.day;
          monthsInRange = 1;
          break;
        case 'Last 3 Months':
          startDate = DateTime(endDate.year, endDate.month - 2, 1);
          daysInRange = endDate.difference(startDate).inDays + 1;
          monthsInRange = 3;
          break;
        case 'Last 6 Months':
          startDate = DateTime(endDate.year, endDate.month - 5, 1);
          daysInRange = endDate.difference(startDate).inDays + 1;
          monthsInRange = 6;
          break;
        case 'This Year':
          startDate = DateTime(endDate.year, 1, 1);
          daysInRange = endDate.difference(startDate).inDays + 1;
          monthsInRange = endDate.month;
          break;
        default:
          startDate = DateTime(endDate.year, endDate.month, 1);
          daysInRange = endDate.day;
          monthsInRange = 1;
      }

      final querySnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      double totalIncome = 0.0;
      double totalExpense = 0.0;
      Map<String, double> spendingCategories = {
        for (var category in CategoryUtils.expenseCategories) category: 0.0
      };
      spendingCategories['Other'] =
          0.0; // Explicitly add "Other" for invalid categories
      Map<String, double> incomeSources = {
        for (var category in CategoryUtils.incomeCategories) category: 0.0
      };
      incomeSources['Other'] =
          0.0; // Explicitly add "Other" for invalid categories
      Map<String, double> spendingByDay = {
        'Mon': 0.0,
        'Tue': 0.0,
        'Wed': 0.0,
        'Thu': 0.0,
        'Fri': 0.0,
        'Sat': 0.0,
        'Sun': 0.0
      };
      Map<String, double> savingsByMonth = {};

      for (int i = 0; i < monthsInRange; i++) {
        DateTime month = DateTime(endDate.year, endDate.month - i, 1);
        savingsByMonth[DateFormat('MMM').format(month)] = 0.0;
      }

      for (var doc in querySnapshot.docs) {
        final transaction = TransactionModel.fromFirestore(doc);
        final amount = transaction.amount;
        final isExpense = transaction.isExpense;
        final date = transaction.date;

        if (isExpense) {
          totalExpense += amount;
          if (spendingCategories.containsKey(transaction.category)) {
            spendingCategories[transaction.category] =
                spendingCategories[transaction.category]! + amount;
          } else {
            spendingCategories['Other'] = spendingCategories['Other']! + amount;
          }
          String dayOfWeek = DateFormat('E').format(date).substring(0, 3);
          spendingByDay[dayOfWeek] = spendingByDay[dayOfWeek]! + amount;
        } else {
          totalIncome += amount;
          String source = transaction.category;
          if (incomeSources.containsKey(source)) {
            incomeSources[source] = incomeSources[source]! + amount;
          } else {
            incomeSources['Other'] = incomeSources['Other']! + amount;
          }
        }

        String monthKey = DateFormat('MMM').format(date);
        if (savingsByMonth.containsKey(monthKey)) {
          if (isExpense) {
            savingsByMonth[monthKey] = savingsByMonth[monthKey]! - amount;
          } else {
            savingsByMonth[monthKey] = savingsByMonth[monthKey]! + amount;
          }
        }
      }

      double avgDailySpending =
          daysInRange > 0 ? totalExpense / daysInRange : 0.0;
      double avgMonthlyIncome =
          monthsInRange > 0 ? totalIncome / monthsInRange : 0.0;
      double savingsRate =
          (totalIncome > 0) ? (totalIncome - totalExpense) / totalIncome : 0.0;

      double maxSpendingDay =
          spendingByDay.values.reduce((a, b) => a > b ? a : b);
      if (maxSpendingDay > 0) {
        spendingByDay.updateAll((key, value) => value / maxSpendingDay);
      }

      double avgSavingsRate = 0.0;
      int validMonths = 0;
      savingsByMonth.forEach((month, savings) {
        if (totalIncome > 0) {
          double rate = savings / totalIncome;
          savingsByMonth[month] = rate.clamp(0.0, 1.0);
          avgSavingsRate += rate;
          validMonths++;
        } else {
          savingsByMonth[month] = 0.0;
        }
      });
      avgSavingsRate = validMonths > 0 ? avgSavingsRate / validMonths : 0.0;

      setState(() {
        _totalSpending = totalExpense;
        _avgDailySpending = avgDailySpending;
        _spendingCategories = spendingCategories;
        _spendingByDay = spendingByDay;
        _totalIncome = totalIncome;
        _avgMonthlyIncome = avgMonthlyIncome;
        _incomeSources = incomeSources;
        _savingsRate = savingsRate.clamp(0.0, 1.0);
        _avgSavingsRate = avgSavingsRate.clamp(0.0, 1.0);
        _savingsByMonth = savingsByMonth;
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
        title: Text('Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Spending'),
            Tab(text: 'Income'),
            Tab(text: 'Savings'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildTimeRangeSelector(),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSpendingTab(),
                      _buildIncomeTab(),
                      _buildSavingsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Time Range',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        value: _timeRange,
        items: [
          'This Week',
          'This Month',
          'Last Month',
          'Last 3 Months',
          'Last 6 Months',
          'This Year'
        ].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            _timeRange = newValue!;
            _fetchData();
          });
        },
      ),
    );
  }

  Widget _buildSpendingTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSpendingTrendsCard(),
          SizedBox(height: 20),
          _buildTopCategoriesCard(),
          SizedBox(height: 20),
          _buildSpendingByDayCard(),
        ],
      ),
    );
  }

  Widget _buildIncomeTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIncomeTrendsCard(),
          SizedBox(height: 20),
          _buildIncomeSourcesCard(),
        ],
      ),
    );
  }

  Widget _buildSavingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSavingsProgressCard(),
          SizedBox(height: 20),
          _buildSavingsByMonthCard(),
          SizedBox(height: 20),
          _buildSavingsGoalsCard(),
        ],
      ),
    );
  }

  Widget _buildSpendingTrendsCard() {
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
              'Spending Trends',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _totalSpending == 0.0
                ? Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No spending recorded for this period',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: [
                                  FlSpot(0, _totalSpending),
                                  FlSpot(1, _avgDailySpending * 30),
                                ],
                                isCurved: true,
                                color: Colors.red,
                                barWidth: 2,
                                dotData: FlDotData(show: true),
                              ),
                            ],
                            minY: 0,
                            maxY: (_totalSpending > _avgDailySpending * 30
                                    ? _totalSpending
                                    : _avgDailySpending * 30) *
                                1.1,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem(
                              'Total Spent',
                              'RM ${_totalSpending.toStringAsFixed(2)}',
                              Icons.payments,
                              Colors.red),
                          _buildStatItem(
                              'Avg Daily',
                              'RM ${_avgDailySpending.toStringAsFixed(2)}',
                              Icons.date_range,
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

  Widget _buildTopCategoriesCard() {
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
              'Top Spending Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _totalSpending == 0.0
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
                          'No expenses recorded for this period',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: _spendingCategories.entries
                                .where((entry) => entry.value > 0)
                                .map((entry) => PieChartSectionData(
                                      color: CategoryUtils.getCategoryColor(
                                          entry.key),
                                      value: entry.value,
                                      title:
                                          '${(entry.value / _totalSpending * 100).toStringAsFixed(1)}%',
                                      radius: 80,
                                      titleStyle: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ))
                                .toList(),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: _spendingCategories.entries
                            .where((entry) => entry.value > 0)
                            .map((entry) => Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      color: CategoryUtils.getCategoryColor(
                                          entry.key),
                                    ),
                                    SizedBox(width: 4),
                                    Text(entry.key),
                                  ],
                                ))
                            .toList(),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingByDayCard() {
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
              'Spending by Day of Week',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _totalSpending == 0.0
                ? Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.bar_chart_outlined,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No spending data for this period',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const style = TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                );
                                switch (value.toInt()) {
                                  case 0:
                                    return Text('Mon', style: style);
                                  case 1:
                                    return Text('Tue', style: style);
                                  case 2:
                                    return Text('Wed', style: style);
                                  case 3:
                                    return Text('Thu', style: style);
                                  case 4:
                                    return Text('Fri', style: style);
                                  case 5:
                                    return Text('Sat', style: style);
                                  case 6:
                                    return Text('Sun', style: style);
                                  default:
                                    return Text('');
                                }
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              FlSpot(0, _spendingByDay['Mon']! * 100),
                              FlSpot(1, _spendingByDay['Tue']! * 100),
                              FlSpot(2, _spendingByDay['Wed']! * 100),
                              FlSpot(3, _spendingByDay['Thu']! * 100),
                              FlSpot(4, _spendingByDay['Fri']! * 100),
                              FlSpot(5, _spendingByDay['Sat']! * 100),
                              FlSpot(6, _spendingByDay['Sun']! * 100),
                            ],
                            isCurved:
                                false, // Changed to false for straight lines
                            color: Colors.blue,
                            barWidth: 2,
                            dotData: FlDotData(show: true),
                          ),
                        ],
                        minY: 0,
                        maxY: 100,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeTrendsCard() {
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
              'Income Trends',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _totalIncome == 0.0
                ? Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No income recorded for this period',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: [
                                  FlSpot(0, _totalIncome),
                                  FlSpot(1, _avgMonthlyIncome),
                                ],
                                isCurved: true,
                                color: Colors.green,
                                barWidth: 2,
                                dotData: FlDotData(show: true),
                              ),
                            ],
                            minY: 0,
                            maxY: (_totalIncome > _avgMonthlyIncome
                                    ? _totalIncome
                                    : _avgMonthlyIncome) *
                                1.1,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem(
                              'Total Income',
                              'RM ${_totalIncome.toStringAsFixed(2)}',
                              Icons.account_balance,
                              Colors.green),
                          _buildStatItem(
                              'Monthly Avg',
                              'RM ${_avgMonthlyIncome.toStringAsFixed(2)}',
                              Icons.calendar_today,
                              Colors.blue),
                        ],
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeSourcesCard() {
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
              'Income Sources',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _totalIncome == 0.0
                ? Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance,
                          size: 24,
                          color: Colors.grey[400],
                        ),
                        SizedBox(width: 8),
                        Text(
                          'No income recorded for this period',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: _incomeSources.entries
                                .where((entry) => entry.value > 0)
                                .map((entry) => PieChartSectionData(
                                      color: CategoryUtils.getCategoryColor(
                                          entry.key),
                                      value: entry.value,
                                      title:
                                          '${(entry.value / _totalIncome * 100).toStringAsFixed(1)}%',
                                      radius: 80,
                                      titleStyle: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ))
                                .toList(),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: _incomeSources.entries
                            .where((entry) => entry.value > 0)
                            .map((entry) => Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      color: CategoryUtils.getCategoryColor(
                                          entry.key),
                                    ),
                                    SizedBox(width: 4),
                                    Text(entry.key),
                                  ],
                                ))
                            .toList(),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsProgressCard() {
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
              'Savings Rate',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            (_totalIncome == 0.0 && _totalSpending == 0.0)
                ? Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.savings_outlined,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No transactions recorded for this period',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'This Period',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${(_savingsRate * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: _savingsRate,
                              backgroundColor: Colors.grey[200],
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.green),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Average',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${(_avgSavingsRate * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: _avgSavingsRate,
                              backgroundColor: Colors.grey[200],
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.blue),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsByMonthCard() {
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
              'Savings by Month',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            (_totalIncome == 0.0 && _totalSpending == 0.0)
                ? Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.bar_chart_outlined,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No savings data for this period',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final months = _savingsByMonth.keys.toList();
                                if (value.toInt() < months.length) {
                                  return Text(months[value.toInt()],
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.black));
                                }
                                return Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _savingsByMonth.entries.map((entry) {
                              final index = _savingsByMonth.keys
                                  .toList()
                                  .indexOf(entry.key);
                              return FlSpot(
                                  index.toDouble(), entry.value * 100);
                            }).toList(),
                            isCurved: true,
                            color: Colors.green,
                            barWidth: 2,
                            dotData: FlDotData(show: true),
                          ),
                        ],
                        minY: 0,
                        maxY: 100,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsGoalsCard() {
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
              'Savings Goals Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Savings goals feature coming soon!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Row(
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
              size: 20,
            ),
          ),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
