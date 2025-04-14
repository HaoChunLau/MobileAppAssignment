import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditExpenseScreen extends StatefulWidget {
  const EditExpenseScreen({super.key});

  @override
  EditExpenseScreenState createState() => EditExpenseScreenState();
}

class EditExpenseScreenState extends State<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form field controllers
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  
  late DateTime _selectedDate;
  late String _selectedCategory;
  
  // Predefined categories
  final List<String> _categories = [
    'Food',
    'Transportation',
    'Entertainment',
    'Utilities',
    'Housing',
    'Healthcare',
    'Shopping',
    'Education',
    'Personal',
    'Other',
  ];

  bool _isLoading = true;
  String _expenseId = '';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _selectedDate = DateTime.now();
    _selectedCategory = 'Food';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get the expense ID from the route arguments
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null && arguments.containsKey('id')) {
      _expenseId = arguments['id'] as String;
      _loadExpenseData();
    } else {
      // No ID provided, show error and go back
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: No expense ID provided')),
        );
      });
    }
  }

  // Load expense data (simulated)
  void _loadExpenseData() {
    // In a real app, this would fetch from a database or API
    // Simulated loading delay
    Future.delayed(Duration(milliseconds: 500), () {
      // Dummy data for this template
      final expenseData = {
        'title': 'Groceries',
        'amount': 85.40,
        'date': '2025-03-21',
        'category': 'Food',
        'description': 'Weekly grocery shopping',
      };
      
      setState(() {
        _titleController.text = expenseData['title'] as String;
        _amountController.text = (expenseData['amount'] as double).toString();
        _selectedDate = DateTime.parse(expenseData['date'] as String);
        _selectedCategory = expenseData['category'] as String;
        _descriptionController.text = expenseData['description'] as String;
        _isLoading = false;
      });
    });
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
      appBar: AppBar(
        title: Text('Edit Expense'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _showDeleteConfirmation,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title field
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
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
                    SizedBox(height: 16),
                    
                    // Amount field
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount (RM)',
                        hintText: 'e.g., 45.50',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                    SizedBox(height: 16),
                    
                    // Date picker
                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
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
                            Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Category dropdown
                    InputDecorator(
                      decoration: InputDecoration(
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
                                    _getCategoryIcon(category),
                                    color: _getCategoryColor(category),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(category),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedCategory = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Add notes about this expense',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 24),
                    
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateExpense,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
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
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _updateExpense() {
    if (_formKey.currentState!.validate()) {
      // Update the expense data
      // This is just a template, so we'll just print it
      print('Updating expense ID: $_expenseId');
      print('Title: ${_titleController.text}');
      print('Amount: ${_amountController.text}');
      print('Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}');
      print('Category: $_selectedCategory');
      print('Description: ${_descriptionController.text}');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Expense updated successfully')),
      );
      
      // Navigate back to the expense list screen
      Navigator.pop(context);
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Expense'),
          content: Text('Are you sure you want to delete this expense?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Delete the expense
                Navigator.of(context).pop();
                
                // Show success message and navigate back
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Expense deleted')),
                );
                Navigator.pop(context);
              },
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
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
      case 'Housing':
        return Colors.brown;
      case 'Healthcare':
        return Colors.red;
      case 'Shopping':
        return Colors.pink;
      case 'Education':
        return Colors.teal;
      case 'Personal':
        return Colors.indigo;
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
      case 'Housing':
        return Icons.home;
      case 'Healthcare':
        return Icons.medical_services;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Education':
        return Icons.school;
      case 'Personal':
        return Icons.person;
      default:
        return Icons.attach_money;
    }
  }
}