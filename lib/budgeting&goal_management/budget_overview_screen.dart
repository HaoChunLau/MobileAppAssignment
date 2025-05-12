import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app_assignment/utils/category_utils.dart';
import 'package:mobile_app_assignment/models/budget_model.dart';
import 'package:mobile_app_assignment/models/transaction_model.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:mobile_app_assignment/utils/sorting_utils.dart';

class BudgetOverviewScreen extends StatefulWidget {
  const BudgetOverviewScreen({super.key});

  @override
  State<BudgetOverviewScreen> createState() => _BudgetOverviewScreenState();
}

class _BudgetOverviewScreenState extends State<BudgetOverviewScreen>
    with SingleTickerProviderStateMixin {
  // ========== Constants and Properties ==========
  static const _budgetTabIndex = 2;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DateTime _selectedDate = DateTime.now();
  int _currentIndex = _budgetTabIndex;

  BudgetModel? budgetPassing;

  late TabController _tabController;
  int _activeTabIndex = 0;

  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  bool _isSearchVisible = false;
  SortingOptions _sortingOptions = const SortingOptions();

  List<String> _selectedCategories = [];
  double _minAmount = 0;
  double _maxAmount = double.infinity;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  bool _isFilterActive = false;
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();
  String? _minAmountError;
  String? _maxAmountError;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  String? _startDateError;
  String? _endDateError;

  bool _isLoading = true; // New manual loading state

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _activeTabIndex = _tabController.index;
      });
    });

    // Initial fetch without setState, rely on StreamBuilder
    _updateAllBudgetsCurrentSpent();

    Timer.periodic(Duration(hours: 1), (timer) {
      _checkAndUpdateAllBudgets();
      _handleRecurringBudgets();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _updateAllBudgetsCurrentSpent() async {
    final budgets = await _firestore
        .collection('budgets')
        .where('userId', isEqualTo: _auth.currentUser?.uid)
        .get();

    final batch = _firestore.batch();

    for (var doc in budgets.docs) {
      final budget = BudgetModel.fromFirestore(doc);
      await updateCurrentSpent(budget);
      batch.update(doc.reference, {
        'currentSpent': budget.currentSpent,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    // No setState here; StreamBuilder will handle updates
  }

  Future<void> _checkAndUpdateAllBudgets() async {
    final budgets = await _firestore
        .collection('budgets')
        .where('userId', isEqualTo: _auth.currentUser?.uid)
        .where('status', isEqualTo: 'active')
        .get();

    final batch = _firestore.batch();

    for (var doc in budgets.docs) {
      final budget = BudgetModel.fromFirestore(doc);
      final previousStatus = budget.status;

      await updateCurrentSpent(budget);
      budget.updateStatus(currentDate: _selectedDate);

      if (budget.status != previousStatus) {
        batch.update(doc.reference, {
          'status': budget.status.name,
          'currentSpent': budget.currentSpent
        });
      }
    }

    await batch.commit();
  }

  Future<void> _handleRecurringBudgets() async {
    final now = DateTime.now();
    final budgets = await _firestore
        .collection('budgets')
        .where('userId', isEqualTo: _auth.currentUser?.uid)
        .where('isRecurring', isEqualTo: true)
        .where('endDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .get();

    final batch = _firestore.batch();

    for (var doc in budgets.docs) {
      final budget = BudgetModel.fromFirestore(doc);

      final duration = budget.endDate.difference(budget.startDate);
      final newStartDate = budget.endDate.add(Duration(days: 1));
      final newEndDate = newStartDate.add(duration);

      final newBudget = {
        'budgetId': _firestore.collection('budgets').doc().id,
        'budgetCategory': budget.budgetCategory,
        'budgetName': budget.budgetName,
        'targetAmount': budget.targetAmount,
        'remark': budget.remark,
        'duration': budget.duration.name, // Use enum name
        'customDays': budget.customDays,
        'startDate': Timestamp.fromDate(newStartDate),
        'endDate': Timestamp.fromDate(newEndDate),
        'userId': budget.userId,
        'status': 'active',
        'isRecurring': budget.isRecurring,
        'nextOccurrence': Timestamp.fromDate(_calculateNextOccurrence(
            budget.duration, newEndDate,
            customDay: budget.customDays)),
      };

      batch.set(
          _firestore.collection('budgets').doc(newBudget['budgetId'] as String),
          newBudget);
    }

    await batch.commit();
  }

  DateTime _calculateNextOccurrence(DurationCategory duration, DateTime endDate,
      {int? customDay}) {
    switch (duration) {
      case DurationCategory.daily:
        return endDate.add(const Duration(days: 1));
      case DurationCategory.weekly:
        return endDate.add(const Duration(days: 7));
      case DurationCategory.monthly:
        final nextMonth = endDate.month + 1;
        final nextYear = endDate.year + (nextMonth > 12 ? 1 : 0);
        final adjustedMonth = nextMonth > 12 ? nextMonth - 12 : nextMonth;
        return DateTime(
          nextYear,
          adjustedMonth,
          min(endDate.day, DateUtils.getDaysInMonth(nextYear, adjustedMonth)),
        );
      case DurationCategory.custom:
        final days = customDay ?? 0;
        return endDate.add(Duration(days: days));
    }
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'search':
        setState(() {
          _isSearchVisible = !_isSearchVisible;
          if (!_isSearchVisible) {
            _searchController.clear();
            _searchTerm = '';
          }
        });
        break;
      case 'sort':
        _showSortDialog(context);
        break;
      case 'filter':
        _showFilterDialog(context);
        break;
    }
  }

  void _showSortDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _buildSortDialogContent(context);
      },
    );
  }

  void _applySorting(SortingOptions newOptions) {
    setState(() {
      _sortingOptions = newOptions;
    });
  }

  void _showFilterDialog(BuildContext context) {
    final allCategories = CategoryUtils.allCategories;

    _minAmountController.text =
        _minAmount > 0 ? _minAmount.toStringAsFixed(2) : '';
    _maxAmountController.text =
        _maxAmount < double.infinity ? _maxAmount.toStringAsFixed(2) : '';
    _startDateController.text = _filterStartDate != null
        ? DateFormat('dd/MM/yyyy').format(_filterStartDate!)
        : '';
    _endDateController.text = _filterEndDate != null
        ? DateFormat('dd/MM/yyyy').format(_filterEndDate!)
        : '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        List<String> dialogSelectedCategories = List.from(_selectedCategories);

        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: const Text('Filter Budgets'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCategoriesFilter(dialogSelectedCategories,
                        allCategories, dialogSetState),
                    const SizedBox(height: 16),
                    _buildAmountRangeFilter(dialogSetState),
                    const SizedBox(height: 16),
                    _buildDateRangeFilter(dialogSetState),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    dialogSetState(() {
                      dialogSelectedCategories.clear();
                      _minAmountController.clear();
                      _maxAmountController.clear();
                      _startDateController.clear();
                      _endDateController.clear();
                      _minAmountError = null;
                      _maxAmountError = null;
                      _filterStartDate = null;
                      _filterEndDate = null;
                      _startDateError = null;
                      _endDateError = null;
                    });
                  },
                  child: const Text('Reset All'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    _validateAmounts(_minAmountController.text,
                        _maxAmountController.text, dialogSetState);
                    _validateDateRange();

                    if (_minAmountError == null &&
                        _maxAmountError == null &&
                        _startDateError == null &&
                        _endDateError == null) {
                      setState(() {
                        _selectedCategories = dialogSelectedCategories;
                        _minAmount = _minAmountController.text.isEmpty
                            ? 0
                            : double.parse(_minAmountController.text);
                        _maxAmount = _maxAmountController.text.isEmpty
                            ? double.infinity
                            : double.parse(_maxAmountController.text);
                        _filterStartDate = _startDateController.text.isNotEmpty
                            ? DateFormat('dd/MM/yyyy')
                                .parse(_startDateController.text)
                            : null;
                        _filterEndDate = _endDateController.text.isNotEmpty
                            ? DateFormat('dd/MM/yyyy')
                                .parse(_endDateController.text)
                            : null;
                        _isFilterActive = dialogSelectedCategories.isNotEmpty ||
                            _minAmount > 0 ||
                            _maxAmount < double.infinity ||
                            _filterStartDate != null ||
                            _filterEndDate != null;
                      });
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _validateAmounts(
      String minValue, String maxValue, StateSetter amtSetState) {
    final min = double.tryParse(minValue);
    final max = double.tryParse(maxValue);

    _minAmountError = null;
    _maxAmountError = null;

    if (minValue.isEmpty && maxValue.isEmpty) {
      amtSetState(() {});
      return;
    }

    if (minValue.isNotEmpty) {
      if (min == null) {
        _minAmountError = 'Enter a valid number';
      } else if (min < 0) {
        _minAmountError = 'Cannot be negative';
      }
    }

    if (maxValue.isNotEmpty) {
      if (max == null) {
        _maxAmountError = 'Enter a valid number';
      } else if (max < 0) {
        _maxAmountError = 'Cannot be negative';
      }
    }

    if (min != null && max != null && max < min) {
      _maxAmountError = 'Max must be above Min';
    }

    if (_minAmountError != null || _maxAmountError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors before applying')),
      );
      amtSetState(() {});
    }
  }

  void _validateDateRange() {
    _startDateError = null;
    _endDateError = null;

    if (_filterStartDate != null && _filterEndDate != null) {
      if (_filterStartDate!.isAfter(_filterEndDate!)) {
        _startDateError = 'Start Date must be before End Date';
        _endDateError = 'End Date must be after Start Date';
      }
    }
  }

  List<BudgetModel> _applyFilters(List<BudgetModel> budgets) {
    if (!_isFilterActive) return budgets;

    return budgets.where((budget) {
      if (_selectedCategories.isNotEmpty &&
          !_selectedCategories.contains(budget.budgetCategory)) {
        return false;
      }

      if (budget.targetAmount < _minAmount ||
          budget.targetAmount > _maxAmount) {
        return false;
      }

      if (_filterStartDate != null &&
          budget.endDate.isBefore(_filterStartDate!)) {
        return false;
      }
      if (_filterEndDate != null && budget.startDate.isAfter(_filterEndDate!)) {
        return false;
      }

      return true;
    }).toList();
  }

  Stream<QuerySnapshot> getBudgetStream(DateTime selectedDate,
      {List<String>? statuses}) {
    var query = _firestore
        .collection('budgets')
        .where('userId', isEqualTo: _auth.currentUser?.uid)
        .where('startDate',
            isLessThanOrEqualTo: Timestamp.fromDate(
                DateTime(selectedDate.year, selectedDate.month + 1, 0)))
        .where('endDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(
                DateTime(selectedDate.year, selectedDate.month, 1)));

    if (statuses != null && statuses.isNotEmpty) {
      query = query.where('status', whereIn: statuses);
    }

    return query.snapshots();
  }

  Stream<QuerySnapshot> getTransactionStream(
      {String? budgetId, DateTime? startDate, DateTime? endDate}) {
    var query = _firestore
        .collection('transactions')
        .where('userId', isEqualTo: _auth.currentUser?.uid)
        .where('isExpense', isEqualTo: true);

    if (budgetId != null) {
      query = query.where('budgetId', isEqualTo: budgetId);
    }

    if (startDate != null) {
      query = query.where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query =
          query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildBody(),
        floatingActionButton: _buildCreateBudgetButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text('Budget - ${DateFormat('MMM yyyy').format(_selectedDate)}'),
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () => _selectMonth(context),
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert),
          onSelected: (String value) {
            _handleMenuSelection(value);
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
                value: 'search',
                child: ListTile(
                  leading: Icon(
                    _isSearchVisible ? Icons.search_off : Icons.search,
                    size: 20,
                  ),
                  title: Text(_isSearchVisible ? 'Cancel Searching' : 'Search'),
                  dense: true,
                )),
            PopupMenuItem<String>(
                value: 'sort',
                child: ListTile(
                  leading: Icon(Icons.sort, size: 20),
                  title: Text('Sort by'),
                  dense: true,
                )),
            PopupMenuItem<String>(
                value: 'filter',
                child: ListTile(
                  leading: Icon(Icons.filter_alt_rounded, size: 20),
                  title: Text('Filter'),
                  dense: true,
                )),
          ],
        ),
      ],
      bottom: TabBar(
        tabAlignment: TabAlignment.center,
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Colors.blue,
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Active'),
          Tab(text: 'Completed'),
          Tab(text: 'Failed'),
          Tab(text: 'Stopped'),
          Tab(text: 'Deleted'),
        ],
        onTap: (index) {
          setState(() {
            _activeTabIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        if (_isSearchVisible) _buildSearchContent(context),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAllBudgetsTab(),
              _buildActiveBudgetsTab(),
              _buildCompletedBudgetsTab(),
              _buildFailedBudgetsTab(),
              _buildStoppedBudgetsTab(),
              _buildDeletedBudgetsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllBudgetsTab() {
    List<String> selectedStatuses = [
      'active',
      'completed',
      'failed',
      'stopped',
      'deleted'
    ];
    return StreamBuilder<QuerySnapshot>(
      stream: getBudgetStream(_selectedDate, statuses: selectedStatuses),
      builder: (context, snapshot) {
        List<BudgetModel> budgets = (snapshot.data?.docs ?? [])
            .map((doc) {
              var budget = BudgetModel.fromFirestore(doc);
              budget.updateStatus(currentDate: _selectedDate);
              return budget;
            })
            .where((budget) =>
                _searchTerm.isEmpty ||
                budget.budgetName
                    .toLowerCase()
                    .contains(_searchTerm.toLowerCase()) ||
                (budget.remark
                        ?.toLowerCase()
                        .contains(_searchTerm.toLowerCase()) ??
                    false))
            .toList();

        budgets = _applyFilters(budgets);

        return _buildBudgetContent(budgets);
      },
    );
  }

  Widget _buildActiveBudgetsTab() {
    List<String> selectedStatuses = ['active'];
    return StreamBuilder<QuerySnapshot>(
      stream: getBudgetStream(_selectedDate, statuses: selectedStatuses),
      builder: (context, snapshot) {
        List<BudgetModel> activeBudgets = (snapshot.data?.docs ?? [])
            .map((doc) => BudgetModel.fromFirestore(doc))
            .where((budget) =>
                _searchTerm.isEmpty ||
                budget.budgetName
                    .toLowerCase()
                    .contains(_searchTerm.toLowerCase()) ||
                (budget.remark
                        ?.toLowerCase()
                        .contains(_searchTerm.toLowerCase()) ??
                    false))
            .toList();

        activeBudgets = _applyFilters(activeBudgets);

        return _buildBudgetContent(activeBudgets);
      },
    );
  }

  Widget _buildCompletedBudgetsTab() {
    List<String> selectedStatuses = ['completed'];
    return StreamBuilder<QuerySnapshot>(
      stream: getBudgetStream(_selectedDate, statuses: selectedStatuses),
      builder: (context, snapshot) {
        List<BudgetModel> completedBudgets = (snapshot.data?.docs ?? [])
            .map((doc) => BudgetModel.fromFirestore(doc))
            .where((budget) =>
                _searchTerm.isEmpty ||
                budget.budgetName
                    .toLowerCase()
                    .contains(_searchTerm.toLowerCase()) ||
                (budget.remark
                        ?.toLowerCase()
                        .contains(_searchTerm.toLowerCase()) ??
                    false))
            .toList();

        completedBudgets = _applyFilters(completedBudgets);

        return _buildBudgetContent(completedBudgets);
      },
    );
  }

  Widget _buildFailedBudgetsTab() {
    List<String> selectedStatuses = ['failed'];
    return StreamBuilder<QuerySnapshot>(
      stream: getBudgetStream(_selectedDate, statuses: selectedStatuses),
      builder: (context, snapshot) {
        List<BudgetModel> failedBudgets = (snapshot.data?.docs ?? [])
            .map((doc) => BudgetModel.fromFirestore(doc))
            .where((budget) =>
                _searchTerm.isEmpty ||
                budget.budgetName
                    .toLowerCase()
                    .contains(_searchTerm.toLowerCase()) ||
                (budget.remark
                        ?.toLowerCase()
                        .contains(_searchTerm.toLowerCase()) ??
                    false))
            .toList();

        failedBudgets = _applyFilters(failedBudgets);

        return _buildBudgetContent(failedBudgets);
      },
    );
  }

  Widget _buildStoppedBudgetsTab() {
    List<String> selectedStatuses = ['stopped'];
    return StreamBuilder<QuerySnapshot>(
      stream: getBudgetStream(_selectedDate, statuses: selectedStatuses),
      builder: (context, snapshot) {
        List<BudgetModel> stoppedBudgets = (snapshot.data?.docs ?? [])
            .map((doc) => BudgetModel.fromFirestore(doc))
            .where((budget) =>
                _searchTerm.isEmpty ||
                budget.budgetName
                    .toLowerCase()
                    .contains(_searchTerm.toLowerCase()) ||
                (budget.remark
                        ?.toLowerCase()
                        .contains(_searchTerm.toLowerCase()) ??
                    false))
            .toList();

        stoppedBudgets = _applyFilters(stoppedBudgets);

        return _buildBudgetContent(stoppedBudgets);
      },
    );
  }

  Widget _buildDeletedBudgetsTab() {
    List<String> selectedStatuses = ['deleted'];
    return StreamBuilder<QuerySnapshot>(
      stream: getBudgetStream(_selectedDate, statuses: selectedStatuses),
      builder: (context, snapshot) {
        List<BudgetModel> deletedBudgets = (snapshot.data?.docs ?? [])
            .map((doc) => BudgetModel.fromFirestore(doc))
            .where((budget) =>
                _searchTerm.isEmpty ||
                budget.budgetName
                    .toLowerCase()
                    .contains(_searchTerm.toLowerCase()) ||
                (budget.remark
                        ?.toLowerCase()
                        .contains(_searchTerm.toLowerCase()) ??
                    false))
            .toList();

        deletedBudgets = _applyFilters(deletedBudgets);

        return _buildBudgetContent(deletedBudgets);
      },
    );
  }

  Widget _buildBudgetContent(List<BudgetModel> budgets) {
    String statusTab = '';
    return StreamBuilder<QuerySnapshot>(
      stream: getTransactionStream(
        startDate: DateTime(_selectedDate.year, _selectedDate.month, 1),
        endDate: DateTime(
            _selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59),
      ),
      builder: (context, transactionSnapshot) {
        // Show loading only for initial fetch
        if (_isLoading &&
            transactionSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        // Turn off loading after first snapshot
        if (_isLoading &&
            transactionSnapshot.connectionState != ConnectionState.waiting) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          });
        }

        // Handle error state
        if (transactionSnapshot.hasError) {
          return _buildErrorState(transactionSnapshot.error);
        }

        // Handle no data (null or empty snapshot)
        if (!transactionSnapshot.hasData || transactionSnapshot.data == null) {
          return _buildEmptyState('Transactions');
        }

        // Handle empty budgets case
        if (budgets.isEmpty) {
          switch (_activeTabIndex) {
            case 0:
              statusTab = 'All';
              break;
            case 1:
              statusTab = 'Active';
              break;
            case 2:
              statusTab = 'Completed';
              break;
            case 3:
              statusTab = 'Failed';
              break;
            case 4:
              statusTab = 'Stopped';
              break;
            case 5:
              statusTab = 'Deleted';
              break;
          }
          return _buildEmptyState(statusTab);
        }

        // Process transactions
        final allTransactions = transactionSnapshot.data!.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList();

        // Calculate totalSpent for the monthly overview
        final totalSpent =
            allTransactions.fold(0.0, (total, txn) => total + txn.amount);

        // Filter transactions for budget-specific spending
        final expenses = allTransactions
            .where((txn) =>
                budgets.any((budget) => budget.budgetId == txn.budgetId) &&
                txn.date.isAfter((txn.budgetId != null
                        ? budgets
                            .firstWhere((b) => b.budgetId == txn.budgetId)
                            .startDate
                        : DateTime.now())
                    .subtract(const Duration(seconds: 1))) &&
                txn.date.isBefore((txn.budgetId != null
                        ? budgets
                            .firstWhere((b) => b.budgetId == txn.budgetId)
                            .endDate
                        : DateTime.now())
                    .add(const Duration(seconds: 1))))
            .toList();

        final spendingData = _calculateSpendingData(expenses, budgets);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverallBudgetCard(spendingData.totalAllocated, totalSpent),
              const SizedBox(height: 24),
              _buildCategorySection(),
              const SizedBox(height: 16),
              _buildBudgetList(budgets, spendingData.spentPerBudget),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  SpendingData _calculateSpendingData(
      List<TransactionModel>? transactionList, List<BudgetModel> budgets) {
    Map<String, double> spentPerCategory = {};
    Map<String, double> spentPerBudget = {};
    double totalSpent = 0;

    if (transactionList != null) {
      for (var transaction in transactionList) {
        spentPerCategory[transaction.category] =
            (spentPerCategory[transaction.category] ?? 0) + transaction.amount;
        if (transaction.budgetId != null) {
          spentPerBudget[transaction.budgetId!] =
              (spentPerBudget[transaction.budgetId!] ?? 0) + transaction.amount;
        }
      }
    }

    double totalAllocated =
        budgets.fold(0, (total, item) => total + item.targetAmount);

    return SpendingData(
      totalAllocated: totalAllocated,
      totalSpent: totalSpent,
      spentPerCategory: spentPerCategory,
      spentPerBudget: spentPerBudget,
    );
  }

  Future<void> updateCurrentSpent(BudgetModel budget) async {
    final budgetDocRef = _firestore.collection('budgets').doc(budget.budgetId);

    final transactions = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: _auth.currentUser?.uid)
        .where('budgetId', isEqualTo: budget.budgetId)
        .where('isExpense', isEqualTo: true)
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(budget.startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(budget.endDate))
        .get();

    double currentSpent = transactions.docs.fold(0.0, (accumulatedTotal, doc) {
      final amount = (doc.data()['amount'] as num).toDouble();
      return accumulatedTotal + amount;
    });

    await budgetDocRef.update({
      'currentSpent': currentSpent,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    budget.currentSpent = currentSpent;
    budget.updateStatus();
  }

  Future<void> updateFailedStatus(BudgetModel budget) async {
    try {
      DateTime failedDate = DateTime.now();
      String status = Status.failed.name;

      await FirebaseFirestore.instance
          .collection('budgets')
          .doc(budget.budgetId)
          .update({
        'status': status,
        'overDate': Timestamp.fromDate(failedDate),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to change budget status: ${e.toString()}')),
      );
    }
  }

  Widget _buildErrorState(dynamic error) {
    return Center(child: Text('Error: $error'));
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyState(String statusFilter) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            statusFilter == 'All'
                ? 'No Budgets Yet'
                : 'No $statusFilter Budgets',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first budget to start tracking',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCreateBudgetButton() {
    return FloatingActionButton(
      shape: CircleBorder(),
      onPressed: () {
        Navigator.pushNamed(
          context,
          '/budget_add',
          arguments: {'selectedDate': _selectedDate},
        );
      },
      child: const Icon(Icons.add),
    );
  }

  Widget _buildOverallBudgetCard(double totalAllocated, double totalSpent) {
    double percentUsed = totalAllocated > 0 ? (totalSpent / totalAllocated) : 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Budget Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBudgetInfoColumn('Allocated',
                    'RM ${totalAllocated.toStringAsFixed(2)}', Colors.blue),
                _buildBudgetInfoColumn(
                    'Spent', 'RM ${totalSpent.toStringAsFixed(2)}', Colors.red),
                _buildBudgetInfoColumn(
                    'Remaining',
                    'RM ${(totalAllocated - totalSpent).toStringAsFixed(2)}',
                    Colors.green),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Overall Progress',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentUsed,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                percentUsed > 0.9 ? Colors.red : Colors.blue,
              ),
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 8),
            Text(
              '${(percentUsed * 100).toInt()}% of budget used',
              style: TextStyle(
                color: percentUsed > 0.9 ? Colors.red : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetInfoColumn(String title, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(amount,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildCategorySection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Categories',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBudgetList(
      List<BudgetModel> budgets, Map<String, double> spentPerBudget) {
    final sortedBudgets = SortingUtils.sortBudgets(
      budgets: budgets,
      options: _sortingOptions,
      spentPerCategory: spentPerBudget,
      currentDate: _selectedDate,
    );

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedBudgets.length,
      itemBuilder: (context, index) =>
          _buildBudgetItem(sortedBudgets[index], spentPerBudget),
    );
  }

  Widget _buildBudgetItem(
      BudgetModel budget, Map<String, double> spentPerBudget) {
    final spent = spentPerBudget[budget.budgetId] ?? budget.currentSpent;
    final progress =
        budget.targetAmount > 0 ? spent / budget.targetAmount : 0.0;
    final categoryColor = CategoryUtils.getCategoryColor(budget.budgetCategory);

    budget.updateStatus(spent: spent);

    return GestureDetector(
      onTap: () => _navigateToBudgetDetail(budget),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStatusIndicator(budget.status.name),
                  Spacer(),
                  _buildRepeatIcon(budget.isRecurring),
                ],
              ),
              const SizedBox(height: 16),
              _buildBudgetHeader(budget),
              const SizedBox(height: 16),
              _buildProgressInfo(spent, budget.targetAmount, progress),
              const SizedBox(height: 8),
              _buildProgressBar(progress, categoryColor),
              const SizedBox(height: 4),
              _buildProgressDetail(spent, budget.targetAmount),
              const SizedBox(height: 16),
              _buildBudgetDeadline(budget.startDate, budget.endDate),
            ],
          ),
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
      decoration: BoxDecoration(
        color: statusColor.withAlpha((0.2 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: statusColor.withAlpha((0.5 * 255).round()), width: 1),
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

  Widget _buildRepeatIcon(bool isRepeat) {
    final baseColor = isRepeat ? Colors.purple : Colors.grey;
    return Tooltip(
      message: isRepeat ? 'Repeat Budget' : 'One-time Budget',
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: baseColor
              .withAlpha((0.2 * 255).round()), // replaces withOpacity(0.2)
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.repeat,
          size: 20,
          color: baseColor,
        ),
      ),
    );
  }

  Widget _buildBudgetHeader(BudgetModel budget) {
    return Row(
      children: [
        _buildCategoryIcon(budget),
        const SizedBox(width: 12),
        Flexible(
          child: _buildBudgetTitle(budget),
        ),
        const Spacer(),
        _buildEditButton(budget),
      ],
    );
  }

  Widget _buildCategoryIcon(BudgetModel budget) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: CategoryUtils.getCategoryColor(budget.budgetCategory)
            .withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        CategoryUtils.getCategoryIcon(budget.budgetCategory),
        color: CategoryUtils.getCategoryColor(budget.budgetCategory),
      ),
    );
  }

  Widget _buildBudgetTitle(BudgetModel budget) {
    return Row(
      children: [
        Flexible(
          child: Text(
            budget.budgetName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEditButton(BudgetModel budget) {
    return IconButton(
      icon: const Icon(Icons.edit, size: 20),
      onPressed: () => _navigateToEditBudget(budget),
    );
  }

  Widget _buildProgressInfo(
      double spent, double targetAmount, double progress) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'RM ${spent.toStringAsFixed(2)} of RM ${targetAmount.toStringAsFixed(2)}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        Text(
          '${(progress * 100).toInt()}%',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _getProgressTextColor(progress),
          ),
        ),
      ],
    );
  }

  Color _getProgressTextColor(double progress) {
    if (progress > 0.9) return Colors.red;
    if (progress > 0.75) return Colors.orange;
    return Colors.black;
  }

  Widget _buildProgressBar(double progress, Color categoryColor) {
    return LinearProgressIndicator(
      value: progress,
      backgroundColor: Colors.grey[200],
      valueColor: AlwaysStoppedAnimation<Color>(
        _getProgressColor(progress),
      ),
      minHeight: 8,
      borderRadius: BorderRadius.circular(4),
    );
  }

  Widget _buildProgressDetail(double spent, double targetAmount) {
    final remainAmount = targetAmount - spent;

    return Row(
      children: [
        Text(
          'Remaining Amount: RM ${remainAmount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            color: Colors.purple,
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

  Widget _buildBudgetDeadline(DateTime startDate, DateTime endDate) {
    final totalDuration = endDate.difference(startDate);
    final elapsedDuration = DateTime.now().difference(startDate);
    final progress = elapsedDuration.inSeconds / totalDuration.inSeconds;
    final percentage = (progress * 100).clamp(0, 100).toInt();

    final startDateFormatted = DateFormat('dd/MM/yyyy').format(startDate);
    final endDateFormatted = DateFormat('dd/MM/yyyy').format(endDate);

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
              '${percentage.clamp(0, 100).toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getProgressColor(progress),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor:
              AlwaysStoppedAnimation<Color>(_getProgressColor(progress)),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        _buildRemainDays(endDate),
      ],
    );
  }

  Widget _buildRemainDays(DateTime endDate) {
    final now = DateTime.now();
    final remainingDuration = endDate.difference(now);
    final isPast = remainingDuration.isNegative;
    final totalSeconds = remainingDuration.inSeconds;

    final days = remainingDuration.inDays;
    final hours = remainingDuration.inHours % 24;
    final minutes = remainingDuration.inMinutes % 60;
    final seconds = remainingDuration.inSeconds % 60;

    String remainingText;
    TextStyle textStyle;

    if (isPast) {
      remainingText = 'Budget has ended';
      textStyle = TextStyle(fontSize: 16, color: Colors.red);
    } else if (days > 0) {
      remainingText = 'Remaining: $days day${days != 1 ? 's' : ''}';
      textStyle = TextStyle(fontSize: 16, color: Colors.blue);
    } else if (remainingDuration.inHours > 0) {
      remainingText = 'Remaining: $hours hour${hours != 1 ? 's' : ''}';
      textStyle = TextStyle(fontSize: 16, color: Colors.blue);
    } else if (remainingDuration.inMinutes > 0) {
      remainingText = 'Remaining: $minutes minute${minutes != 1 ? 's' : ''}';
      textStyle = TextStyle(fontSize: 16, color: Colors.orange);
    } else if (totalSeconds > 0) {
      remainingText = 'Remaining: $seconds second${seconds != 1 ? 's' : ''}';
      textStyle = TextStyle(fontSize: 16, color: Colors.orange);
    } else {
      remainingText = 'Budget has ended';
      textStyle = TextStyle(fontSize: 16, color: Colors.red);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Text(remainingText, style: textStyle),
        ],
      ),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _handleBottomNavigationTap,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet), label: 'Transactions'),
        BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Budget'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reports'),
        BottomNavigationBarItem(icon: Icon(Icons.savings), label: 'Savings'),
      ],
    );
  }

  void _handleBottomNavigationTap(int index) {
    if (index == 0) {
      Navigator.pushNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushNamed(context, '/transactions');
    } else if (index == 3) {
      Navigator.pushNamed(context, '/reports_overview');
    } else if (index == 4) {
      Navigator.pushNamed(context, '/savings_goal');
    } else {
      setState(() => _currentIndex = index);
      // Only update if necessary, e.g., on explicit refresh
    }
  }

  void _navigateToEditBudget(BudgetModel budget) {
    Navigator.pushNamed(
      context,
      '/budget_edit',
      arguments: {
        'budget': budget,
        'selectedDate': _selectedDate,
      },
    );
  }

  void _navigateToBudgetDetail(BudgetModel budget) {
    Navigator.pushNamed(
      context,
      '/budget_detail',
      arguments: {
        'budget': budget,
        'selectedDate': _selectedDate,
      },
    );
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showMonthPicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _isLoading = true; // Reset loading state for new month
      });
    }
  }

  Widget _buildSortDialogContent(BuildContext context) {
    SortCategory currentCategory = _sortingOptions.category;
    SortDirection currentDirection = _sortingOptions.direction;

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Sort By'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...SortCategory.values.map((category) {
                return RadioListTile<SortCategory>(
                  title: Row(
                    children: [
                      Icon(SortingUtils.getSortCategoryIcon(category)),
                      const SizedBox(width: 8),
                      Text(SortingUtils.getSortCategoryName(category)),
                    ],
                  ),
                  value: category,
                  groupValue: currentCategory,
                  onChanged: (SortCategory? value) {
                    setState(() => currentCategory = value!);
                  },
                );
              }),
              const Divider(),
              RadioListTile<SortDirection>(
                title: const Text('Ascending'),
                value: SortDirection.ascending,
                groupValue: currentDirection,
                onChanged: (SortDirection? value) {
                  setState(() => currentDirection = value!);
                },
              ),
              RadioListTile<SortDirection>(
                title: const Text('Descending'),
                value: SortDirection.descending,
                groupValue: currentDirection,
                onChanged: (SortDirection? value) {
                  setState(() => currentDirection = value!);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _applySorting(SortingOptions(
                    category: currentCategory,
                    direction: currentDirection,
                  ));
                });
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        keyboardType: TextInputType.text,
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name... ',
          prefixIcon: Icon(Icons.search),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _searchController.clear();
                        _searchTerm = '';
                      });
                    },
                    child: const Icon(Icons.arrow_back),
                  ),
                if (_searchController.text.isEmpty)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSearchVisible = false;
                        _searchController.clear();
                        _searchTerm = '';
                      });
                    },
                    child: const Icon(Icons.close),
                  ),
              ],
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          filled: true,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        onChanged: (value) {
          setState(() {
            _searchTerm = value;
          });
        },
      ),
    );
  }

  final Map<String, bool> _expandedSections = {
    'categories': true,
    'amount_range': false,
    'date_range': false,
  };

  Widget _buildCategoriesFilter(
      List<String> selected, List<String> all, StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoriesDialogTitle(setState),
        if (_expandedSections['categories']!) ...[
          const SizedBox(height: 8),
          _buildCategoriesFilterContent(all, selected, setState),
        ]
      ],
    );
  }

  Widget _buildCategoriesDialogTitle(StateSetter catSetState) {
    return InkWell(
      onTap: () {
        catSetState(() {
          _expandedSections['categories'] = !_expandedSections['categories']!;
        });
      },
      child: Row(children: [
        Text(
          'Categories',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        Icon(
          _expandedSections['categories']!
              ? Icons.expand_less
              : Icons.expand_more,
        ),
      ]),
    );
  }

  Widget _buildCategoriesFilterContent(List<String> allCategories,
      List<String> selectedCategories, StateSetter catSetState) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allCategories.map((category) {
        final isSelected = selectedCategories.contains(category);
        return FilterChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (selectedVal) {
            catSetState(() {
              if (selectedVal) {
                selectedCategories.add(category);
              } else {
                selectedCategories.remove(category);
              }
            });
          },
          selectedColor: CategoryUtils.getCategoryColor(category)
              .withAlpha((0.2 * 255).round()),
          checkmarkColor: CategoryUtils.getCategoryColor(category),
          backgroundColor: Colors.grey[200],
          labelStyle: TextStyle(
            color: isSelected
                ? CategoryUtils.getCategoryColor(category)
                : Colors.black,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAmountRangeFilter(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAmountRangeTitle(setState),
        if (_expandedSections['amount_range']!) ...[
          const SizedBox(height: 8),
          _buildAmountRangeFilterContent(setState),
        ]
      ],
    );
  }

  Widget _buildAmountRangeTitle(StateSetter amtSetState) {
    return InkWell(
      onTap: () {
        amtSetState(() {
          _expandedSections['amount_range'] =
              !_expandedSections['amount_range']!;
        });
      },
      child: Row(children: [
        Text(
          'Amount Range',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        Icon(
          _expandedSections['amount_range']!
              ? Icons.expand_less
              : Icons.expand_more,
        ),
      ]),
    );
  }

  Widget _buildAmountRangeFilterContent(StateSetter amtSetState) {
    return Column(
      children: [
        TextField(
          controller: _minAmountController,
          decoration: InputDecoration(
            labelText: 'Min Amount (RM)',
            border: const OutlineInputBorder(),
            errorText: _minAmountError,
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            TextInputFormatter.withFunction((oldValue, newValue) {
              if (newValue.text.contains('.')) {
                final parts = newValue.text.split('.');
                if (parts[1].length > 2) {
                  return oldValue;
                }
              }
              return newValue;
            }),
          ],
          onChanged: (value) {
            _validateAmounts(value, _maxAmountController.text, amtSetState);
          },
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _maxAmountController,
          decoration: InputDecoration(
            labelText: 'Max Amount (RM)',
            border: const OutlineInputBorder(),
            errorText: _maxAmountError,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            TextInputFormatter.withFunction((oldValue, newValue) {
              if (newValue.text.contains('.')) {
                final parts = newValue.text.split('.');
                if (parts[1].length > 2) {
                  return oldValue;
                }
              }
              return newValue;
            }),
          ],
          onChanged: (value) {
            _validateAmounts(_minAmountController.text, value, amtSetState);
          },
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateRangeTitle(setState),
        if (_expandedSections['date_range']!) ...[
          const SizedBox(height: 8),
          _buildDateRangeFilterContent(setState),
        ]
      ],
    );
  }

  Widget _buildDateRangeTitle(StateSetter dateSetState) {
    return InkWell(
      onTap: () {
        dateSetState(() {
          _expandedSections['date_range'] = !_expandedSections['date_range']!;
        });
      },
      child: Row(children: [
        Text(
          'Date Range',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        Icon(
          _expandedSections['date_range']!
              ? Icons.expand_less
              : Icons.expand_more,
        ),
      ]),
    );
  }

  Widget _buildDateRangeFilterContent(StateSetter dateSetState) {
    return Column(
      children: [
        TextField(
          controller: _startDateController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Start Date',
            suffixIcon: Icon(Icons.calendar_today),
            border: OutlineInputBorder(),
            errorText: _startDateError,
          ),
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _filterStartDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (pickedDate != null) {
              dateSetState(() {
                _filterStartDate = pickedDate;
                _startDateController.text =
                    DateFormat('dd/MM/yyyy').format(pickedDate);
                _validateDateRange();
              });
            }
          },
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _endDateController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'End Date',
            suffixIcon: Icon(Icons.calendar_today),
            border: OutlineInputBorder(),
            errorText: _endDateError,
          ),
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _filterEndDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (pickedDate != null) {
              dateSetState(() {
                _filterEndDate = pickedDate;
                _endDateController.text =
                    DateFormat('dd/MM/yyyy').format(pickedDate);
                _validateDateRange();
              });
            }
          },
        ),
        const SizedBox(height: 8),
        if (_filterStartDate != null || _filterEndDate != null) ...[
          TextButton(
            onPressed: () {
              dateSetState(() {
                _filterStartDate = null;
                _filterEndDate = null;
                _startDateController.clear();
                _endDateController.clear();
                _startDateError = null;
                _endDateError = null;
              });
            },
            child: const Text('Clear Date Range'),
          ),
        ],
      ],
    );
  }
}

class SpendingData {
  final double totalAllocated;
  final double totalSpent;
  final Map<String, double> spentPerCategory;
  final Map<String, double> spentPerBudget;

  SpendingData({
    required this.totalAllocated,
    required this.totalSpent,
    required this.spentPerCategory,
    required this.spentPerBudget,
  });
}