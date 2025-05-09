import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _customDayController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();

  // firebase integration
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize these with null or empty values
  late IconData _selectedIcon;
  late Color _selectedColor;
  late DateTime _startDate; // Default to current date
  late DateTime _endDate;
  late String _status;
  late DurationCategory _selectedDuration;
  late bool _isRecurring;

  BudgetModel? _editingBudget;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isLoading = true;
  String? _errorMessage;

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
    _startDate = DateTime.now(); // Initialize with current date
    _endDate = _startDate.add(Duration(days: 7)); // Default to weekly
    _selectedDuration = DurationCategory.weekly;
    _isRecurring = false;
  }

  void _loadArguments() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments == null) {
        setState(() {
          _errorMessage = 'No budget data provided';
          _isLoading = false;
        });
        return;
      }

      BudgetModel? budget;

      if (arguments is BudgetModel) {
        budget = arguments;
      } else if (arguments is Map<String, dynamic>) {
        budget = arguments['budget'] as BudgetModel?;
      }

      if (budget == null) return;  // Early return if no budget

      _status = budget.status.name;

      setState(() {
        _editingBudget = budget!;
        _categoryController.text = budget.budgetCategory;
        _budgetNameController.text = budget.budgetName;
        _amountController.text = budget.targetAmount.toStringAsFixed(2);
        _remarkController.text = budget.remark ?? '';
        _selectedIcon = CategoryUtils.getCategoryIcon(budget.budgetCategory);
        _selectedColor = CategoryUtils.getCategoryColor(budget.budgetCategory);
        _startDate = budget.startDate;
        _endDate = budget.endDate;
        _selectedDuration = budget.duration;
        _isRecurring = budget.isRecurring;

        _dueDateController.text = DateFormat('MMM dd, yyyy').format(budget.endDate);

        // Update duration controller if custom
        if (budget.duration == DurationCategory.custom) {
          _customDayController.text = budget.customDays?.toString() ??
              budget.endDate.difference(budget.startDate).inDays.toString();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildActionButton(),
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
            _buildDueDateField(),
            const SizedBox(height: 20),
            _buildDurationField(),
            const SizedBox(height: 20),
            _buildRemarkField(),
            const SizedBox(height: 20),
            _buildRepeatSwitch(),
            const SizedBox(height: 32),
            _buildPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryNameField() {
    return SizedBox(
      width: 200,
      height: 60,
      child: InputDecorator(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.purple[50],
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

  Widget _buildDueDateField(){
    return GestureDetector(
      onTap: _selectDate, // Trigger date picker on any tap
      child: AbsorbPointer(
        child: TextFormField(
          controller: _dueDateController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Due Date',
            hintText: 'Select a date',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.calendar_today), // Optional prefix
            suffixIcon: const Icon(Icons.arrow_drop_down), // Optional dropdown hint
          ),
          validator: _dueDateValidator,
        ),
      ),
    );
  }

  Widget _buildDurationField(){
    return Column(
      children: [
        DropdownButtonHideUnderline(
          child: DropdownButtonFormField<DurationCategory>(
            value: _selectedDuration,
            decoration: InputDecoration(
              labelText: 'Duration',
              prefixIcon: Icon(Icons.timer),
              border: OutlineInputBorder(),
            ),
            isExpanded: true,
            items: DurationCategory.values.map((duration) {
              return DropdownMenuItem(
                value: duration,
                child: Text(
                  duration.name.toUpperCase(),
                ),
              );
            }).toList(),
            onChanged: (DurationCategory? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedDuration = newValue;
                  if (newValue != DurationCategory.custom) {
                    _calculateEndDate();
                    _updateDueDateDisplay();
                  } else {
                    _customDayController.text = '';
                  }
                });
              }
            },
            validator: _durationDropdownValidator,
          ),
        ),
        // Conditional Custom Days Input
        if (_selectedDuration == DurationCategory.custom)
          _buildCustomDaysField(),
      ],
    );
  }

  Widget _buildCustomDaysField(){
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextFormField(
        controller: _customDayController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.dashboard_customize_outlined),
          labelText: 'Number of Days',
          border: OutlineInputBorder(),
          suffixText: 'days',
        ),
        validator: _customDaysValidator,
        onChanged: (value) {
          final days = int.tryParse(value);
          if (days != null && days > 0) {
            _endDate = _startDate.add(Duration(days: days));
            _updateDueDateDisplay();
          }
        },
      ),
    );
  }

  Widget _buildRepeatSwitch(){
    return SwitchListTile(
      contentPadding: EdgeInsets.zero, // Remove default padding
      title: const Text(
        'Repeat',
        style: TextStyle(fontSize: 16),
      ),
      subtitle: _isRecurring
          ? const Text('This budget will repeat automatically')
          : null,
      value: _isRecurring,
      onChanged: (bool value) {
        setState(() {
          _isRecurring = value;
        });
      },
      secondary: const Icon(Icons.repeat),
      activeColor: Colors.purple[200], // Your theme color
      inactiveTrackColor: Colors.grey[300],
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
      validator: _remarkValidator,
    );
  }

  Widget _buildPreview() {
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
            Row(
              children: [
                _buildStatusIndicator(_status),
                Spacer(),
                _buildRepeatIcon(_isRecurring),

              ],
            ),
            const SizedBox(height: 16),
            _buildPreviewHeader(),
            const SizedBox(height: 16),
            _buildBudgetProcess(),
            const SizedBox(height: 16),
            _buildBudgetDeadline(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewHeader(){
    final categoryName = _categoryController.text;
    final budgetTitle = _budgetNameController.text;

    return Row(
      children: [
        _buildCategoryIcon(),
        const SizedBox(width: 12),
        _buildCategoryName(categoryName),
        _buildBudgetTitle(budgetTitle),
      ],
    );
  }

  Widget _buildStatusIndicator(String status) {
    Color statusColor;
    String statusText;

    switch (status.toLowerCase()) {
      case 'active':
        statusColor = Colors.green;
        statusText = 'Active';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusText = 'Completed';
        break;
      case 'failed':
        statusColor = Colors.grey;
        statusText = 'Failed';
        break;
      case 'stopped':
        statusColor = Colors.orange;
        statusText = 'Stopped';
        break;
      case 'deleted':
        statusColor = Colors.red;
        statusText = 'Deleted';
        break;
      default:
        statusColor = Colors.black;
        statusText = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            color: statusColor,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepeatIcon(bool isRepeat){
    return Tooltip(
      message: isRepeat ? 'Repeat Budget' : 'One-time Budget',
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isRepeat
              ? Colors.purple.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.repeat,
          size: 20,
          color: isRepeat ? Colors.purple : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildCategoryIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _selectedColor.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _selectedIcon,
        color: _selectedColor,
      ),
    );
  }

  Widget _buildCategoryName(String name) {
    return Text(
      name.isNotEmpty ? name : 'Category Name',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildBudgetTitle(String? title) {
    if (title == null || title.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        const SizedBox(width: 9),
        const Text(
          '-',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBudgetProcess(){
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    return Column(
      children: [
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
    );
  }

  Widget _buildBudgetDeadline(){
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = DateTime(_endDate.year, _endDate.month, _endDate.day);

    final remainDays = endDate.difference(today).inDays;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$remainDays ${remainDays == 1 ? 'day' : 'days'} remaining',
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
    );
  }

  Widget _buildActionButton(){
    return Padding(
      padding: EdgeInsets.only(left: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FloatingActionButton(
            onPressed: _confirmDeleteBudget,
            child: Icon(Icons.delete_rounded, color: Colors.white),
            backgroundColor: Colors.red,
          ),
          FloatingActionButton(
            onPressed: _saveBudget,
            child: Icon(Icons.upload_sharp, color: Colors.white),
            backgroundColor: Colors.green,
          ),
        ],
      ),
    );
  }

  //=====================
  // FORM VALIDATORS
  //=====================
  String? _budgetTitleValidator(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a budget title';
    if (value.length > 20) return 'We only accept 20 characters. Please try again';
    return null;
  }

  String? _dueDateValidator(String? value) {
    if (value == null || value.isEmpty) return 'Select a date';
    if (_endDate.isBefore(DateTime.now())) return 'Date cannot be in the past';
    return null;
  }

  String? _amountValidator(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a budget amount';
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) return 'Please enter a valid positive amount';
    return null;
  }

  String? _durationDropdownValidator(DurationCategory? value) {
    if (value == null) return 'Select a duration type';
    if (value == DurationCategory.custom &&
        (_customDayController.text.isEmpty ||
            int.tryParse(_customDayController.text) == null)) {
      return 'Set valid custom days';
    }
    return null;
  }

  String? _customDaysValidator(String? value) {
    if (_selectedDuration != DurationCategory.custom) return null;
    if (value == null || value.isEmpty) return 'Required';
    final days = int.tryParse(value);
    if (days == null) return 'Enter a valid number';
    if (days <= 0) return 'Must be positive';
    return null;
  }

  String? _remarkValidator(String? value) {
    if (value != null && value.length > 20) {
      return 'We only accept 20 characters. Please try again';
    }
    return null;
  }

  // ==========================
  //       BUSINESS LOGIC
  // ==========================

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context, // Uses the State's context
      initialDate: _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59); // End of day
        _dueDateController.text = DateFormat('MMM dd, yyyy').format(_endDate);
        _updateDurationFromDates();
      });
    }
  }

  void _calculateEndDate() {
    setState(() {
      switch (_selectedDuration) {
        case DurationCategory.daily:
          _endDate = _startDate.add(const Duration(days: 1));
          break;
        case DurationCategory.weekly:
          _endDate = _startDate.add(const Duration(days: 7));
          break;
        case DurationCategory.monthly:
          final nextMonth = _startDate.month + 1;
          final nextYear = _startDate.year + (nextMonth > 12 ? 1 : 0);
          final adjustedMonth = nextMonth > 12 ? nextMonth - 12 : nextMonth;
          _endDate = DateTime(nextYear, adjustedMonth, _startDate.day);
          break;
        case DurationCategory.custom:
          final days = int.tryParse(_customDayController.text);
          if (days != null) _endDate = _startDate.add(Duration(days: days));
          break;
      }
    });
  }

  void _updateDueDateDisplay() {
    _dueDateController.text = DateFormat('MMM dd, yyyy').format(_endDate);
  }

  void _updateDurationFromDates() {
    final daysDifference = _endDate.difference(_startDate).inDays;

    setState(() {
      if (daysDifference == 0) { // Same day
        _selectedDuration = DurationCategory.daily;
        _endDate = _startDate.add(Duration(days: 1)); // Force to next day
      }
      else if (daysDifference == 1) {
        _selectedDuration = DurationCategory.daily;
      }
      else if (daysDifference == 7) {
        _selectedDuration = DurationCategory.weekly;
      }
      else {
        // Check for exact month difference
        final nextMonth = DateTime(
            _startDate.year, _startDate.month + 1, _startDate.day);
        if (_endDate
            .difference(nextMonth)
            .inDays == 0) {
          _selectedDuration = DurationCategory.monthly;
        } else {
          _selectedDuration = DurationCategory.custom;
          _customDayController.text = daysDifference.toString();
        }
      }

      _durationController.text = _selectedDuration.name;
    });
  }

  DateTime _calculateNextOccurrence() {
    switch (_selectedDuration) {
      case DurationCategory.daily:
        return _endDate.add(const Duration(days: 1));
      case DurationCategory.weekly:
        return _endDate.add(const Duration(days: 7));
      case DurationCategory.monthly:
        final nextMonth = _endDate.month + 1;
        final nextYear = _endDate.year + (nextMonth > 12 ? 1 : 0);
        final adjustedMonth = nextMonth > 12 ? nextMonth - 12 : nextMonth;
        return DateTime(
          nextYear,
          adjustedMonth,
          min(_endDate.day, DateUtils.getDaysInMonth(nextYear, adjustedMonth)),
        );
      case DurationCategory.custom:
        final days = int.tryParse(_customDayController.text) ?? 0;
        return _endDate.add(Duration(days: days));
    }
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate() || _editingBudget == null) return;

    setState(() => _isSaving = true);

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final budgetData = {
        'budgetCategory': _categoryController.text,
        'budgetName': _budgetNameController.text,
        'targetAmount': double.parse(_amountController.text),
        'duration': _selectedDuration.name,
        'remark': _remarkController.text,
        'isRecurring': _isRecurring,
        'customDay': _selectedDuration == DurationCategory.custom
            ? int.tryParse(_customDayController.text)
            : null,
        'endDate': Timestamp.fromDate(_endDate),
        'userId': userId,
        'status': _editingBudget?.status.toString() ?? 'active', //default value
        'nextOccurrence': _calculateNextOccurrence(),
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
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Use _startDate instead of now
      final firstDayOfMonth = DateTime(_startDate.year, _startDate.month, 1);
      final lastDayOfMonth = DateTime(_startDate.year, _startDate.month + 1, 0);

      final budgetData = {
        'budgetCategory': _categoryController.text,
        'budgetName': _budgetNameController.text,
        'targetAmount': double.parse(_amountController.text),
        'remark': _remarkController.text,
        'startDate': Timestamp.fromDate(firstDayOfMonth),
        'endDate': Timestamp.fromDate(lastDayOfMonth),
        'userId': userId,
        'status': 'deleted',
      };
      await _firestore.collection('budgets').doc(_editingBudget!.budgetId).update(budgetData);

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
