import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app_assignment/utils/category_utils.dart';
import 'package:mobile_app_assignment/models/transaction_model.dart';
import 'package:mobile_app_assignment/models/budget_model.dart';

class ExpenseListScreen extends StatefulWidget {
  final DateTime selectedDate;

  const ExpenseListScreen({super.key, required this.selectedDate});

  @override
  ExpenseListScreenState createState() => ExpenseListScreenState();
}

class ExpenseListScreenState extends State<ExpenseListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  late Query _query;
  _FilterOptions _filterOptions = _FilterOptions();

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

  @override
  void didUpdateWidget(ExpenseListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _initializeQuery();
    }
  }

  void _initializeQuery() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      setState(() {
        _query = _firestore
            .collection('transactions')
            .where('userId', isEqualTo: '');
      });
      return;
    }

    final firstDayOfMonth =
        DateTime(widget.selectedDate.year, widget.selectedDate.month, 1);
    final lastDayOfMonth =
        DateTime(widget.selectedDate.year, widget.selectedDate.month + 1, 0);

    Query query = _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('isExpense', isEqualTo: true)
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(lastDayOfMonth));

    if (_filterOptions.category != null) {
      query = query.where('category', isEqualTo: _filterOptions.category);
    }

    query = query.orderBy('date', descending: true);
    setState(() {
      _query = query;
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final tempFilters = _FilterOptions.from(_filterOptions);
        return AlertDialog(
          title: const Text(
            'Filter Expenses by Category',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String?>(
                  value: tempFilters.category,
                  hint: const Text('Select a category'),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: const TextStyle(color: Colors.blueGrey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Colors.blueGrey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Colors.blueGrey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 2.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('All Categories')),
                    ...CategoryUtils.expenseCategories
                        .map((category) => DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            )),
                  ],
                  onChanged: (value) {
                    tempFilters.category = value;
                  },
                  isExpanded: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _filterOptions = _FilterOptions();
                  _initializeQuery();
                });
                Navigator.pop(context);
              },
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _filterOptions = tempFilters;
                  _initializeQuery();
                });
                Navigator.pop(context);
              },
              child: const Text('Apply', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Expenses - ${DateFormat('MMM yyyy').format(widget.selectedDate)}'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter Expenses',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
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
                          final transaction =
                              TransactionModel.fromFirestore(doc!);
                          return AnimatedOpacity(
                            opacity: 1.0,
                            duration: const Duration(milliseconds: 300),
                            child: _buildExpenseItem(transaction, doc.id),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
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
            semanticLabel: 'No expenses icon',
          ),
          const SizedBox(height: 16),
          const Text(
            'No expenses recorded yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first expense',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/add_expense'),
            icon: const Icon(Icons.add),
            label: const Text('Add Expense'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(TransactionModel transaction, String docId) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: CategoryUtils.getCategoryColor(transaction.category),
          child: Icon(
            CategoryUtils.getCategoryIcon(transaction.category),
            color: Colors.white,
            size: 20,
            semanticLabel: '${transaction.category} icon',
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
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              tooltip: 'Edit Expense',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/edit_expense',
                  arguments: {'id': docId, 'transaction': transaction},
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete Expense',
              onPressed: () => _showDeleteConfirmation(docId, transaction),
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

  void _showDeleteConfirmation(String docId, TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Expense'),
          content: const Text('Are you sure you want to delete this expense?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteExpense(docId, transaction.budgetId);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteExpense(String docId, String? budgetId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final docSnapshot =
          await _firestore.collection('transactions').doc(docId).get();
      if (!docSnapshot.exists) {
        throw Exception('Transaction not found');
      }
      final deletedTransaction = docSnapshot.data()!;

      await _firestore.collection('transactions').doc(docId).delete();

      if (budgetId != null) {
        await _updateBudgetCurrentSpent(budgetId);
      }

      if (!mounted) return;

      HapticFeedback.lightImpact();
      final snackBar = SnackBar(
        content: const Text('Expense deleted successfully'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.purple,
          onPressed: () async {
            await _firestore
                .collection('transactions')
                .doc(docId)
                .set(deletedTransaction);
            if (budgetId != null) {
              await _updateBudgetCurrentSpent(budgetId);
            }
          },
        ),
        duration: const Duration(seconds: 5),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting expense: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.blue,
            onPressed: () {},
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateBudgetCurrentSpent(String budgetId) async {
    final budgetDoc =
        await _firestore.collection('budgets').doc(budgetId).get();
    if (!budgetDoc.exists) return;

    final budget = BudgetModel.fromFirestore(budgetDoc);

    final transactions = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: _auth.currentUser?.uid)
        .where('budgetId', isEqualTo: budgetId)
        .where('isExpense', isEqualTo: true)
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(budget.startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(budget.endDate))
        .get();

    double currentSpent = transactions.docs.fold(0.0, (total, doc) {
      final amount = (doc.data()['amount'] as num).toDouble();
      return total + amount;
    });

    await _firestore.collection('budgets').doc(budgetId).update({
      'currentSpent': currentSpent,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
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

class _FilterOptions {
  String? category;

  _FilterOptions();

  _FilterOptions.from(_FilterOptions other) : category = other.category;
}