import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app_assignment/category_utils.dart';
import 'package:mobile_app_assignment/models/budget_model.dart';

class BudgetSettingScreen extends StatefulWidget {
  const BudgetSettingScreen({super.key});

  @override
  State<BudgetSettingScreen> createState() => _BudgetSettingScreenState();
}

class _BudgetSettingScreenState extends State<BudgetSettingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Initialize these with null or empty values
  late IconData _selectedIcon;
  late Color _selectedColor;
  DateTime _selectedDate = DateTime.now(); // Default to current date

  BudgetModel? _editingBudget;

  @override
  void initState() {
    super.initState();
    
    final defaultCategory = CategoryUtils.categories.isNotEmpty 
        ? CategoryUtils.categories[0] 
        : "Food";
    
    _categoryController.text = defaultCategory;
    _selectedIcon = CategoryUtils.getCategoryIcon(defaultCategory);
    _selectedColor = CategoryUtils.getCategoryColor(defaultCategory);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      
      // Update this section to handle both cases:
      if (arguments != null) {
        if (arguments is BudgetModel) {
          // Legacy case - directly passing a budget model
          setState(() {
            _editingBudget = arguments;
            _categoryController.text = _editingBudget!.budgetCategory;
            _amountController.text = _editingBudget!.targetAmount.toString();
            _selectedIcon = CategoryUtils.getCategoryIcon(_editingBudget!.budgetCategory);
            _selectedColor = CategoryUtils.getCategoryColor(_editingBudget!.budgetCategory);
          });
        } else if (arguments is Map) {
          // New way - passing a map with the necessary data
          if (arguments['budget'] != null) {
            setState(() {
              _editingBudget = arguments['budget'] as BudgetModel;
              _categoryController.text = _editingBudget!.budgetCategory;
              _amountController.text = _editingBudget!.budgetCategory.toString();
              _selectedIcon = CategoryUtils.getCategoryIcon(_editingBudget!.budgetCategory);
              _selectedColor = CategoryUtils.getCategoryColor(_editingBudget!.budgetCategory);
            });
          }
          
          if (arguments['selectedDate'] != null) {
            setState(() {
              _selectedDate = arguments['selectedDate'] as DateTime;
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editingBudget == null ? 'Create Budget' : 'Edit Budget'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryNameField(),
              const SizedBox(height: 20),
              _buildAmountField(),
              const SizedBox(height: 32),
              _buildPreview(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveBudget,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(_editingBudget == null ? 'Create Budget' : 'Update Budget'),
              ),
              if (_editingBudget != null) 
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: OutlinedButton(
                    onPressed: _deleteBudget,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Delete Budget'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryNameField() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: CategoryUtils.categories.contains(_categoryController.text) 
              ? _categoryController.text 
              : (CategoryUtils.categories.isNotEmpty ? CategoryUtils.categories[0] : null),
          isExpanded: true,
          items: CategoryUtils.categories.map((String category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Row(
                children: [
                  Icon(
                    CategoryUtils.getCategoryIcon(category),
                    color: CategoryUtils.getCategoryColor(category),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(category),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _categoryController.text = newValue;
                _selectedIcon = CategoryUtils.getCategoryIcon(newValue);
                _selectedColor = CategoryUtils.getCategoryColor(newValue);
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: const InputDecoration(
        labelText: 'Budget Amount (RM)',
        hintText: 'E.g., 500.00',
        border: OutlineInputBorder(),
        prefixText: 'RM ',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a budget amount';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return 'Please enter a valid positive amount';
        }
        return null;
      },
    );
  }

  Widget _buildPreview() {
    final categoryName = _categoryController.text.isNotEmpty
        ? _categoryController.text
        : 'Category Name';
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedColor.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _selectedIcon,
                    color: _selectedColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  categoryName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RM 0.00 of RM ${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const Text(
                  '0%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: 0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(_selectedColor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveBudget() async {
    if (_formKey.currentState!.validate()) {
      try {
        final userId = _auth.currentUser?.uid;
        if (userId == null) return;

        // Use _selectedDate instead of now
        final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
        final lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

        final budgetData = {
          'category': _categoryController.text,
          'amount': double.parse(_amountController.text),
          'startDate': firstDayOfMonth,
          'endDate': lastDayOfMonth,
          'userId': userId,
        };

        if (_editingBudget == null) {
          await _firestore.collection('budgets').add(budgetData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Budget created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          await _firestore.collection('budgets').doc(_editingBudget!.budgetId).update(budgetData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Budget updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteBudget() async {
    try {
      if (_editingBudget != null) {
        await _firestore.collection('budgets').doc(_editingBudget!.budgetId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}