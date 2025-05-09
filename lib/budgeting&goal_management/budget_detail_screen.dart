import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mobile_app_assignment/category_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';

class BudgetDetailScreen extends StatefulWidget {
  const BudgetDetailScreen({super.key});

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  // firebase integration
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //Display details initialization
  String category = '';
  String budgetName = '';
  String dueDate = '';
  String duration = '';
  String customDay = '';
  String amount = '';
  String remark = '';
  late IconData _selectedIcon;
  late Color _selectedColor;
  late DateTime _focusedDay;  //for calendar
  late DateTime _selectedDay; //for calendar
  DateTime _startDate = DateTime.now(); // Default to current date
  late DateTime _endDate;
  final DateTime _stoppedDate = DateTime.now();
  final DateTime _selectedDate = DateTime.now();
  String _status = '';
  late DurationCategory _selectedDuration;
  bool _isRecurring = false;
  bool _isDeleting = false;

  BudgetModel? _budget;
  bool _isLoading = true;
  String? _errorMessage;

  // ========== INITIALIZATION =========
  @override
  void initState() {  //set default value
    super.initState();

    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _loadArguments();
  }

  void _loadArguments() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments == null){
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
        if (arguments['budget'] != null) {
          budget = arguments['budget'] as BudgetModel;
        }
      }

      if (budget == null){
        setState(() {
          _errorMessage = 'Invalid budget data format';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _budget = budget!;
        category= budget.budgetCategory;
        budgetName = budget.budgetName;
        amount = budget.targetAmount.toStringAsFixed(2);
        remark = budget.remark ?? '';
        duration = budget.duration.name;
        _selectedIcon = CategoryUtils.getCategoryIcon(budget.budgetCategory);
        _selectedColor = CategoryUtils.getCategoryColor(budget.budgetCategory);
        _startDate = budget.startDate;
        _endDate = budget.endDate;
        _selectedDuration = budget.duration;
        _isRecurring = budget.isRecurring;
        _status = budget.status.name;

        dueDate = DateFormat('MMM dd, yyyy').format(budget.endDate);

        // Update duration controller if custom
        if (budget.duration == DurationCategory.custom) {
          customDay = budget.customDays?.toString() ??
              budget.endDate.difference(budget.startDate).inDays.toString();
        }

        _isLoading = false;
      });
    });
  }

  // Extension on each Title
  final Map<String, bool> _expandedSections = {
    'deadline': true,
    'progress': true,
    'duration': true,
    'remark': true,
    'expenses': true,
  };

  // ==========================
  //      BUSINESS LOGIC
  // ==========================
  void _handleMenuSelection(String value) {
    switch (value) {
      case 'settings':
        Navigator.pushNamed(context, '/settings');
        break;
      case 'editing':
        _navigateToEditBudget(_budget!);
        break;
      case 'stopping':
        stopBudget();
        break;
      case 'continue':
        continueBudget();
        break;
      case 'deleting':
        _confirmDeleteBudget();
        break;
    }
  }

  String _assignedDuration(String duration){
    switch(duration){
      case 'daily' :
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'custom':
        return 'Customize: $customDay days';
      default:
        return '';
    }
  }

  // Helper to calculate y-axis interval dynamically
  double _calculateInterval(Iterable<double> amounts) {
    final maxAmount = amounts.reduce((a, b) => a > b ? a : b);
    if (maxAmount <= 10) return 2;
    if (maxAmount <= 50) return 5;
    if (maxAmount <= 100) return 10;
    return 20; // Default for larger values
  }

  void _navigateToExpenses(){
    Navigator.pushNamed(context, '/expense_list');
  }

  void _navigateToEditBudget(BudgetModel budget){
    Navigator.pushNamed(
      context,
      '/budget_edit',
      arguments: {
        'budget': budget,
        'selectedDate': _selectedDate,
      },
    );
  }

  Future<void> stopBudget() async {
    try {
      // 1. Validate if budget exists and is active
      if (_budget == null || !_budget!.isActive) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No active budget to stop')),
        );
        return;
      }

      // 2. Update budget status in local state
      setState(() {
        _status = Status.stopped.name;
        _stoppedDate: DateTime.now(); // Mark when it was stopped
      });

      // 3. Persist to database (example using Firestore)
      await FirebaseFirestore.instance
          .collection('budgets')
          .doc(_budget!.budgetId)
          .update({
        'status': _status,
        'stoppedDate': Timestamp.fromDate(_stoppedDate),
      });

      // 4. Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Budget stopped successfully')),
      );

      // 5. Trigger refresh
      if (mounted) {
        Navigator.pop(context); // Close budget detail view if needed
      }
    } catch (e) {
      // 6. Error handling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to stop budget: ${e.toString()}')),
      );
      debugPrint('Error stopping budget: $e');
    }
  }

  Future<void> continueBudget() async {
    try {
      // 1. Validate if budget exists and is stopped
      if (_budget == null || _status != Status.stopped.name) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No stopped budget to continue')),
        );
        return;
      }

      // 2. Update budget status in local state
      setState(() {
        _status = Status.active.name;
      });

      // 3. Persist to database
      await FirebaseFirestore.instance
          .collection('budgets')
          .doc(_budget!.budgetId)
          .update({
        'status': _status,
        'stoppedDate': null, // Remove end date
      });

      // 4. Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Budget resumed successfully')),
      );

      // 5. Trigger refresh
      if (mounted) {
        Navigator.pop(context); // Optional: Close detail view
      }
    } catch (e) {
      // 6. Error handling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resume budget: ${e.toString()}')),
      );
      debugPrint('Error resuming budget: $e');
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
    if (_budget == null) return;

    setState(() => _isDeleting = true);

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final budgetData = {
        'status': 'deleted',
      };
      await _firestore.collection('budgets').doc(_budget!.budgetId).update(budgetData);

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

  // ========== Helper Methods ==========
  SpendingData _calculateSpendingData(List<TransactionModel> transactions, BudgetModel budget) {
    final spentPerCategory = <String, double>{};
    double totalSpent = 0.0;
    final firstDay = DateTime(budget.startDate.year, budget.startDate.month, 1);
    final lastDay = DateTime(budget.startDate.year, budget.startDate.month + 1, 0, 23, 59, 59);

    if (transactions.isEmpty) {
      return SpendingData(
        totalAllocated: budget.targetAmount,
        totalSpent: 0.0,
        spentPerBudgetCategory: {budget.budgetCategory: 0.0},
      );
    }

    for (final txn in transactions) {
      totalSpent += txn.amount.abs();
      spentPerCategory.update(
        txn.category,
            (value) => value + txn.amount.abs(),
        ifAbsent: () => txn.amount.abs(),
      );
    }

    return SpendingData(
      totalAllocated: budget.targetAmount,
      totalSpent: totalSpent,
      spentPerBudgetCategory: spentPerCategory,
    );
  }

  // ==========================
  //        UI ELEMENTS
  // ==========================
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
      title: Row(
        children: [
          _buildBudgetName(),
          const SizedBox(width: 8),
          _buildIsRecurring(),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert),
          onSelected: (String value) {
            _handleMenuSelection(value);
          },
          itemBuilder: (BuildContext context) =>
          [
            PopupMenuItem<String>(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings, size: 20, color: Colors.grey,),
                title: Text('Settings'),
                dense: true,
              ),
            ),
            PopupMenuItem<String>(
              value: 'editing',
              child: ListTile(
                leading: Icon(Icons.edit, size: 20, color: Colors.blue,),
                title: Text('Editing'),
                dense: true,
              ),
            ),

            if (_status == Status.active.name)
              PopupMenuItem<String>(
                value: 'stopping',
                child: ListTile(
                  leading: Icon(Icons.stop_circle, size: 20, color: Colors.red),
                  title: Text('Stop Budget'),
                  dense: true,
                ),
              )
            else
              PopupMenuItem<String>(
                value: 'continue',
                child: ListTile(
                  leading: Icon(Icons.play_circle, size: 20, color: Colors.green),
                  title: Text('Continue Budget'),
                  dense: true,
                ),
              ),
            PopupMenuItem<String>(
              value: 'deleting',
              child: ListTile(
                leading: Icon(Icons.delete_rounded, size: 20, color: Colors.red,),
                title: Text('Delete budget'),
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(){
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_budget == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return const Center(child: Text('Please sign in'));
    }

    final stream = _firestore
        .collection('transactions')
        .where('userId', isEqualTo: _auth.currentUser?.uid ?? 'invalid')
        .where('isExpense', isEqualTo: true)
        .where('category', isEqualTo: _budget!.budgetCategory)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, transactionSnapshot){
          if (transactionSnapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (_errorMessage != null) {
            return Center(child: Text(_errorMessage!));
          }

          if (_budget == null) {
            return const Center(child: Text('No budget data available'));
          }

          // For display calendar
          final transactionDates = transactionSnapshot.data?.docs
              .map((doc) {
            try {
              return TransactionModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('Error creating transaction: $e');
              return null;
            }
          })
              .where((txn) =>
              txn != null &&
              txn.category == _budget?.budgetCategory&&
              txn.date.isAfter(_startDate.subtract(const Duration(seconds: 1))) &&
              txn.date.isBefore(_endDate.add(const Duration(seconds: 1)))
          )
              .map((txn) => txn!.date)
              .toList() ?? [];

          // For expenses list
          final expenses = transactionSnapshot.data!.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .where((txn) =>
          txn.category == _budget?.budgetCategory &&
              txn.date.isAfter(_startDate.subtract(Duration(seconds: 1))) &&
              txn.date.isBefore(_endDate.add(Duration(seconds: 1))))
              .toList();

          final spendingData = _calculateSpendingData(
            expenses,
            _budget!,
          );

          final spent = spendingData.spentPerBudgetCategory[category] ?? 0.0;
          final targetAmount = double.tryParse(amount) ?? 0.0;
          final amountProgress = targetAmount > 0 ? spent / targetAmount : 0.0;
          final categoryColor = CategoryUtils.getCategoryColor(category);
          final remainAmount = targetAmount - spent;

          // Calculate progress values
          final totalDuration = _endDate.difference(_startDate);
          final elapsedDuration = DateTime.now().difference(_startDate);
          final dateProgress = elapsedDuration.inSeconds / totalDuration.inSeconds;
          final percentage = (dateProgress * 100).clamp(0, 100).toInt();
          final remainDays = _endDate.difference(DateTime.now()).inDays;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildCategoryNameField(),
                    Spacer(),
                    _buildStatusIndicator(_status),
                  ],
                ),

                //Deadline
                const SizedBox(height: 16),
                _buildBudgetDeadlineTitle(),
                if (_expandedSections['deadline']!) ...[
                  const SizedBox(height: 16),
                  _buildCalendar(transactionDates),
                  const SizedBox(height: 16),
                  _buildBudgetDeadline(dateProgress),
                  const SizedBox(height: 8),
                  _buildDeadlineText(_startDate, _endDate, percentage, dateProgress),
                  const SizedBox(height: 16),
                  _buildRemainDays(remainDays),
                ],

                //Progression
                const SizedBox(height: 16),
                _buildBudgetProgressTitle(),
                if (_expandedSections['progress']!) ...[
                  const SizedBox(height: 16),
                  _buildProgressBar(amountProgress, categoryColor),
                  const SizedBox(height: 8),
                  _buildProgressText(spent, targetAmount),
                  const SizedBox(height: 16),
                  _buildRemainAmount(remainAmount),
                  const SizedBox(height: 75),
                  _buildExpenseChart(expenses),
                ],

                //Duration
                const SizedBox(height: 16),
                _buildDurationTitle(),
                if (_expandedSections['duration']!) ...[
                  const SizedBox(height: 8),
                  _buildDuration(duration),
                ],

                //Remark
                const SizedBox(height: 16),
                if(remark.isNotEmpty)...[
                  _buildRemarkTitle(),
                  if (_expandedSections['remark']!) ...[
                    const SizedBox(height: 8),
                    _buildRemarkText(remark),
                  ],
                ],

                //Expenses
                const SizedBox(height: 16),
                if (expenses.isNotEmpty)...[
                  _buildExpensesTitle(),
                  if (_expandedSections['expenses']!)...[
                    const SizedBox(height: 8),
                    _buildExpensesList(expenses),
                  ],
                ],
              ],
            ),
          );
        }
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildBudgetName(){
    return Text(
      budgetName,
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildIsRecurring(){
    if (_isRecurring){
      return Container(
        margin: const EdgeInsets.only(right: 12), // optional spacing
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.purple.shade100, // background color
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.repeat,
          color: Colors.purple, // icon color
        ),
      );
    }
    return SizedBox.shrink();
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
        child: Row(
          children: [
            Icon(
              CategoryUtils.getCategoryIcon(category),
              color: CategoryUtils.getCategoryColor(category),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                category,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
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
      alignment: Alignment.center,
      width: 120,
      height: 60,
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
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetProgressTitle(){
    return InkWell(
      onTap: () {
        setState(() {
          _expandedSections['progress'] = !_expandedSections['progress']!;
        });
      },
      child: Row(
        children: [
          Text(
            'Progression',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
          Icon(
            _expandedSections['progress']!
                ? Icons.expand_less
                : Icons.expand_more,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress, Color categoryColor) {
    return LinearProgressIndicator(
      value: progress,
      backgroundColor: Colors.grey[200],
      valueColor: AlwaysStoppedAnimation<Color>(
        _getProgressColor(progress),
      ),
      minHeight: 10,
      borderRadius: BorderRadius.circular(4),
    );
  }

  Widget _buildProgressText(double spent, double target) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'RM ${spent.toStringAsFixed(2)} of RM ${target.toStringAsFixed(2)}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        Text(
          '${((spent / target) * 100).toStringAsFixed(2)}%',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _getProgressColor(spent / target),
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

  Widget _buildRemainAmount(double remainAmount){
    return Row(
      children: [
        Text('Remaining Amount: RM ${remainAmount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetDeadlineTitle(){
    return InkWell(
      onTap: (){
        setState(() {
          _expandedSections['deadline'] = !_expandedSections['deadline']!;
        });
      },
      child: Row(
        children: [
          Text(
            'Deadline',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
          Icon(
            _expandedSections['deadline']!
                ? Icons.expand_less
                : Icons.expand_more,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(List<DateTime> transactionDates){
    return Column(
      children: [
        TableCalendar(
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          firstDay: _startDate.subtract(const Duration(days: 30)),
          lastDay: _endDate.add(const Duration(days: 30)),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          calendarStyle: CalendarStyle(
            selectedDecoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.blue.shade200,
              shape: BoxShape.circle,
            ),
            rangeStartDecoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            rangeEndDecoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            withinRangeDecoration: BoxDecoration(
              color: Colors.transparent,
            ),
            markerDecoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            defaultTextStyle: TextStyle(color: Colors.black),
            weekendTextStyle: TextStyle(color: Colors.black),
          ),
          rangeStartDay: _startDate,
          rangeEndDay: _endDate,
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (transactionDates.any((d) => isSameDay(d, date))) {
                return Positioned(
                  bottom: 1,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }
              return null;
            },
          ),
        ),
        _buildCalendarLegend(),
      ],
    );
  }

  Widget _buildCalendarLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildLegendItem(
          color: Colors.green,
          text: 'Start Date',
        ),
        _buildLegendItem(
          color: Colors.red,
          text: 'End Date',
        ),
        _buildLegendItem(
          color: Colors.blue,
          text: 'Selected Day',
        ),
        _buildLegendItem(
          color: Colors.blue.shade200,
          text: 'Today',
        ),
        _buildLegendItem(
          color: Colors.blue.shade100,
          text: 'Budget Period',
        ),
        _buildLegendItem(
          color: Colors.orange,
          text: 'Transaction',
        ),
      ],
    );
  }

  Widget _buildLegendItem({required Color color, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildBudgetDeadline(double progress) {
    return
      LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.grey[200],
        valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(progress)),
        minHeight: 10,
        borderRadius: BorderRadius.circular(4),
      );
  }

  Widget _buildDeadlineText(DateTime startDate, DateTime endDate, int percentage, double progress) {
    // Format dates
    final startDateFormatted = DateFormat('dd/MM/yyyy').format(startDate);
    final endDateFormatted = DateFormat('dd/MM/yyyy').format(endDate);

    return Row(
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
          '${percentage.toStringAsFixed(2)}%',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _getProgressColor(progress),
          ),
        ),
      ],
    );
  }

  Widget _buildRemainDays(int remainDays) {
    final now = DateTime.now();
    final remainingDuration = _endDate.difference(now);
    final totalSeconds = remainingDuration.inSeconds;

    // Calculate all time units
    final days = remainingDuration.inDays;
    final hours = remainingDuration.inHours % 24;
    final minutes = remainingDuration.inMinutes % 60;
    final seconds = remainingDuration.inSeconds % 60;

    String remainingText;
    TextStyle textStyle;

    if (days > 0) {
      remainingText = 'Remaining: $days day${days != 1 ? 's' : ''}';
      textStyle = TextStyle(fontSize: 16, color: Colors.blue);
    }
    else if (remainingDuration.inHours > 0) {
      remainingText = 'Remaining: ${remainingDuration.inHours} hour${remainingDuration.inHours != 1 ? 's' : ''}';
      textStyle = TextStyle(fontSize: 16, color: Colors.blue);
    }
    else if (remainingDuration.inMinutes > 0) {
      remainingText = 'Remaining: ${remainingDuration.inMinutes} minute${remainingDuration.inMinutes != 1 ? 's' : ''}';
      textStyle = TextStyle(fontSize: 16, color: Colors.orange);
    }
    else if (totalSeconds > 0) {
      remainingText = 'Remaining: $seconds second${seconds != 1 ? 's' : ''}';
      textStyle = TextStyle(fontSize: 16, color: Colors.orange);
    }
    else {
      remainingText = 'Budget has ended';
      textStyle = TextStyle(fontSize: 16, color: Colors.red);
    }

    return Row(
      children: [
        Text(remainingText, style: textStyle),
      ],
    );
  }

  Widget _buildDurationTitle(){
    return InkWell(
      onTap: () {
        setState(() {
          _expandedSections['duration'] = !_expandedSections['duration']!;
        });
      },
      child: Row(
        children: [
          Text(
            'Duration',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
          Icon(
            _expandedSections['duration']!
                ? Icons.expand_less
                : Icons.expand_more,
          ),
        ],
      ),
    );
  }

  Widget _buildDuration(String duration){
    return Row(
      children: [
        Text(_assignedDuration(duration),
          style: TextStyle(
            fontSize: 16,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildRemarkTitle(){
    return InkWell(
      onTap: () {
        setState(() {
          _expandedSections['remark'] = !_expandedSections['remark']!;
        });
      },
      child: Row(
        children: [
          Text(
            'Remark',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
          Icon(
            _expandedSections['remark']!
                ? Icons.expand_less
                : Icons.expand_more,
          ),
        ],
      ),
    );
  }

  Widget _buildRemarkText(String remark){
    return Row(
      children: [
        Text(remark,
          style: TextStyle(
            fontSize: 16,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildExpensesTitle(){
    return InkWell(
      onTap: () {
        setState(() {
          _expandedSections['expenses'] = !_expandedSections['expenses']!;
        });
      },
      child: Row(
        children: [
          Text(
            'Expenses',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
          Icon(
            _expandedSections['expenses']!
                ? Icons.expand_less
                : Icons.expand_more,
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesList(List<TransactionModel> expenses){
    // Sort expenses by date (newest first)
    expenses.sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: expenses.length,
      itemBuilder: (context, index) => _buildExpenseItem(expenses[index]),
    );
  }

  Widget _buildExpenseItem(TransactionModel expense) {
    final categoryColor = CategoryUtils.getCategoryColor(expense.category);
    final icon = CategoryUtils.getCategoryIcon(expense.category);
    final formattedDate = DateFormat('MMM dd, yyyy').format(expense.date);
    final formattedTime = DateFormat('hh:mm a').format(expense.date);

    return GestureDetector(
      onTap: () => _navigateToExpenses(),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                children: [
                  Icon(
                    icon,
                    color: categoryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    expense.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: categoryColor,
                    ),
                  ),
                  Spacer(),
                  Text(
                    '-RM ${expense.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    formattedDate,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    formattedTime,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseChart(List<TransactionModel> expenses) {
    // Handle null or empty expenses
    if (expenses.isEmpty) {
      return SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) => Text(''), // Empty but keeps space
                ),
                axisNameWidget: const Text(
                  'Date',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) => Text('${value.toInt()}'),
                  reservedSize: 32,
                  interval: 10, // Default interval
                ),
                axisNameWidget: const Text(
                  'Amount',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            gridData: const FlGridData(show: true),
            borderData: FlBorderData(show: true),
            barGroups: [], // No bars
          ),
        ),
      );
    }

    // Group expenses by day
    final dailyExpenses = <DateTime, double>{};
    for (final expense in expenses) {
      final date = DateTime(expense.date.year, expense.date.month, expense.date.day);
      dailyExpenses.update(
        date,
            (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    // Convert to chart data
    final sortedDates = dailyExpenses.keys.toList()..sort();
    final barGroups = sortedDates.asMap().entries.map((entry) {
      final date = entry.value;
      final amount = dailyExpenses[date]!;
      final dayLabel = DateFormat('dd').format(date);

      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: amount,
            color: CategoryUtils.getCategoryColor(_budget!.budgetCategory),
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
        showingTooltipIndicators: [0],
      );
    }).toList();

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barGroups: barGroups,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value >= 0 && value < sortedDates.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        DateFormat('dd MMM').format(sortedDates[value.toInt()]), // Format: "05 Jun"
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
              axisNameWidget: const Text(
                'Date',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  );
                },
                reservedSize: 32, // Adjust space for y-axis labels
                interval: _calculateInterval(dailyExpenses.values), // Dynamic interval
              ),
              axisNameWidget: const Text(
                'Amount',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
          ),
          gridData: const FlGridData(show: true), // Show grid lines for clarity
          borderData: FlBorderData(
            show: true, // Show chart border
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
        ),
      ),
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
            backgroundColor: Colors.red,
            shape: CircleBorder(),
            child: Icon(Icons.delete_rounded, color: Colors.white),
          ),
          FloatingActionButton(
            onPressed: () => _navigateToEditBudget(_budget!),
            backgroundColor: Colors.green,
            shape: CircleBorder(),
            child: Icon(Icons.edit, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ========== Helper Classes ==========
class SpendingData {
  final double totalAllocated;
  final double totalSpent;
  final Map<String, double> spentPerBudgetCategory;
  //final Map<String, double> spentPerBudget;Z

  SpendingData({
    required this.totalAllocated,
    required this.totalSpent,
    required this.spentPerBudgetCategory,
    //required this.spentPerBudget,
  });
}

class ExpenseChartData {
  final String day;
  final double amount;
  final Color color;

  ExpenseChartData(this.day, this.amount, this.color);
}