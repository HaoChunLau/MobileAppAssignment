import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app_assignment/models/transaction_model.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

class IncomeListScreen extends StatefulWidget {
  const IncomeListScreen({super.key});

  @override
  IncomeListScreenState createState() => IncomeListScreenState();
}

class IncomeListScreenState extends State<IncomeListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  late Query _query;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeQuery();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _initializeQuery() {
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    
    _query = _firestore
        .collection('transactions')
        .where('userId', isEqualTo: _auth.currentUser?.uid)
        .where('isExpense', isEqualTo: false)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(lastDayOfMonth))
        .orderBy('date', descending: true);
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showMonthPicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _initializeQuery();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Income - ${DateFormat('MMM yyyy').format(_selectedDate)}'),
        automaticallyImplyLeading: false, // Remove back arrow
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectMonth(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data?.docs.isEmpty ?? true) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  itemCount: snapshot.data?.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data?.docs[index];
                    final transaction = TransactionModel.fromFirestore(doc!);
                    return _buildIncomeItem(transaction, doc.id);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add_income');
        },
        tooltip: 'Add Income',
        child: const Icon(Icons.add),
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
          const SizedBox(height: 16),
          const Text(
            'No income recorded yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
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

  Widget _buildIncomeItem(TransactionModel transaction, String docId) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(transaction.category),
          child: Icon(
            _getCategoryIcon(transaction.category),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(transaction.title),
        subtitle: Text(
          '${_formatDate(transaction.date)} · ${transaction.category}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'RM ${transaction.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              tooltip: 'Edit Income',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/edit_income',
                  arguments: {'id': docId, 'transaction': transaction},
                );
              },
            ),
          ],
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(transaction.title),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Amount: RM ${transaction.amount.toStringAsFixed(2)}'),
                  Text('Date: ${_formatDate(transaction.date)}'),
                  Text('Category: ${transaction.category}'),
                  if (transaction.notes != null)
                    Text('Description: ${transaction.notes!}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
      ),
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
      case 'Bonus':
        return Colors.amber;
      case 'Dividend':
        return Colors.teal;
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
      case 'Bonus':
        return Icons.star;
      case 'Dividend':
        return Icons.attach_money;
      default:
        return Icons.attach_money;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == now.year && 
               date.month == now.month && 
               date.day == now.day - 1) {
      return 'Yesterday';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}