import 'package:flutter/material.dart';

class IncomeListScreen extends StatefulWidget {
  const IncomeListScreen({super.key});

  @override
  IncomeListScreenState createState() => IncomeListScreenState();
}

class IncomeListScreenState extends State<IncomeListScreen> {
  // Dummy data for incomes
  final List<Map<String, dynamic>> _incomes = [
    {
      'id': '1',
      'title': 'Salary',
      'amount': 4500.00,
      'date': '2025-03-15',
      'category': 'Salary',
      'description': 'Monthly salary',
    },
    {
      'id': '2',
      'title': 'Freelance Project',
      'amount': 600.00,
      'date': '2025-03-10',
      'category': 'Freelance',
      'description': 'Website development',
    },
    {
      'id': '3',
      'title': 'Dividend',
      'amount': 140.00,
      'date': '2025-03-05',
      'category': 'Investment',
      'description': 'Stock dividend',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Income'),
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
      body: _incomes.isEmpty
          ? _buildEmptyState()
          : _buildIncomeList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add_income');
        },
        tooltip: 'Add Income',
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
            'No income recorded yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap the + button to add your first income',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeList() {
    return ListView.builder(
      itemCount: _incomes.length,
      itemBuilder: (context, index) {
        final income = _incomes[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getCategoryColor(income['category']),
              child: Icon(
                _getCategoryIcon(income['category']),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(income['title']),
            subtitle: Text(
              '${_formatDate(income['date'])} · ${income['category']}',
            ),
            trailing: Text(
              'RM ${income['amount'].toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            onTap: () {
              // Navigate to edit income screen with the income id
              Navigator.pushNamed(
                context,
                '/edit_income',
                arguments: {'id': income['id']},
              );
            },
          ),
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Salary':
        return Colors.green;
      case 'Freelance':
        return Colors.blue;
      case 'Investment':
        return Colors.purple;
      case 'Gift':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Salary':
        return Icons.account_balance;
      case 'Freelance':
        return Icons.work;
      case 'Investment':
        return Icons.trending_up;
      case 'Gift':
        return Icons.card_giftcard;
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