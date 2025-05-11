import 'package:flutter/material.dart';
import 'package:mobile_app_assignment/sorting_utils.dart';

class BudgetHistoryScreen extends StatefulWidget {
  const BudgetHistoryScreen({super.key});

  @override
  State<BudgetHistoryScreen> createState() => _BudgetHistoryScreenState();
}

class _BudgetHistoryScreenState extends State<BudgetHistoryScreen> {
  // Search properties
  final TextEditingController _searchController = TextEditingController();
  final String _searchTerm = '';
  final bool _isSearchVisible = false;
  final SortingOptions _sortingOptions = const SortingOptions();

  // ========== Filter Properties ==========
  final List<String> _selectedCategories = [];
  final double _minAmount = 0;
  final double _maxAmount = double.infinity;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  final bool _isFilterActive = false;
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();
  String? _minAmountError;
  String? _maxAmountError;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  String? _startDateError;
  String? _endDateError;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  // ===================================
  //            UI ELEMENT
  // ===================================
  AppBar _buildAppBar(){
    return AppBar(
      title: Text('Budget History'),
      actions: [
        PopupMenuButton(
          icon: Icon(Icons.more_vert),
          onSelected: (String value) {
            _handleMenuSelection(value);
          },
          itemBuilder: (BuildContext context) =>
          [
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
                title: Text('Sort'),
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
          ]
        ),
      ],
    );
  }

  Widget _buildBody(){
    return Column(
      children: [
        Text('TODO'),
      ],
    );
  }

  // ================================
  //          BUSINESS LOGIC
  // ================================
  void _handleMenuSelection(String value) {
    switch (value) {
      case 'sort':
        //_showSortDialog(context);
        break;
      case 'filter':
        //_showFilterDialog(context);
        break;
    }
  }

}
