import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app_assignment/category_utils.dart';
import 'package:mobile_app_assignment/models/budget_model.dart';
import 'package:mobile_app_assignment/models/transaction_model.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

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
  int _currentIndex = _budgetTabIndex; // Make sure index matches Budget tab
  int _activeTabIndex = 0; // Default to first tab (All)

  late TabController _tabController;

  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  bool _isSearchVisible = false;

  // ======= For tab bar ========
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // 5 tabs
    _tabController.addListener(() {
      setState(() {
        _activeTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ========= Popup Windows for more action ========
  void _handleMenuSelection(String value) {
    switch (value) {
      case 'settings':
        Navigator.pushNamed(context, '/settings');
        break;
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
      //filterPopup();
        break;
      case 'history':
        _navigateToBudgetHistory();
        break;
    }
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

  void _performSort(String? sortBy, bool ascending) {
    // This will be implemented in your actual sorting logic
    debugPrint('Sorting by $sortBy in ${ascending
        ? 'ascending'
        : 'descending'} order');
    // Call your actual sort functions here based on the selected option
    switch (sortBy) {
      case 'alphabet':
      // sortAlphabetically(ascending);
        break;
      case 'duration':
      // sortByDuration(ascending);
        break;
      case 'dueDate':
      // sortByDueDate(ascending);
        break;
      case 'process':
      // sortByProcess(ascending);
        break;
      case 'category':
      // sortByCategory(ascending);
        break;
      case 'budgetAmount':
      // sortByBudgetAmount(ascending);
        break;
      default:
      // sortByCreatedDate(descending);
      // No sorting or default sorting
        break;
    }
  }

  void _sortAlphabetically(bool ascending) {
    // Implement alphabetical sorting logic here
  }

  void _sortByDuration(bool ascending) {
    // Implement duration sorting logic here
  }

  void _sortByDueDate(bool ascending) {
    // Implement due date sorting logic here
  }

  void _sortByProcess(bool ascending) {
    // Implement process sorting logic here
  }

  void _sortByCategory(bool ascending) {
    // Implement category sorting logic here
  }

  void _sortByBudgetAmount(bool ascending) {
    // Implement budget amount sorting logic here
  }

  // ======== Search Method ===========
  void _showSearchContent(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildSearchContent(context);
      },
    );
  }

  void _performSearch(String searchTerm) {
    // This is where you handle the search logic
    debugPrint('Search performed with term: $searchTerm');
    // You can add your actual search logic here, e.g., filtering data, calling an API, etc.
  }

  // ========== Main Build Method ==========
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent default pop
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

  // ========== App Bar ==========
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
          itemBuilder: (BuildContext context) =>
          [
            PopupMenuItem<String>(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings, size: 20),
                title: Text('Settings'),
                dense: true,
              ),
            ),
            PopupMenuItem<String>(
                value: 'search',
                child: ListTile(
                  leading: Icon(
                    _isSearchVisible ? Icons.search_off : Icons.search,
                    size: 20,
                  ),
                  title: Text(_isSearchVisible ? 'Cancel Searching' : 'Search'),
                  dense: true,
                )
            ),
            PopupMenuItem<String>(
                value: 'sort',
                child: ListTile(
                  leading: Icon(Icons.sort, size: 20),
                  title: Text('Sort by'),
                  dense: true,
                )
            ),
            PopupMenuItem<String>(
                value: 'filter',
                child: ListTile(
                  leading: Icon(Icons.filter_alt_rounded, size: 20),
                  title: Text('Filter'),
                  dense: true,
                )
            ),
            PopupMenuItem<String>(
                value: 'history',
                child: ListTile(
                  leading: Icon(Icons.history, size: 20),
                  title: Text('View History'),
                  dense: true,
                )
            ),
          ],
        ),
      ],
      bottom: TabBar(
        tabAlignment: TabAlignment.center,
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Colors.blue,
        // Underline color for active tab
        labelColor: Colors.blue,
        // Text color for active tab
        unselectedLabelColor: Colors.grey,
        // Text color for inactive tabs
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Active'),
          Tab(text: 'Completed'),
          Tab(text: 'Failed'),
          Tab(text: 'Deleted'),
        ],
        onTap: (index) {
          setState(() {
            _activeTabIndex = index; // Update the active tab index
          });
        },
      ),
    );
  }

  // ========== Body Content ==========
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
              _buildDeletedBudgetsTab(),
            ],
          ),
        ),
      ],
    );
  }

  //========= Tab control ========
  Widget _buildAllBudgetsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('budgets')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .where('status',
          whereIn: ['active', 'completed', 'failed', 'stopped', 'deleted'])
          .where('startDate', isLessThanOrEqualTo:
      Timestamp.fromDate(
          DateTime(_selectedDate.year, _selectedDate.month + 1, 0)))
          .where('endDate', isGreaterThanOrEqualTo:
      Timestamp.fromDate(DateTime(_selectedDate.year, _selectedDate.month, 1)))
          .snapshots(),
      builder: (context, snapshot) {
        List<BudgetModel> budgets = (snapshot.data?.docs ?? [])
            .map((doc) => BudgetModel.fromFirestore(doc))
            .where((budget) =>
        _searchTerm.isEmpty ||
            budget.budgetCategory.toLowerCase().contains(
                _searchTerm.toLowerCase()) ||
            (budget.remark?.toLowerCase().contains(_searchTerm.toLowerCase()) ??
                false))
            .toList();

        return _buildBudgetContent(budgets);
      },
    );
  }

  Widget _buildActiveBudgetsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('budgets')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .where('status', whereIn: ['active'])
          .where('startDate', isLessThanOrEqualTo:
      Timestamp.fromDate(
          DateTime(_selectedDate.year, _selectedDate.month + 1, 0)))
          .where('endDate', isGreaterThanOrEqualTo:
      Timestamp.fromDate(DateTime(_selectedDate.year, _selectedDate.month, 1)))
          .snapshots(),
      builder: (context, snapshot) {
        // Filtered content for active budgets
        List<BudgetModel> activeBudgets = (snapshot.data?.docs ?? [])
            .map((doc) => BudgetModel.fromFirestore(doc))
            .where((budget) =>
        _searchTerm.isEmpty ||
            budget.budgetCategory.toLowerCase().contains(
                _searchTerm.toLowerCase()) ||
            (budget.remark?.toLowerCase().contains(_searchTerm.toLowerCase()) ??
                false))
            .toList();

        return _buildBudgetContent(activeBudgets);
      },
    );
  }

  Widget _buildCompletedBudgetsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('budgets')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .where('status', isEqualTo: Status.completed)
          .where('startDate', isLessThanOrEqualTo:
      Timestamp.fromDate(
          DateTime(_selectedDate.year, _selectedDate.month + 1, 0)))
          .where('endDate', isGreaterThanOrEqualTo:
      Timestamp.fromDate(DateTime(_selectedDate.year, _selectedDate.month, 1)))
          .snapshots(),
      builder: (context, snapshot) {
        // Filtered content for active budgets
        List<BudgetModel> budgets = (snapshot.data?.docs ?? [])
            .map((doc) => BudgetModel.fromFirestore(doc))
            .where((budget) =>
        _searchTerm.isEmpty ||
            budget.budgetCategory.toLowerCase().contains(
                _searchTerm.toLowerCase()) ||
            (budget.remark?.toLowerCase().contains(_searchTerm.toLowerCase()) ??
                false))
            .toList();

        return _buildBudgetContent(budgets);
      },
    );
  }

  Widget _buildFailedBudgetsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('budgets')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .where('status', isEqualTo: Status.failed)
          .where('startDate', isLessThanOrEqualTo:
      Timestamp.fromDate(
          DateTime(_selectedDate.year, _selectedDate.month + 1, 0)))
          .where('endDate', isGreaterThanOrEqualTo:
      Timestamp.fromDate(DateTime(_selectedDate.year, _selectedDate.month, 1)))
          .snapshots(),
      builder: (context, snapshot) {
        // Filtered content for active budgets
        List<BudgetModel> budgets = (snapshot.data?.docs ?? [])
            .map((doc) => BudgetModel.fromFirestore(doc))
            .where((budget) =>
        _searchTerm.isEmpty ||
            budget.budgetCategory.toLowerCase().contains(
                _searchTerm.toLowerCase()) ||
            (budget.remark?.toLowerCase().contains(_searchTerm.toLowerCase()) ??
                false))
            .toList();

        return _buildBudgetContent(budgets);
      },
    );
  }

  Widget _buildDeletedBudgetsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('budgets')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .where('status', isEqualTo: Status.deleted)
          .where('startDate', isLessThanOrEqualTo:
      Timestamp.fromDate(
          DateTime(_selectedDate.year, _selectedDate.month + 1, 0)))
          .where('endDate', isGreaterThanOrEqualTo:
      Timestamp.fromDate(DateTime(_selectedDate.year, _selectedDate.month, 1)))
          .snapshots(),
      builder: (context, snapshot) {
        // Filtered content for active budgets
        List<BudgetModel> budgets = (snapshot.data?.docs ?? [])
            .map((doc) => BudgetModel.fromFirestore(doc))
            .where((budget) =>
        _searchTerm.isEmpty ||
            budget.budgetCategory.toLowerCase().contains(
                _searchTerm.toLowerCase()) ||
            (budget.remark?.toLowerCase().contains(_searchTerm.toLowerCase()) ??
                false))
            .toList();

        return _buildBudgetContent(budgets);
      },
    );
  }

  //======== Sort Content ========
  Widget _buildSortDialogContent(BuildContext context) {
    String? selectedSortOption; // Currently selected sort option
    bool isAscending = true; // Sort direction

    return AlertDialog(
      title: const Text('Sort By'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sort options radio buttons
          ..._buildSortOptions(selectedSortOption),

          const SizedBox(height: 16),

          const Text(
            'Sort Direction:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Sort direction toggle
          Row(
            children: [
              const SizedBox(width: 16),
              ToggleButtons(
                isSelected: [isAscending, !isAscending],
                onPressed: (index) {
                  isAscending = index == 0;
                  Navigator.of(context).pop();
                  _performSort(selectedSortOption, isAscending);
                },
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Ascending'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Descending'),
                  ),
                ],
              ),
            ],
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
            Navigator.of(context).pop();
            _performSort(selectedSortOption, isAscending);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  List<Widget> _buildSortOptions(String? selectedOption) {
    return [
      RadioListTile<String>(
        title: const Text('Alphabetical'),
        value: 'alphabet',
        groupValue: selectedOption,
        onChanged: (value) => selectedOption = value,
      ),
      RadioListTile<String>(
        title: const Text('Duration'),
        value: 'duration',
        groupValue: selectedOption,
        onChanged: (value) => selectedOption = value,
      ),
      RadioListTile<String>(
        title: const Text('Due Date'),
        value: 'dueDate',
        groupValue: selectedOption,
        onChanged: (value) => selectedOption = value,
      ),
      RadioListTile<String>(
        title: const Text('Process'),
        value: 'process',
        groupValue: selectedOption,
        onChanged: (value) => selectedOption = value,
      ),
      RadioListTile<String>(
        title: const Text('Category'),
        value: 'category',
        groupValue: selectedOption,
        onChanged: (value) => selectedOption = value,
      ),
      RadioListTile<String>(
        title: const Text('Budget Amount'),
        value: 'budgetAmount',
        groupValue: selectedOption,
        onChanged: (value) => selectedOption = value,
      ),
    ];
  }

  // ==========Search Content ==========
  Widget _buildSearchContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        keyboardType: TextInputType.text,
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search...',
          prefixIcon: Icon(Icons.search),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            // Adjust this value to move icons left/right
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _searchController.clear();
                      _searchTerm = '';
                    });
                  },
                  child: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8.0),
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
          fillColor: Theme
              .of(context)
              .scaffoldBackgroundColor,
        ),
        onChanged: (value) {
          setState(() {
            _searchTerm = value; // Update search term on input change
          });
        },
      ),
    );
  }

  // ========== Budget Content ==========
  Widget _buildBudgetContent(List<BudgetModel> budgets) {
    // Get date range from the FIRST budget (assuming same month for all)
    final budgetMonth = budgets.isNotEmpty
        ? DateTime(budgets.first.startDate.year, budgets.first.startDate.month)
        : DateTime.now();

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('transactions')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .where('isExpense', isEqualTo: true)
          .snapshots(),
      builder: (context, transactionSnapshot) {
        if (transactionSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (budgets.isEmpty) {
          return _buildEmptyState();
        }

        final spendingData = _calculateSpendingData(
          transactionSnapshot.data?.docs,
          budgets,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverallBudgetCard(
                  spendingData.totalAllocated, spendingData.totalSpent),
              const SizedBox(height: 24),
              _buildCategorySection(),
              const SizedBox(height: 16),
              _buildBudgetList(budgets, spendingData.spentPerCategory),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ========== Helper Methods ==========
  SpendingData _calculateSpendingData(
      List<QueryDocumentSnapshot>? transactionDocs,
      List<BudgetModel> budgets,) {
    Map<String, double> spentPerCategory = {};
    double totalSpent = 0;

    if (transactionDocs != null) {
      final allTransactions = transactionDocs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();

      // Define the first and last day of the selected month
      final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
      final lastDay = DateTime(
          _selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59);

      // Filter transactions for the selected month
      final currentMonthTransactions = allTransactions.where((txn) =>
      txn.date.isAfter(firstDay.subtract(const Duration(seconds: 1))) &&
          txn.date.isBefore(lastDay.add(const Duration(seconds: 1)))).toList();

      // Calculate total spent using filtered transactions
      totalSpent =
          currentMonthTransactions.fold(0, (sum, txn) => sum + txn.amount);

      // Calculate spent per category using filtered transactions
      for (var transaction in currentMonthTransactions) {
        spentPerCategory[transaction.category] =
            (spentPerCategory[transaction.category] ?? 0) + transaction.amount;
      }
    }

    double totalAllocated = budgets.fold(
        0, (sum, item) => sum + item.targetAmount);

    return SpendingData(
      totalAllocated: totalAllocated,
      totalSpent: totalSpent,
      spentPerCategory: spentPerCategory,
    );
  }

  // ========== UI Components ==========
  Widget _buildErrorState(dynamic error) {
    return Center(child: Text('Error: $error'));
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyState() {
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
          const Text(
            'No Budgets Yet',
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
                _buildBudgetInfoColumn(
                    'Allocated', 'RM ${totalAllocated.toStringAsFixed(2)}',
                    Colors.blue),
                _buildBudgetInfoColumn(
                    'Spent', 'RM ${totalSpent.toStringAsFixed(2)}', Colors.red),
                _buildBudgetInfoColumn('Remaining',
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
        Text(amount, style: TextStyle(
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

  Widget _buildBudgetList(List<BudgetModel> budgets,
      Map<String, double> spentPerCategory) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: budgets.length,
      itemBuilder: (context, index) =>
          _buildBudgetItem(budgets[index], spentPerCategory),
    );
  }

  Widget _buildBudgetItem(BudgetModel budget,
      Map<String, double> spentPerCategory) {
    final spent = spentPerCategory[budget.budgetCategory] ?? 0.0;
    final progress = budget.targetAmount > 0
        ? spent / budget.targetAmount
        : 0.0;

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
                  _buildCategoryIcon(budget),
                  const SizedBox(width: 12),
                  Text(
                    budget.budgetCategory,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _navigateToEditBudget(budget),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RM ${spent.toStringAsFixed(2)} of RM ${budget.targetAmount
                        .toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: progress > 0.9 ? Colors.red : progress > 0.75
                          ? Colors.orange
                          : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress > 0.9 ? Colors.red :
                  progress > 0.75 ? Colors.orange : CategoryUtils
                      .getCategoryColor(budget.budgetCategory),
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      ),
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

  // ========== Bottom Navigation ==========
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

  // ========== Navigation Methods ==========
  void _handleBottomNavigationTap(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/transactions');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/reports_overview');
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/savings_goal');
    } else {
      setState(() => _currentIndex = index);
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
    Navigator.pushNamed(context, '/budget_detail');
  }

  void _navigateToBudgetHistory() {
    Navigator.pushNamed(context, '/budget_history');
  }


  // ========== Month Picker ==========
  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showMonthPicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }
}

// ========== Helper Classes ==========
class SpendingData {
  final double totalAllocated;
  final double totalSpent;
  final Map<String, double> spentPerCategory;

  SpendingData({
    required this.totalAllocated,
    required this.totalSpent,
    required this.spentPerCategory,
  });
}