import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app_assignment/utils/category_utils.dart';
import 'package:mobile_app_assignment/models/savings_goal_model.dart';

class SavingsGoalAddScreen extends StatefulWidget {
  const SavingsGoalAddScreen({super.key});

  @override
  State<SavingsGoalAddScreen> createState() => _SavingsGoalAddScreenState();
}

class _SavingsGoalAddScreenState extends State<SavingsGoalAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _savingNameController = TextEditingController();
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

  void initState() {  //set default value
    super.initState();
    _initializeDefaultValues();
  }

  void _initializeDefaultValues() {
    final defaultCategory = SavingCategoryUtils.categories.isNotEmpty
        ? SavingCategoryUtils.categories[0]
        : "Emergency Fund";

    _categoryController.text = defaultCategory;
    _selectedIcon = SavingCategoryUtils.getCategoryIcon(defaultCategory);
    _selectedColor = SavingCategoryUtils.getCategoryColor(defaultCategory);

    _selectedDuration = DurationCategory.weekly;
    _durationController.text = _selectedDuration.name; // Initialize text

    _calculateEndDate();
    _updateDueDateDisplay();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _savingNameController.dispose();
    _dueDateController.dispose();
    _durationController.dispose();
    _customDayController.dispose();
    _amountController.dispose();
    _remarkController.dispose();

    super.dispose();
  }

  //=====================
  // BUSINESS LOGIC
  //=====================

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

  Future<bool> _isDuplicateSaving() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    // Check if a budget with the same name exists for the same user
    final sameNameQuery = await _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .where('budgetCategory', isEqualTo: _categoryController.text)
        .where('budgetName', isEqualTo: _savingNameController.text)
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

  // change
  Future<void> _saveSaving() async {
    if (_formKey.currentState!.validate()) {
      try {

        final isDuplicate = await _isDuplicateSaving();
        if (isDuplicate) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A saving with this name already exists for the selected time period'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        final userId = _auth.currentUser?.uid;
        if (userId == null) return;

        //PASSING DATA TO FIREBASE
        final savingData = {
          'savingGoalId':  _firestore.collection('savings').doc().id,
          'goalCategory': _categoryController.text,
          'title': _savingNameController.text,
          'targetAmount': double.parse(_amountController.text),
          'remark': _remarkController.text,
          'duration': _durationController.text,
          'customDay': _selectedDuration == DurationCategory.custom
              ? int.tryParse(_customDayController.text)
              : null,
          'startDate': Timestamp.fromDate(_startDate),
          'targetDate': Timestamp.fromDate(_endDate),
          'userId': userId,
          'status': 'active', //default value
        };

        await _firestore.collection('savings').add(savingData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saving created successfully'),
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
  String? _savingTitleValidator(String? value) {
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

  //=====================
  // UI COMPONENTS
  //=====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildSubmitButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  AppBar _buildAppBar(){
    return AppBar(
      title: Text('Add Savings Goal'),
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
              _buildSavingNameField(),
              const SizedBox(height: 20),
              _buildDueDateField(),
              const SizedBox(height: 20),
              _buildAmountField(),
              const SizedBox(height: 20),
              _buildDurationField(),
              const SizedBox(height: 20),
              _buildRemarkField(),
              const SizedBox(height: 32),
              _buildPreview(),

            ],
          ),
        ),
    );
  }

  Widget _buildCategoryNameField(){
    return SizedBox(
      width: 210,
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
            value: SavingCategoryUtils.categories.contains(_categoryController.text)
                ? _categoryController.text
                : (SavingCategoryUtils.categories.isNotEmpty ? SavingCategoryUtils.categories[0] : null),
            isExpanded: true,
            borderRadius: BorderRadius.circular(15.0),
            icon: Icon(Icons.arrow_drop_down),
            iconSize: 24,
            iconEnabledColor: Colors.blueAccent,
            iconDisabledColor: Colors.grey,
            elevation: 8,
            items: SavingCategoryUtils.categories.map((String category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Row(
                  children: [
                    Icon(
                      SavingCategoryUtils.getCategoryIcon(category),
                      color: SavingCategoryUtils.getCategoryColor(category),
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
                  _selectedIcon = SavingCategoryUtils.getCategoryIcon(newValue);
                  _selectedColor = SavingCategoryUtils.getCategoryColor(newValue);
                });
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSavingNameField(){
    return TextFormField(
      controller: _savingNameController,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.title),
        labelText: 'Saving Title',
        hintText: 'Eg. Trip to Japan',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.text,
      validator: _savingTitleValidator,
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _savingNameController.text = newValue;
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
        labelText: 'Savings Amount (RM)',
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
            const SizedBox(height: 16),
            _buildPreviewHeader(),
            const SizedBox(height: 16),
            _buildSavingProgress(),
            const SizedBox(height: 16),
            _buildProgressDetail(),
            const SizedBox(height: 8),
            _buildSavingButton(),
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_savingNameController.text != '')...[
                Text(
                  _savingNameController.text,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ]
              else ...[
                Text(
                  'Saving Title',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],

              const SizedBox(height: 4),
              Text(
                'Target date: ${DateFormat('MMM dd, yyyy').format(_endDate)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if(_amountController.text != '')...[
              Text(
                'RM ${_amountController.text}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ]
            else...[
              Text(
                'RM 0.00',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '0%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
            ),
          ],
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

  Widget _buildSavingProgress() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final remainAmount = amount;

    return LinearProgressIndicator(
        value: 0,
        backgroundColor: Colors.grey[200],
        valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(0)),
        minHeight: 8,
        borderRadius: BorderRadius.circular(4),
      );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return Colors.green;
    if (progress < 0.7) return Colors.orange;
    return Colors.red;
  }

  Widget _buildProgressDetail(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Saved: RM 0.00',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        if(_amountController.text != '')...[
          Text(
            'Remaining: RM ${_amountController.text}',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ]
        else ...[
          Text(
            'Remaining: RM 0.00',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSavingButton(){
    final daysRemaining = _endDate.difference(_startDate).inDays;
    final categoryName = _categoryController.text;
    final categoryColor = SavingCategoryUtils.getCategoryColor(categoryName);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$daysRemaining days remaining',
          style: TextStyle(
            color: daysRemaining < 30
                ? Colors.orange
                : Colors.grey[600],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: categoryColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              )
            ]
          ),
          child: const Text(
            'Add Money',
            style: TextStyle(
              color: Colors.white, // Text color
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    bool isFormValid = _formKey.currentState?.validate() ?? false;
    return FloatingActionButton(
      onPressed: isFormValid ? _saveSaving : null,
      shape: CircleBorder(),
      backgroundColor: isFormValid ? Colors.purple[100] : Colors.grey[300],
      child: const Icon(Icons.check),
    );
  }
}
