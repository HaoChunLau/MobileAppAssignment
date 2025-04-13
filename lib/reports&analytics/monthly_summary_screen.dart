import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthlySummaryScreen extends StatefulWidget {
  const MonthlySummaryScreen({super.key});

  @override
  MonthlySummaryScreenState createState() => MonthlySummaryScreenState();
}

class MonthlySummaryScreenState extends State<MonthlySummaryScreen> {
  DateTime _selectedMonth = DateTime.now();
  
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
            _buildMonthlySummaryCard(),
            SizedBox(height: 20),
            _buildMonthlyChart(),
            SizedBox(height: 20),
            _buildCategoryBreakdown(),
            SizedBox(height: 20),
            _buildMonthlyInsights(),
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
                });
              },
            ),
            GestureDetector(
              onTap: () async {
                // Show month picker dialog
                showMonthPicker(context);
              },
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
                    nextMonth.month == DateTime.now().month && 
                    nextMonth.year == DateTime.now().year) {
                  setState(() {
                    _selectedMonth = nextMonth;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void showMonthPicker(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select Month"),
          content: SizedBox(
            height: 300,
            width: 300,
            child: CalendarDatePicker(
              initialDate: _selectedMonth,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              currentDate: _selectedMonth,
              onDateChanged: (DateTime dateTime) {
                setState(() {
                  _selectedMonth = DateTime(dateTime.year, dateTime.month, 1);
                });
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthlySummaryCard() {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem('Income', 'RM 5,240.00', Colors.green),
                _buildSummaryItem('Expense', 'RM 1,659.58', Colors.red),
                _buildSummaryItem('Savings', 'RM 3,580.42', Colors.blue),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem('Budget', 'RM 2,000.00', Colors.purple),
                _buildSummaryItem('vs Budget', '83% of budget', Colors.orange),
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
                          _buildChartBar('Income', 0.75, Colors.green),
                          _buildChartBar('Expense', 0.25, Colors.red),
                          _buildChartBar('Savings', 0.5, Colors.blue),
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
      height: 150 * value,
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
    // This would be dynamic data in a real app
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
            child: Column(
              children: [
                _buildCategoryItem('Food & Drinks', 'RM 624.80', 0.38, Colors.orange),
                SizedBox(height: 12),
                _buildCategoryItem('Transportation', 'RM 324.50', 0.20, Colors.blue),
                SizedBox(height: 12),
                _buildCategoryItem('Entertainment', 'RM 487.28', 0.29, Colors.purple),
                SizedBox(height: 12),
                _buildCategoryItem('Utilities', 'RM 223.00', 0.13, Colors.green),
              ],
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

  Widget _buildMonthlyInsights() {
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
            child: Column(
              children: [
                _buildInsightItem(
                  Icons.trending_down,
                  Colors.green,
                  'Your food expenses are 8% lower than last month.',
                ),
                Divider(height: 24),
                _buildInsightItem(
                  Icons.trending_up,
                  Colors.red,
                  'Entertainment spending increased by 15% this month.',
                ),
                Divider(height: 24),
                _buildInsightItem(
                  Icons.savings,
                  Colors.blue,
                  'You\'ve saved 68% of your income this month - great job!',
                ),
              ],
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
            color: color.withOpacity(0.1),
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