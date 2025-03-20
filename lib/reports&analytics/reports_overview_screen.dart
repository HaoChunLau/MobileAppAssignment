import 'package:flutter/material.dart';
import 'package:mobile_app_assignment/reports&analytics/daily_summary_screen.dart';
import 'package:mobile_app_assignment/reports&analytics/monthly_summary_screen.dart';
import 'package:mobile_app_assignment/reports&analytics/filter_screen.dart';
import 'package:mobile_app_assignment/reports&analytics/analytics_screen.dart';
import 'package:mobile_app_assignment/reports&analytics/export_screen.dart';

class ReportsOverviewScreen extends StatelessWidget {
  const ReportsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reports & Analytics")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "View Financial Reports",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DailySummaryScreen()),
                );
              },
              child: const Text("View Daily Summary"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MonthlySummaryScreen()),
                );
              },
              child: const Text("View Monthly Summary"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FilterScreen()),
                );
              },
              child: const Text("Filter Transactions"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
                );
              },
              child: const Text("View Analytics"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExportScreen()),
                );
              },
              child: const Text("Export Data"),
            ),
          ],
        ),
      ),
    );
  }
}