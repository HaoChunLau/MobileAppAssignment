import 'package:flutter/material.dart';
import 'package:mobile_app_assignment/expense&income_tracking/add_expense_screen.dart';
import 'package:mobile_app_assignment/expense&income_tracking/edit_expense_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ExpenseListScreenState createState() => ExpenseListScreenState();
}

class ExpenseListScreenState extends State<ExpenseListScreen> {
  List<Map<String, dynamic>> expenses = [
    {"category": "Food", "subcategory": "Breakfast", "amount": 10.0, "description": "Egg sandwich", "date": DateTime.now()},
    {"category": "Transport", "subcategory": "Bus", "amount": 2.5, "description": "Bus fare", "date": DateTime.now()},
    {"category": "Shopping", "subcategory": "Clothes", "amount": 50.0, "description": "New T-shirt", "date": DateTime.now()},
  ];

  void _deleteExpense(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: const Text("Are you sure you want to delete this expense?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  expenses.removeAt(index);
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
      appBar: AppBar(title: const Text("Expense List")),
      body: ListView.builder(
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          final expense = expenses[index];
          return ListTile(
            leading: const Icon(Icons.attach_money, color: Colors.green),
            title: Text("Expense RM${expense["amount"]}"),
            subtitle: Text("Category: ${expense["category"]}, Subcategory: ${expense["subcategory"]}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditExpenseScreen(
                          category: expense["category"],
                          subcategory: expense["subcategory"],
                          amount: expense["amount"],
                          description: expense["description"],
                          date: expense["date"],
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteExpense(index),
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
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
