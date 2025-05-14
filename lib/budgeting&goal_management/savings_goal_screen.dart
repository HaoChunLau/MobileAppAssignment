import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app_assignment/utils/category_utils.dart';
import 'package:mobile_app_assignment/models/savings_goal_model.dart';
import 'package:mobile_app_assignment/utils/sorting_utils.dart';

class SavingsGoalScreen extends StatefulWidget {
  const SavingsGoalScreen({super.key});

  @override
  State<SavingsGoalScreen> createState() => _SavingsGoalScreenState();
}

class _SavingsGoalScreenState extends State<SavingsGoalScreen> {
  int _currentIndex = 4;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Search properties
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  bool _isSearchVisible = false;
  SortingOptions _sortingOptions = const SortingOptions();

  // Filter Properties
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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
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
        floatingActionButton: _buildAddButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Savings Goals'),
      automaticallyImplyLeading: false,
      actions: [
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert),
          onSelected: (String value) {
            _handleMenuSelection(value);
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'search',
              child: ListTile(
                leading: Icon(Icons.search, size: 20),
                title: Text('Search'),
                dense: true,
              ),
            ),
            PopupMenuItem<String>(
              value: 'sort',
              child: ListTile(
                leading: Icon(Icons.sort, size: 20),
                title: Text('Sort by'),
                dense: true,
              ),
            ),
            PopupMenuItem<String>(
              value: 'filter',
              child: ListTile(
                leading: Icon(Icons.filter_alt_rounded, size: 20),
                title: Text('Filter'),
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          if (_isSearchVisible) _buildSearchContent(context),
          _buildGoalsList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.savings,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Savings Goals Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first savings goal\nto start tracking your progress',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToAddGoalScreen,
            icon: const Icon(Icons.add),
            label: const Text('Add New Goal'),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('savings')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return ErrorWidget(snapshot.error!);
        if (!snapshot.hasData) return _buildLoadingIndicator();

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState();

        List<SavingsGoalModel> savingsList = docs
            .map((doc) {
              final goal = SavingsGoalModel.fromFirestore(doc);
              // Update status for each goal when loading
              goal.updateStatus();
              return goal;
            })
            .where((goal) =>
                _searchTerm.isEmpty ||
                goal.title.toLowerCase().contains(_searchTerm.toLowerCase()) ||
                (goal.remark
                        ?.toLowerCase()
                        .contains(_searchTerm.toLowerCase()) ??
                    false))
            .toList();

        savingsList = _applyFilters(savingsList);

        final sortedSavings = SortingUtils.sortSavings(
          savings: savingsList,
          options: _sortingOptions,
          currentDate: DateTime.now(),
        );

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: sortedSavings.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildGoalsItem(sortedSavings[index]),
          ),
        );
      },
    );
  }

  Widget _buildGoalsItem(SavingsGoalModel goal) {
    final progress = goal.currentSaved / goal.targetAmount;
    final remainingAmount = goal.targetAmount - goal.currentSaved;

    final remainingTime = goal.targetDate.difference(DateTime.now());
    final daysRemaining = remainingTime.inDays;
    final hoursRemaining = remainingTime.inHours % 24;
    final minutesRemaining = remainingTime.inMinutes % 24;
    final secondsRemaining = remainingTime.inSeconds % 24;

    final color = SavingCategoryUtils.getCategoryColor(goal.goalCategory);
    final icon = SavingCategoryUtils.getCategoryIcon(goal.goalCategory);

    return Card(
      // Removed Expanded
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/savings_progress', arguments: goal);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Target date: ${DateFormat('MMM dd, yyyy').format(goal.targetDate)}',
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
                      Text(
                        'RM ${goal.targetAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: progress > 0.7 ? Colors.green : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress > 0.7 ? Colors.green : color,
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saved: RM ${goal.currentSaved.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Remaining: RM ${remainingAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (remainingAmount == 0)
                    Text('Target Achieve!')
                  else if (daysRemaining > 0)
                    Text(
                      '$daysRemaining days remaining',
                      style: TextStyle(
                        color: daysRemaining < 30
                            ? Colors.orange
                            : Colors.grey[600],
                      ),
                    )
                  else if (remainingTime.inHours > 0)
                    Text(
                      '$hoursRemaining hours remaining',
                      style: TextStyle(color: Colors.orange),
                    )
                  else if (remainingTime.inMinutes > 0)
                    Text(
                      '$minutesRemaining minutes remaining',
                      style: TextStyle(color: Colors.orange),
                    )
                  else if (remainingTime.inSeconds > 0)
                    Text(
                      '$secondsRemaining seconds remaining',
                      style: TextStyle(color: Colors.orange),
                    )
                  else
                    Text(
                      'Goal date passed',
                      style: TextStyle(
                        color: Colors.red[400],
                      ),
                    ),

                  if(goal.status == Status.active)...[
                    ElevatedButton(
                      onPressed: () => _showAddContributionDialog(goal),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Add Money'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  FloatingActionButton _buildAddButton() {
    return FloatingActionButton(
      onPressed: _navigateToAddGoalScreen,
      shape: CircleBorder(),
      child: const Icon(Icons.add),
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

  // ========= Loading UI =========
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Loading your savings goals...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  //======== Sort Content ========
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

  // ==========Search Content ==========
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
            // Adjust this value to move icons left/right
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
            _searchTerm = value; // Update search term on input change
          });
        },
      ),
    );
  }

  // ============ Categories Filter ==============
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
          selectedColor:
              SavingCategoryUtils.getCategoryColor(category).withOpacity(0.2),
          checkmarkColor: SavingCategoryUtils.getCategoryColor(category),
          backgroundColor: Colors.grey[200],
          labelStyle: TextStyle(
            color: isSelected
                ? SavingCategoryUtils.getCategoryColor(category)
                : Colors.black,
          ),
        );
      }).toList(),
    );
  }

  // =============== Amount range ==================
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
              // Auto-format to 2 decimal places
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
              // Auto-format to 2 decimal places
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

  // ================ DATE RANGE FILTER ===================
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

  // ========= Popup Windows for more action ========
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

  void _navigateToAddGoalScreen() {
    Navigator.pushNamed(context, '/savings_add');
  }

