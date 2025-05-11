import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app_assignment/category_utils.dart';
import 'package:mobile_app_assignment/models/budget_model.dart';

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
  DateTime _endDate = DateTime.now().add(Duration(days: 7)); // Default to weekly
  final DateTime _startDate = DateTime.now(); // Default to current date
  DurationCategory _selectedDuration = DurationCategory.weekly;
  bool _isRecurring = false;

  @override
  void initState() {
    super.initState();
    _initializeDefaultValues();
    _updateDueDateDisplay();
  }

  void _initializeDefaultValues() {
    final defaultCategory = CategoryUtils.allCategories.isNotEmpty
        ? CategoryUtils.allCategories[0]
        : "Food";

    _categoryController.text = defaultCategory;
    _selectedIcon = CategoryUtils.getCategoryIcon(defaultCategory);
    _selectedColor = CategoryUtils.getCategoryColor(defaultCategory);

    _selectedDuration = DurationCategory.weekly;
    _durationController.text = _selectedDuration.name; // Initialize text
    _calculateEndDate();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _budgetNameController.dispose();
    _dueDateController.dispose();
    _durationController.dispose();
    _customDayController.dispose();
    _amountController.dispose();
    _remarkController.dispose();

    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context, // Uses the State's context
      initialDate: _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        _dueDateController.text = DateFormat('MMM dd, yyyy').format(_endDate);
        _updateDurationFromDates(); // New method to auto-calculate duration
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
          // Same day next month (e.g., May 8 → June 8)
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
      else if (daysDifference >= 28 && daysDifference <= 31) {
        // Check if it's approximately a month
        final nextMonth = DateTime(_startDate.year, _startDate.month + 1, _startDate.day);
        if (_endDate.day == nextMonth.day) {
          _selectedDuration = DurationCategory.monthly;
        } else {
          _selectedDuration = DurationCategory.custom;
          _customDayController.text = daysDifference.toString();
        }
      }
      else {
        _selectedDuration = DurationCategory.custom;
        _customDayController.text = daysDifference.toString();
      }

      _durationController.text = _selectedDuration.name;
    });
  }

  Future<bool> _isDuplicateBudget() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    // Check if a budget with the same name exists for the same user
    final sameNameQuery = await _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .where('budgetCategory', isEqualTo: _categoryController.text)
        .where('budgetName', isEqualTo: _budgetNameController.text)
        .get();

    if (sameNameQuery.docs.isEmpty) {
      return false; // No budget with same name exists
    }

    // Check for overlapping time periods
    for (final doc in sameNameQuery.docs) {
      final existingBudget = doc.data();
      final existingStart = (existingBudget['startDate'] as Timestamp).toDate();
      final existingEnd = (existingBudget['endDate'] as Timestamp).toDate();

      if (_startDate.isBefore(existingEnd) && _endDate.isAfter(existingStart)) {
        return true; // Overlapping budget found
      }
    }

    return false;
  }

  Future<void> _saveBudget() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Check for duplicate budget first
        final isDuplicate = await _isDuplicateBudget();
        if (isDuplicate) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A budget with this name already exists for the selected time period'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        final userId = _auth.currentUser?.uid;
        if (userId == null) return;

        final budgetData = {
          'budgetId':  _firestore.collection('budgets').doc().id,
          'budgetCategory': _categoryController.text,
          'budgetName': _budgetNameController.text,
          'targetAmount': double.parse(_amountController.text),
          'remark': _remarkController.text,
          'duration': _durationController.text,
          'customDay': _selectedDuration == DurationCategory.custom
        ? int.tryParse(_customDayController.text)
            : null,
          'startDate': Timestamp.fromDate(_startDate),
          'endDate': Timestamp.fromDate(_endDate),
          'userId': userId,
          'status': 'active', //default value
          'isRecurring': _isRecurring,
          'nextOccurrence': _calculateNextOccurrence(),
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

  String? _budgetTitleValidator(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a budget title';
    if (value.length > 20) return 'We only accept 20 characters. Please try again';
    return null;
  }

  String? _dueDateValidator(String? value) {
    if (value == null || value.isEmpty) return 'Please select a date';

    final now = DateTime.now();
    final selectedDate = _endDate;

    if (selectedDate.isBefore(now)) {
      return 'Deadline cannot be in the past';
    }
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
    if (value != null && value.length > 50) {
      return 'We only accept 50 characters. Please try again';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Budget'),
      ),
      body: _buildBody(),
      floatingActionButton: _buildSubmitButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
            _buildDeadlineWarning(),
            const SizedBox(height: 20),
            _buildDurationField(),
            const SizedBox(height: 20),
            _buildRemarkField(),
            const SizedBox(height: 20),
            _buildRepeatSwitch(),
            const SizedBox(height: 32),
            _buildPreview(),
            const SizedBox(height: 32),
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
          labelText: 'Category',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          filled: true,
          fillColor: Colors.purple[50],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: CategoryUtils.allCategories.contains(_categoryController.text)
                ? _categoryController.text
                : (CategoryUtils.allCategories.isNotEmpty ? CategoryUtils.allCategories[0] : null),
            isExpanded: true,
            borderRadius: BorderRadius.circular(15.0),
            icon: Icon(Icons.arrow_drop_down),
            iconSize: 24,
            iconEnabledColor: Colors.blueAccent,
            iconDisabledColor: Colors.grey,
            elevation: 8,
            items: CategoryUtils.allCategories.map((String category) {
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
        prefixIcon: Icon(Icons.title),
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

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.attach_money),
        labelText: 'Budget Amount (RM)',
        hintText: 'Eg. 500.00',
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
        prefixIcon: Icon(Icons.speaker_notes_outlined),
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
            Row(
              children: [
                _buildStatusIndicator('active'),
                Spacer(),
                _buildRepeatIcon(_isRecurring),
              ],
            ),
            const SizedBox(height: 16),
            _buildPreviewHeader(),
            const SizedBox(height: 16),
            _buildBudgetProgress(),
            const SizedBox(height: 16),
            _buildBudgetDeadlineProgress(),
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
    final remainAmount = amount;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RM 0.00 of RM ${amount.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              '0%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getProgressColor(0),
              )
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: 0,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(0)),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'RM${remainAmount.toStringAsFixed(2)} remaining',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetDeadlineProgress() {
    final now = DateTime.now();
    final startDateAtMidnight = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final endDateAtMidnight = DateTime(_endDate.year, _endDate.month, _endDate.day);

    // Ensure at least 1 day remains if deadline is today or future
    final remainDays = endDateAtMidnight.difference(now).inDays.clamp(0, 365);

    // Format dates
    final startDateFormatted = DateFormat('dd/MM/yyyy').format(_startDate);
    final endDateFormatted = DateFormat('dd/MM/yyyy').format(_endDate);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$startDateFormatted until $endDateFormatted',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            Text(
              '0%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getProgressColor(0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: 0,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(0)),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$remainDays ${remainDays == 1 ? 'day' : 'days'}  remaining',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return Colors.green;
    if (progress < 0.7) return Colors.orange;
    return Colors.red;
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

  Widget _buildSubmitButton() {
    bool isFormValid = _formKey.currentState?.validate() ?? false;
    return FloatingActionButton(
      onPressed: isFormValid ? _saveBudget : null,
      shape: CircleBorder(),
      backgroundColor: isFormValid ? Colors.purple[100] : Colors.grey[300],
      child: const Icon(Icons.check),
    );
  }

  Widget _buildDeadlineWarning() {
    final now = DateTime.now();
    final remainDays = _endDate.difference(now).inDays;

    if (remainDays <= 1) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          '⚠️ Deadline is very close!',
          style: TextStyle(color: Colors.orange[800], fontSize: 12),
        ),
      );
    }
    return SizedBox.shrink();
  }
}