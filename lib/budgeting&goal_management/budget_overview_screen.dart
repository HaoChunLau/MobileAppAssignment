import 'package:flutter/material.dart';
import 'package:mobile_app_assignment/budgeting&goal_management/budget_setting_screen.dart';
import 'package:mobile_app_assignment/budgeting&goal_management/savings_goal_screen.dart';
import 'package:mobile_app_assignment/budgeting&goal_management/savings_progress_screen.dart';

class BudgetOverviewScreen extends StatelessWidget {
  const BudgetOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Budget Overview")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Monthly Budget Overview",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildBudgetItem("Food", 500, 300),
            _buildBudgetItem("Transport", 200, 150),
            _buildBudgetItem("Shopping", 300, 250),
            _buildBudgetItem("Bills", 400, 200),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BudgetSettingScreen()),
                      );
                    },
                    child: const Text("Set Budget"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SavingsGoalScreen()),
                      );
                    },
                    child: const Text("Set Savings Goal"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SavingsProgressScreen()),
                      );
                    },
                    child: const Text("View Savings Progress"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetItem(String category, double budget, double spent) {
    double percentage = spent / budget;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$category: RM$spent / RM$budget"),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: percentage.clamp(0.0, 1.0),
          backgroundColor: Colors.grey[300],
          color: percentage > 0.8 ? Colors.red : Colors.green,
          minHeight: 10,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
