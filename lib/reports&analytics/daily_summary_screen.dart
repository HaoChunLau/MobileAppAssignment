import 'package:flutter/material.dart';

class DailySummaryScreen extends StatelessWidget {
  const DailySummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Daily Summary")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Daily Expense & Income Summary",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildSummaryItem("Total Expenses", 150.0, Colors.red),
            _buildSummaryItem("Total Income", 200.0, Colors.green),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildTransactionItem("Food - Breakfast", -10.0, "8:00 AM"),
                  _buildTransactionItem("Transport - Bus", -2.5, "9:00 AM"),
                  _buildTransactionItem("Salary", 200.0, "10:00 AM"),
                  _buildTransactionItem("Shopping - Clothes", -50.0, "2:00 PM"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            "RM${amount.toStringAsFixed(2)}",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(String title, double amount, String time) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(time),
        trailing: Text(
          "RM${amount.toStringAsFixed(2)}",
          style: TextStyle(
            color: amount < 0 ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
