import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../category_utils.dart';
import '../models/budget_model.dart';

class BudgetEditScreen extends StatefulWidget {
  const BudgetEditScreen({super.key});

  @override
  State<BudgetEditScreen> createState() => _BudgetEditScreenState();
}

class _BudgetEditScreenState extends State<BudgetEditScreen> {
  final _formKey = GlobalKey<FormState>();    //for validation

  //Controllers
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
  DateTime _selectedDate = DateTime.now(); // Default to current date

  BudgetModel? _editingBudget;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {  //set default value
    super.initState();

    _initializeDefaults();
    _loadArguments();
  }

  void _initializeDefaults(){
    final defaultCategory = CategoryUtils.categories.isNotEmpty
        ? CategoryUtils.categories[0]
        : "Food";
    _categoryController.text = defaultCategory;
    _selectedIcon = CategoryUtils.getCategoryIcon(defaultCategory);
    _selectedColor = CategoryUtils.getCategoryColor(defaultCategory);
  }

  void _loadArguments() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments == null) return;

      BudgetModel? budget;
      DateTime? selectedDate;

      if (arguments is BudgetModel) {
        budget = arguments;
      } else if (arguments is Map<String, dynamic>) {
        budget = arguments['budget'] as BudgetModel?;
        selectedDate = arguments['selectedDate'] as DateTime?;
      }

      if (budget == null) return;  // Early return if no budget

      setState(() {
        _editingBudget = budget!;
        _categoryController.text = budget.budgetCategory;
        _amountController.text = budget.targetAmount.toString();
        _remarkController.text = budget.remark ?? '';
        _selectedIcon = CategoryUtils.getCategoryIcon(budget.budgetCategory);
        _selectedColor = CategoryUtils.getCategoryColor(budget.budgetCategory);
        _selectedDate = selectedDate ?? _selectedDate;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar(){
    return AppBar(
      title: Text('Edit Budget'),
      actions: [
        if (_isSaving)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
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
            const SizedBox(height: 20),
            _buildRemarkField(),
            const SizedBox(height: 32),
            _buildPreview(),
            const SizedBox(height: 32),
            _buildActionButton(),
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
      validator: (value){
        if (value != null && value.length > 20){
          return 'We only accept 20 characters. Please try again';
        }
        return null;
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

  Widget _buildRemarkField(){
    return TextFormField(
      controller: _remarkController,
      decoration: const InputDecoration(
        labelText: 'Remark',
        hintText: 'Eg. KFC',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.text,
      validator: (value){
        if (value != null && value.length > 20){
          return 'We only accept 20 characters. Please try again';
        }
        return null;
      },
    );
  }

  Widget _buildPreview() {
    final categoryName = _categoryController.text;
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final remark = _remarkController.text;

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
                const SizedBox(width: 20),
                (remark.isNotEmpty && remark.length <= 20)
                    ? Text(
                  remark,
                  style: const TextStyle(fontSize: 16),
                )
                    : const SizedBox.shrink(),
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

  Widget _buildActionButton(){
    return Column(
      children: [
        ElevatedButton(
          onPressed: _isSaving ? null : _saveBudget,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: _isSaving
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Text('Update Budget'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isDeleting ? null : _confirmDeleteBudget,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            foregroundColor: Colors.red,
          ),
          child: _isDeleting
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.red,
            ),
          )
              : const Text('Delete Budget'),
        ),
      ],
    );
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate() || _editingBudget == null) return;

    setState(() => _isSaving = true);

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Use _selectedDate instead of now
      final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
      final lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

      final budgetData = {
        'budgetCategory': _categoryController.text,
        'budgetName': _budgetNameController.text,
        'targetAmount': double.parse(_amountController.text),
        'remark': _remarkController.text,
        'startDate': Timestamp.fromDate(firstDayOfMonth),
        'endDate': Timestamp.fromDate(lastDayOfMonth),
        'userId': userId,
        'status': _editingBudget?.status.toString() ?? 'active' //default value
      };
      await _firestore.collection('budgets').doc(_editingBudget!.budgetId).update(budgetData);

      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Firebase error: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmDeleteBudget() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this budget? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteBudget();
    }
  }

  Future<void> _deleteBudget() async {
    if (_editingBudget == null) return;

    setState(() => _isDeleting = true);

    try {
      await _firestore.collection('budgets').doc(_editingBudget!.budgetId).delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }  on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Firebase error: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }
}
