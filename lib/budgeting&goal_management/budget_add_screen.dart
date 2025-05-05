import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app_assignment/category_utils.dart';

class BudgetAddScreen extends StatefulWidget {
  const BudgetAddScreen({super.key});

  @override
  State<BudgetAddScreen> createState() => _BudgetAddScreenState();
}

class _BudgetAddScreenState extends State<BudgetAddScreen> {
  //Controllers
  final _formKey = GlobalKey<FormState>();    //for validation
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _budgetNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();

  // firebase integration
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize these with null or empty values
  late IconData _selectedIcon;
  late Color _selectedColor;
  final DateTime _selectedDate = DateTime.now(); // Default to current date

  //=====================
  // INITIALIZATION
  //=====================
  @override
  void initState() {  //set default value
    super.initState();
    _initializeDefaultValues();
  }

  void _initializeDefaultValues() {
    final defaultCategory = CategoryUtils.categories.isNotEmpty
        ? CategoryUtils.categories[0]
        : "Food";

    _categoryController.text = defaultCategory;
    _selectedIcon = CategoryUtils.getCategoryIcon(defaultCategory);
    _selectedColor = CategoryUtils.getCategoryColor(defaultCategory);
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  //=====================
  // BUSINESS LOGIC
  //=====================
  Future<void> _saveBudget() async {
    if (_formKey.currentState!.validate()) {
      try {
        final userId = _auth.currentUser?.uid;
        if (userId == null) return;

        // Use _selectedDate instead of now
        final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
        final lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

        final budgetData = {
          'budgetCategory': _categoryController.text,
          'targetAmount': double.parse(_amountController.text),
          'remark': _remarkController.text,
          'startDate': firstDayOfMonth,
          'endDate': lastDayOfMonth,
          'userId': userId,
          'status': 'active' //default value
        };


        await _firestore.collection('budgets').add(budgetData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget created successfully'),
            backgroundColor: Colors.green,
          ),
        );


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

  //=====================
  // FORM VALIDATORS
  //=====================
  String? _budgetTitleValidator(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a budget title';
    if (value.length > 20) return 'We only accept 20 characters. Please try again';
    return null;
  }

  String? _amountValidator(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a budget amount';
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) return 'Please enter a valid positive amount';
    return null;
  }

  String? _remarkValidator(String? value) {
    if (value != null && value.length > 20) {
      return 'We only accept 20 characters. Please try again';
    }
    return null;
  }

  //=====================
  // UI COMPONENTS
  //=====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar(){
    return AppBar(
    title: Text('Create Budget'),
    );
  }

  Widget _buildBody(){
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryNameField(),
            const SizedBox(height: 20),
            _buildBudgetNameField(),
            const SizedBox(height: 20),
            _buildAmountField(),
            const SizedBox(height: 32),
            _buildRemarkField(),
            const SizedBox(height: 32),
            _buildPreview(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryNameField() {
    return SizedBox(
      width: 200,
      height: 50,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Category',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: CategoryUtils.categories.contains(_categoryController.text)
                ? _categoryController.text
                : (CategoryUtils.categories.isNotEmpty ? CategoryUtils.categories[0] : null),
            isExpanded: true,
            borderRadius: BorderRadius.circular(15.0),
            icon: Icon(Icons.arrow_drop_down),
            iconSize: 24,
            iconEnabledColor: Colors.blueAccent,
            iconDisabledColor: Colors.grey,
            elevation: 8,
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
      ),
    );
  }

  Widget _buildBudgetNameField(){
    return TextFormField(
      controller: _budgetNameController,
      decoration: const InputDecoration(
        labelText: 'Budget Title',
        hintText: 'Eg. Haidilao',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.text,
      validator: _budgetTitleValidator,
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _budgetNameController.text = newValue;
          });
        }
      },
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: const InputDecoration(
        labelText: 'Budget Amount (RM)',
        hintText: 'E.g. 500.00',
        border: OutlineInputBorder(),
        prefixText: 'RM ',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: _amountValidator,
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _amountController.text = newValue;
          });
        }
      },
    );
  }

  Widget _buildRemarkField(){
    return TextFormField(
      controller: _remarkController,
      decoration: const InputDecoration(
        labelText: 'Remark',
        hintText: 'Eg. Eat with friends',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.text,
      validator: _remarkValidator,
    );
  }

  Widget _buildPreview() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPreviewHeader(),
            const SizedBox(height: 16),
            _buildBudgetProgress(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewHeader() {
    return Row(
      children: [
        _buildCategoryIcon(),
        const SizedBox(width: 12),
        Text(
          _categoryController.text.isNotEmpty ? _categoryController.text : 'Category Name',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 9),
        if (_budgetNameController.text.isNotEmpty)
          Text(
            '-',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 9),
          Text(
            _budgetNameController.text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

        if (_remarkController.text.isNotEmpty && _remarkController.text.length <= 20)
          Text(_remarkController.text, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildCategoryIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _selectedColor.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(_selectedIcon, color: _selectedColor),
    );
  }

  Widget _buildBudgetProgress() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RM 0.00 of RM ${amount.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const Text('0%', style: TextStyle(fontWeight: FontWeight.bold)),
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
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _saveBudget,
      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
      child: const Text('Create Budget'),
    );
  }
}