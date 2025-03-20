import 'package:flutter/material.dart';

class MonthlySummaryScreen extends StatelessWidget {
  const MonthlySummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Monthly Summary")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Monthly Expense & Income Summary",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildSummaryItem("Total Expenses", 3200.0, Colors.red),
            _buildSummaryItem("Total Income", 4500.0, Colors.green),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildTransactionItem("Food", -800.0),
                  _buildTransactionItem("Transport", -300.0),
                  _buildTransactionItem("Salary", 4000.0),
                  _buildTransactionItem("Shopping", -600.0),
                  _buildTransactionItem("Bills", -1500.0),
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

  Widget _buildTransactionItem(String category, double amount) {
    return Card(
      child: ListTile(
        title: Text(category),
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