import 'package:flutter/material.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ExpenseListScreenState createState() => ExpenseListScreenState();
}

class ExpenseListScreenState extends State<ExpenseListScreen> {
  // Dummy data for expenses
  final List<Map<String, dynamic>> _expenses = [
    {
      'id': '1',
      'title': 'Groceries',
      'amount': 85.40,
      'date': '2025-03-21',
      'category': 'Food',
      'description': 'Weekly grocery shopping',
    },
    {
      'id': '2',
      'title': 'Restaurant',
      'amount': 124.80,
      'date': '2025-03-14',
      'category': 'Food',
      'description': 'Dinner with friends',
    },
    {
      'id': '3',
      'title': 'Fuel',
      'amount': 70.00,
      'date': '2025-03-18',
      'category': 'Transportation',
      'description': 'Petrol station',
    },
    {
      'id': '4',
      'title': 'Movie Tickets',
      'amount': 35.00,
      'date': '2025-03-10',
      'category': 'Entertainment',
      'description': 'Weekend movie',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expenses'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              // Navigate to filter screen
              Navigator.pushNamed(context, '/filter');
            },
          ),
        ],
      ),
      body: _expenses.isEmpty
          ? _buildEmptyState()
          : _buildExpenseList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add_expense');
        },
        tooltip: 'Add Expense',
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No expenses recorded yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap the + button to add your first expense',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList() {
    return ListView.builder(
      itemCount: _expenses.length,
      itemBuilder: (context, index) {
        final expense = _expenses[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getCategoryColor(expense['category']),
              child: Icon(
                _getCategoryIcon(expense['category']),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(expense['title']),
            subtitle: Text(
              '${_formatDate(expense['date'])} · ${expense['category']}',
            ),
            trailing: Text(
              'RM ${expense['amount'].toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            onTap: () {
              // Navigate to edit expense screen with the expense id
              Navigator.pushNamed(
                context,
                '/edit_expense',
                arguments: {'id': expense['id']},
              );
            },
          ),
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.orange;
      case 'Transportation':
        return Colors.blue;
      case 'Entertainment':
        return Colors.purple;
      case 'Utilities':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Transportation':
        return Icons.directions_car;
      case 'Entertainment':
        return Icons.movie;
      case 'Utilities':
        return Icons.lightbulb;
      default:
        return Icons.attach_money;
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}