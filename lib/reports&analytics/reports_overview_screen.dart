import 'package:flutter/material.dart';

class ReportsOverviewScreen extends StatelessWidget {
  const ReportsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports & Analytics'),
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
        child: Column(
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
                _buildSummaryItem('Income', 'RM 5,240.00', Colors.green),
                _buildSummaryItem('Expense', 'RM 1,659.58', Colors.red),
                _buildSummaryItem('Savings', 'RM 3,580.42', Colors.blue),
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
              'Custom Filters',
              Icons.filter_alt,
              Colors.blue,
              '/filter',
            ),
            _buildReportCard(
              context,
              'Export Reports',
              Icons.download,
              Colors.teal,
              '/export',
            ),
            _buildReportCard(
              context,
              'Budget Analysis',
              Icons.pie_chart,
              Colors.amber,
              '/budget_overview',
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
}