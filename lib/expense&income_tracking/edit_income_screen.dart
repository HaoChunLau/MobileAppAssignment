import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditIncomeScreen extends StatefulWidget {
  @override
  _EditIncomeScreenState createState() => _EditIncomeScreenState();
}

class _EditIncomeScreenState extends State<EditIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form field controllers
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  
  late DateTime _selectedDate;
  late String _selectedCategory;
  
  // Predefined categories
  final List<String> _categories = [
    'Salary',
    'Freelance',
    'Investment',
    'Gift',
    'Bonus',
    'Refund',
    'Other',
  ];

  bool _isLoading = true;
  String _incomeId = '';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _selectedDate = DateTime.now();
    _selectedCategory = 'Salary';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get the income ID from the route arguments
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null && arguments.containsKey('id')) {
      _incomeId = arguments['id'] as String;
      _loadIncomeData();
    } else {
      // No ID provided, show error and go back
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: No income ID provided')),
        );
      });
    }
  }

  // Load income data (simulated)
  void _loadIncomeData() {
    // In a real app, this would fetch from a database or API
    // Simulated loading delay
    Future.delayed(Duration(milliseconds: 500), () {
      // Dummy data for this template
      final incomeData = {
        'title': 'Salary',
        'amount': 4500.00,
        'date': '2025-03-15',
        'category': 'Salary',
        'description': 'Monthly salary',
      };
      
      setState(() {
        _titleController.text = incomeData['title'] as String;
        _amountController.text = (incomeData['amount'] as double).toString();
        _selectedDate = DateTime.parse(incomeData['date'] as String);
        _selectedCategory = incomeData['category'] as String;
        _descriptionController.text = incomeData['description'] as String;
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
        title: Text('Edit Income'),
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
                        hintText: 'e.g., Monthly Salary',
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
                        hintText: 'e.g., 4500.00',
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
                        hintText: 'Add notes about this income',
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
                        onPressed: _updateIncome,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Update Income',
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

  void _updateIncome() {
    if (_formKey.currentState!.validate()) {
      // Update the income data
      // This is just a template, so we'll just print it
      print('Updating income ID: $_incomeId');
      print('Title: ${_titleController.text}');
      print('Amount: ${_amountController.text}');
      print('Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}');
      print('Category: $_selectedCategory');
      print('Description: ${_descriptionController.text}');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Income updated successfully')),
      );
      
      // Navigate back to the income list screen
      Navigator.pop(context);
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Income'),
          content: Text('Are you sure you want to delete this income?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Delete the income
                Navigator.of(context).pop();
                
                // Show success message and navigate back
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Income deleted')),
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
      case 'Refund':
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
        return Icons.stars;
      case 'Refund':
        return Icons.replay;
      default:
        return Icons.attach_money;
    }
  }
}