import 'package:flutter/material.dart';

class BudgetSettingScreen extends StatefulWidget {
  const BudgetSettingScreen({super.key});

  @override
  BudgetSettingScreenState createState() => BudgetSettingScreenState();
}

class BudgetSettingScreenState extends State<BudgetSettingScreen> {
  final Map<String, TextEditingController> _budgetControllers = {
    "Food": TextEditingController(),
    "Transport": TextEditingController(),
    "Shopping": TextEditingController(),
    "Bills": TextEditingController(),
  };

  @override
  void dispose() {
    for (var controller in _budgetControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Set Budget")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Set Monthly Budget for Each Category",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ..._budgetControllers.keys.map((category) => _buildBudgetField(category)),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Save budget settings logic will be implemented later
                  Navigator.pop(context);
                },
                child: const Text("Save Budget"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetField(String category) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: _budgetControllers[category],
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: "$category Budget (RM)",
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