//========== Sorting Method ============
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

  // ========== Filter Method ==========
  // Extension on each Title in filtering
  final Map<String, bool> _expandedSections = {
    'categories': true,
    'amount_range': false,
    'date_range': false,
  };

  void _showFilterDialog(BuildContext context) {
    final allCategories = SavingCategoryUtils.categories;

    // Clear controllers and set initial values
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
                    // Category Filter
                    _buildCategoriesFilter(dialogSelectedCategories,
                        allCategories, dialogSetState),
                    const SizedBox(height: 16),

                    // Amount Range Filter
                    _buildAmountRangeFilter(dialogSetState),
                    const SizedBox(height: 16),

                    // Date Range Filter
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
                        _filterStartDate =
                            DateTime.tryParse(_startDateController.text);
                        _filterEndDate =
                            DateTime.tryParse(_endDateController.text);
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

    // Reset errors
    _minAmountError = null;
    _maxAmountError = null;

    if (minValue.isEmpty && maxValue.isEmpty) {
      _minAmountError = null;
      _maxAmountError = null;
      amtSetState(() {});
      return;
    }

    // Validate min amount
    if (minValue.isNotEmpty) {
      if (min == null) {
        _minAmountError = 'Enter a valid number';
      } else if (min < 0) {
        _minAmountError = 'Cannot be negative';
      }
    }

    // Validate max amount
    if (maxValue.isNotEmpty) {
      if (max == null) {
        _maxAmountError = 'Enter a valid number';
      } else if (max < 0) {
        _maxAmountError = 'Cannot be negative';
      }
    }

    // Validate min < max
    if (min != null && max != null && max < min) {
      _maxAmountError = 'Max must be above Min';
    }

    if (_minAmountError != null || _maxAmountError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors before applying')),
      );
      return;
    }

    // Update the state to show errors
    amtSetState(() {});
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

  List<SavingsGoalModel> _applyFilters(List<SavingsGoalModel> savings) {
    if (!_isFilterActive) return savings;

    return savings.where((savings) {
      // Category filter
      if (_selectedCategories.isNotEmpty &&
          !_selectedCategories.contains(savings.goalCategory)) {
        return false;
      }

      // Amount range filter
      if (savings.targetAmount < _minAmount ||
          savings.targetAmount > _maxAmount) {
        return false;
      }

      // Date range filter
      if (_filterStartDate != null &&
          savings.targetDate.isBefore(_filterStartDate!)) {
        return false;
      }
      if (_filterEndDate != null &&
          savings.startDate.isAfter(_filterEndDate!)) {
        return false;
      }

      return true;
    }).toList();
  }

  void _showAddContributionDialog(SavingsGoalModel goal) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final color = SavingCategoryUtils.getCategoryColor(goal.goalCategory);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Money to ${goal.title}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress information
              Row(
                children: [
                  Icon(Icons.savings, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${(goal.currentSaved / goal.targetAmount * 100).toStringAsFixed(1)}% completed',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: goal.currentSaved / goal.targetAmount,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              const SizedBox(height: 16),
              Text(
                'Saved: RM ${goal.currentSaved.toStringAsFixed(2)} '
                'of RM ${goal.targetAmount.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),

              // Amount input field with validation
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount to Add (RM)',
                  border: OutlineInputBorder(),
                  prefixText: 'RM ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid positive amount';
                  }
                  if (goal.currentSaved + amount > goal.targetAmount) {
                    return 'Amount exceeds remaining target';
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final amount = double.parse(amountController.text);

                final newContribution = SavingsContribution(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  goalId: goal.savingGoalId.toString(),
                  amount: amount,
                  date: DateTime.now(),
                  note: noteController.text,
                  type: 'deposit',
                );

                try {
                  // Add contribution document
                  await _firestore
                      .collection('contributions')
                      .doc(newContribution.id)
                      .set(newContribution.toMap());

                  // Update savings goal document's currentSaved field
                  await _firestore
                      .collection('savings')
                      .doc(goal.savingGoalId)
                      .update({
                    'currentSaved': FieldValue.increment(amount),
                    'lastUpdated': FieldValue.serverTimestamp(),
                  });

                  // After both succeed, close dialog and show success snackbar
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'RM ${amount.toStringAsFixed(2)} added to ${goal.title}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  // Handle errors in either operation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to add contribution: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Money'),
          )
        ],
      ),
    );
  }

  void _handleBottomNavigationTap(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/transactions');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/budget_overview');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/reports_overview');
    } else {
      setState(() => _currentIndex = index);
    }
  }
}

class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final DateTime targetDate;
  final IconData icon;
  final Color color;

  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    required this.targetDate,
    required this.icon,
    required this.color,
  });
}