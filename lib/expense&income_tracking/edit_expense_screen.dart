import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app_assignment/utils/category_utils.dart';
import 'package:mobile_app_assignment/models/transaction_model.dart';
import 'package:mobile_app_assignment/models/budget_model.dart';

class EditExpenseScreen extends StatefulWidget {
  const EditExpenseScreen({super.key});

  @override
  EditExpenseScreenState createState() => EditExpenseScreenState();
}

class EditExpenseScreenState extends State<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form field controllers
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;

  late DateTime _selectedDate;
  late String _selectedCategory;
  String? _selectedBudgetId; // Nullable for "No Budget"
  List<BudgetModel> _budgets = []; // List of available budgets

  final List<String> _categories = CategoryUtils.expenseCategories;

  bool _isLoading = true;
  String _expenseId = '';
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _selectedDate = DateTime.now();
    _selectedCategory = 'Food';
    _loadData(); // Load budgets and expense data
  }

  // Load budgets and expense data sequentially
  void _loadData() async {
    try {
      await _fetchBudgets(); // Fetch budgets first
      await _loadExpenseData(); // Then load expense data
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: ${e.toString()}')),
      );
      Navigator.pop(context);
    }
  }

  // Fetch active and failed budgets from Firestore
  Future<void> _fetchBudgets() async {
    try {
      final user = _auth.currentUser!;
      final snapshot = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: user.uid)
          .where('status', whereIn: ['active', 'failed']).get();

      if (mounted) {
        setState(() {
          _budgets = snapshot.docs
              .map((doc) => BudgetModel.fromFirestore(doc))
              .toList();
        });
      }
    } catch (e) {
      throw Exception('Error fetching budgets: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments == null || !arguments.containsKey('id')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: No expense ID provided')),
        );
      });
    } else {
      _expenseId = arguments['id'] as String;
    }
  }

  Future<void> _loadExpenseData() async {
    try {
      final doc =
          await _firestore.collection('transactions').doc(_expenseId).get();
      if (doc.exists) {
        final transaction = TransactionModel.fromFirestore(doc);

        // Validate budgetId
        String? validBudgetId = transaction.budgetId;
        if (validBudgetId != null) {
          final selectedBudget = _budgets.firstWhere(
            (budget) => budget.budgetId == validBudgetId,
            orElse: () => BudgetModel(
              budgetId: '',
              budgetName: '',
              targetAmount: 0.0,
              currentSpent: 0.0,
              budgetCategory: '',
              duration: DurationCategory.weekly, // Default duration
              startDate: DateTime.now(),
              endDate: DateTime.now(),
              userId: '',
              status: Status.active,
            ),
          );
          // Check if budget exists and matches category and date range
          if (selectedBudget.budgetId == '' ||
              selectedBudget.budgetCategory != transaction.category ||
              !transaction.date.isAfter(selectedBudget.startDate
                  .subtract(const Duration(seconds: 1))) ||
              !transaction.date.isBefore(
                  selectedBudget.endDate.add(const Duration(seconds: 1)))) {
            validBudgetId = null; // Reset to null if invalid
          }
        }

        if (mounted) {
          setState(() {
            _titleController.text = transaction.title;
            _amountController.text = transaction.amount.toString();
            _selectedDate = transaction.date;
            _selectedCategory = transaction.category;
            _descriptionController.text = transaction.notes ?? '';
            _selectedBudgetId = validBudgetId;
            _isLoading = false;
            _dataLoaded = true;
          });
        }
      } else {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Expense not found')),
        );
      }
    } catch (e) {
      throw Exception('Error loading expense: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Expense')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title field
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g., Grocery shopping',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Amount field
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount (RM)',
                        hintText: 'e.g., 45.50',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date picker
                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd MMM yyyy').format(_selectedDate),
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category dropdown
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          items: _categories.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Row(
                                children: [
                                  Icon(
                                    CategoryUtils.getCategoryIcon(category),
                                    color: CategoryUtils.getCategoryColor(
                                        category),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(category),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null && mounted) {
                              setState(() {
                                _selectedCategory = newValue;
                                _selectedBudgetId =
                                    null; // Reset budget selection
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Budget dropdown (filtered by category and date range)
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Budget (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_balance_wallet),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _selectedBudgetId,
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('No Budget'),
                            ),
                            ..._budgets
                                .where((budget) =>
                                    budget.budgetCategory ==
                                        _selectedCategory &&
                                    _selectedDate.isAfter(budget.startDate
                                        .subtract(
                                            const Duration(seconds: 1))) &&
                                    _selectedDate.isBefore(budget.endDate
                                        .add(const Duration(seconds: 1))))
                                .map((BudgetModel budget) {
                              return DropdownMenuItem<String?>(
                                value: budget.budgetId,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${budget.budgetName} (${budget.budgetCategory})',
                                      ),
                                    ),
                                    if (budget.status == Status.failed) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.warning,
                                          color: Colors.red, size: 16),
                                    ],
                                  ],
                                ),
                              );
                            }),
                          ],
                          onChanged: (String? newValue) async {
                            if (newValue != null) {
                              final selectedBudget = _budgets.firstWhere(
                                  (budget) => budget.budgetId == newValue);
                              if (selectedBudget.status == Status.failed) {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Failed Budget Selected'),
                                    content: Text(
                                      'The budget "${selectedBudget.budgetName}" has already exceeded its target. Do you want to assign this expense to it?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Proceed'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm != true) return;
                              }
                            }
                            if (mounted) {
                              setState(() {
                                _selectedBudgetId = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Add notes about this expense',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateExpense,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Update Expense',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      if (mounted) {
        setState(() {
          _selectedDate = pickedDate;
          _selectedBudgetId = null; // Reset budget on date change
        });
      }
    }
  }

  void _updateExpense() async {
    if (_formKey.currentState!.validate()) {
      // Validate budget category and date range
      if (_selectedBudgetId != null) {
        final selectedBudget = _budgets
            .firstWhere((budget) => budget.budgetId == _selectedBudgetId);
        if (selectedBudget.budgetCategory != _selectedCategory) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Expense category must match budget category',
              ),
            ),
          );
          return;
        }
        if (!_selectedDate.isAfter(selectedBudget.startDate
                .subtract(const Duration(seconds: 1))) ||
            !_selectedDate.isBefore(
                selectedBudget.endDate.add(const Duration(seconds: 1)))) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Expense date must be within the budget\'s date range (${DateFormat('dd/MM/yyyy').format(selectedBudget.startDate)} - ${DateFormat('dd/MM/yyyy').format(selectedBudget.endDate)})',
              ),
            ),
          );
          return;
        }
      }

      try {
        setState(() {
          _isLoading = true;
        });

        final user = _auth.currentUser!;

        TransactionModel transaction = TransactionModel(
          id: _expenseId,
          title: _titleController.text,
          amount: double.parse(_amountController.text),
          date: _selectedDate,
          category: _selectedCategory,
          notes: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          userId: user.uid,
          isExpense: true,
          budgetId: _selectedBudgetId,
        );

        await _firestore
            .collection('transactions')
            .doc(_expenseId)
            .update(transaction.toMap());

        // Update budget's currentSpent
        await _updateBudgetCurrentSpent(_selectedBudgetId);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense updated successfully')),
        );

        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating expense: ${e.toString()}')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _updateBudgetCurrentSpent(String? budgetId) async {
    if (budgetId == null) return;

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
}