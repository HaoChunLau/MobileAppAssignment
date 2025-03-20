import 'package:flutter/material.dart';
import 'package:mobile_app_assignment/expense&income_tracking/add_income_screen.dart';
import 'package:mobile_app_assignment/expense&income_tracking/edit_income_screen.dart';

class IncomeListScreen extends StatefulWidget {
  const IncomeListScreen({super.key});

  @override
  IncomeListScreenState createState() => IncomeListScreenState();
}

class IncomeListScreenState extends State<IncomeListScreen> {
  List<Map<String, dynamic>> incomes = [
    {"category": "Salary", "amount": 2000.0, "description": "Monthly Salary", "date": DateTime.now()},
    {"category": "Allowance", "amount": 500.0, "description": "Weekly Allowance", "date": DateTime.now()},
    {"category": "Bonus", "amount": 300.0, "description": "Performance Bonus", "date": DateTime.now()},
  ];

  void _deleteIncome(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: const Text("Are you sure you want to delete this income record?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  incomes.removeAt(index);
                });
                Navigator.of(context).pop();
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Income List")),
      body: ListView.builder(
        itemCount: incomes.length,
        itemBuilder: (context, index) {
          final income = incomes[index];
          return ListTile(
            leading: const Icon(Icons.monetization_on, color: Colors.blue),
            title: Text("Income RM${income["amount"]}"),
            subtitle: Text("Category: ${income["category"]}, Description: ${income["description"]}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.green),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditIncomeScreen(
                          category: income["category"],
                          amount: income["amount"],
                          description: income["description"],
                          date: income["date"],
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteIncome(index),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddIncomeScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
