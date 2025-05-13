import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app_assignment/models/transaction_model.dart';
import 'package:mobile_app_assignment/utils/category_utils.dart';
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

  // Data for Net Savings Tab
  double _netSavingsRate = 0.0;
  double _avgNetSavingsRate = 0.0;
  Map<String, double> _netSavingsByMonth = {};

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
      spendingCategories['Other'] = 0.0; // Explicitly add "Other" for invalid categories
      Map<String, double> incomeSources = {
        for (var category in CategoryUtils.incomeCategories) category: 0.0
      };
      incomeSources['Other'] = 0.0; // Explicitly add "Other" for invalid categories
      Map<String, double> spendingByDay = {
        'Mon': 0.0,
        'Tue': 0.0,
        'Wed': 0.0,
        'Thu': 0.0,
        'Fri': 0.0,
        'Sat': 0.0,
        'Sun': 0.0
      };
      Map<String, double> netSavingsByMonth = {};

      for (int i = 0; i < monthsInRange; i++) {
        DateTime month = DateTime(endDate.year, endDate.month - i, 1);
        netSavingsByMonth[DateFormat('MMM').format(month)] = 0.0;
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
        if (netSavingsByMonth.containsKey(monthKey)) {
          if (isExpense) {
            netSavingsByMonth[monthKey] = netSavingsByMonth[monthKey]! - amount;
          } else {
            netSavingsByMonth[monthKey] = netSavingsByMonth[monthKey]! + amount;
          }
        }
      }

      double avgDailySpending = daysInRange > 0 ? totalExpense / daysInRange : 0.0;
      double avgMonthlyIncome = monthsInRange > 0 ? totalIncome / monthsInRange : 0.0;
      double netSavingsRate = (totalIncome > 0) ? (totalIncome - totalExpense) / totalIncome : 0.0;

      double maxSpendingDay = spendingByDay.values.reduce((a, b) => a > b ? a : b);
      if (maxSpendingDay > 0) {
        spendingByDay.updateAll((key, value) => value / maxSpendingDay);
      }

      double avgNetSavingsRate = 0.0;
      int validMonths = 0;
      netSavingsByMonth.forEach((month, savings) {
        if (totalIncome > 0) {
          double rate = savings / totalIncome;
          netSavingsByMonth[month] = rate.clamp(0.0, 1.0);
          avgNetSavingsRate += rate;
          validMonths++;
        } else {
          netSavingsByMonth[month] = 0.0;
        }
      });
      avgNetSavingsRate = validMonths > 0 ? avgNetSavingsRate / validMonths : 0.0;

      setState(() {
        _totalSpending = totalExpense;
        _avgDailySpending = avgDailySpending;
        _spendingCategories = spendingCategories;
        _spendingByDay = spendingByDay;
        _totalIncome = totalIncome;
        _avgMonthlyIncome = avgMonthlyIncome;
        _incomeSources = incomeSources;
        _netSavingsRate = netSavingsRate.clamp(0.0, 1.0);
        _avgNetSavingsRate = avgNetSavingsRate.clamp(0.0, 1.0);
        _netSavingsByMonth = netSavingsByMonth;
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
            Tab(text: 'Net Savings'),
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
                      _buildNetSavingsTab(),
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

  Widget _buildNetSavingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNetSavingsProgressCard(),
          SizedBox(height: 20),
          _buildNetSavingsByMonthCard(),
        ],
      ),
    );
  }

  void _showGraphExplanation(BuildContext context, String title, String explanation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(explanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
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
            Row(
              children: [
                Text(
                  'Spending Trends',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
                  onPressed: () => _showGraphExplanation(
                    context,
                    'Spending Trends',
                    'This graph compares your total spending for the selected period to your average daily spending, projected over a month. It helps you see if your spending is trending higher or lower than usual. Use this to understand your overall spending pattern and identify if you’re overspending.',
                  ),
                ),
              ],
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
            Row(
              children: [
                Text(
                  'Top Spending Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
                  onPressed: () => _showGraphExplanation(
                    context,
                    'Top Spending Categories',
                    'This pie chart shows how your spending is distributed across categories (e.g., Food, Transport). Each slice represents a category’s percentage of your total spending. It highlights where most of your money goes, helping you spot areas to cut back.',
                  ),
                ),
              ],
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
                                      color: CategoryUtils.getCategoryColor(entry.key),
                                      value: entry.value,
                                      title: '${(entry.value / _totalSpending * 100).toStringAsFixed(1)}%',
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
                                      color: CategoryUtils.getCategoryColor(entry.key),
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
            Row(
              children: [
                Text(
                  'Spending by Day of Week',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
                  onPressed: () => _showGraphExplanation(
                    context,
                    'Spending by Day of Week',
                    'This graph shows your spending for each day of the week, normalized to compare days. Higher points indicate days you spend more. It helps you identify which days you tend to spend more, so you can plan better.',
                  ),
                ),
              ],
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
                            isCurved: false,
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
            Row(
              children: [
                Text(
                  'Income Trends',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
                  onPressed: () => _showGraphExplanation(
                    context,
                    'Income Trends',
                    'This graph compares your total income for the selected period to your average monthly income. It shows if your income is above or below your usual level. Use this to track your income stability and plan your budget.',
                  ),
                ),
              ],
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
            Row(
              children: [
                Text(
                  'Income Sources',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
                  onPressed: () => _showGraphExplanation(
                    context,
                    'Income Sources',
                    'This pie chart shows where your income comes from (e.g., Salary, Freelance). Each slice represents a source’s percentage of your total income. It helps you understand your income diversity and reliance on specific sources.',
                  ),
                ),
              ],
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
                          color: Colors.grey[600],
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
                                      color: CategoryUtils.getCategoryColor(entry.key),
                                      value: entry.value,
                                      title: '${(entry.value / _totalIncome * 100).toStringAsFixed(1)}%',
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
                                      color: CategoryUtils.getCategoryColor(entry.key),
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

  Widget _buildNetSavingsProgressCard() {
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
            Row(
              children: [
                Text(
                  'Net Savings Rate',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
                  onPressed: () => _showGraphExplanation(
                    context,
                    'Net Savings Rate',
                    'This shows your savings rate, calculated as (Income - Expenses) / Income, for the current period and your average over time. A higher percentage means you’re saving more of your income. It measures how much of your income you’re saving, helping you gauge your financial health.',
                  ),
                ),
              ],
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
                              '${(_netSavingsRate * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: _netSavingsRate,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
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
                              '${(_avgNetSavingsRate * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: _avgNetSavingsRate,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
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

  Widget _buildNetSavingsByMonthCard() {
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
            Row(
              children: [
                Text(
                  'Net Savings by Month',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
                  onPressed: () => _showGraphExplanation(
                    context,
                    'Net Savings by Month',
                    'This graph shows your savings rate for each month in the selected period. Each point represents a month’s savings rate as a percentage of income. It helps you track how your savings rate changes over time, so you can improve your saving habits.',
                  ),
                ),
              ],
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
                                final months = _netSavingsByMonth.keys.toList();
                                if (value.toInt() < months.length) {
                                  return Text(
                                    months[value.toInt()],
                                    style: TextStyle(fontSize: 12, color: Colors.black),
                                  );
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
                            spots: _netSavingsByMonth.entries.map((entry) {
                              final index = _netSavingsByMonth.keys.toList().indexOf(entry.key);
                              return FlSpot(index.toDouble(), entry.value * 100);
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

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
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