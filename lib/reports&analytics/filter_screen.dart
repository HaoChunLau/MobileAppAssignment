import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  FilterScreenState createState() => FilterScreenState();
}

class FilterScreenState extends State<FilterScreen> {
  // Filter state variables
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(Duration(days: 30)),
    end: DateTime.now(),
  );
  RangeValues _amountRange = RangeValues(0, 5000);
  List<String> _selectedCategories = [];
  String _transactionType = 'All';

  // Sample categories
  final List<String> _categories = [
    'Food & Drinks',
    'Transportation',
    'Entertainment',
    'Utilities',
    'Shopping',
    'Health',
    'Education',
    'Bills',
    'Salary',
    'Investments',
    'Gifts',
    'Others',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Filter Transactions'),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: Text('Reset'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateRangeFilter(),
            SizedBox(height: 20),
            _buildTransactionTypeFilter(),
            SizedBox(height: 20),
            _buildAmountRangeFilter(),
            SizedBox(height: 20),
            _buildCategoriesFilter(),
            SizedBox(height: 32),
            _buildApplyButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Date Range'),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectDateRange,
                child: InputDecorator(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${DateFormat('MMM d, y').format(_dateRange.start)} - ${DateFormat('MMM d, y').format(_dateRange.end)}',
                        style: TextStyle(fontSize: 14),
                      ),
                      Icon(Icons.calendar_today, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        _buildQuickDateRanges(),
      ],
    );
  }

  Widget _buildQuickDateRanges() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildDateRangeChip('Today', 0),
        _buildDateRangeChip('Yesterday', 1),
        _buildDateRangeChip('This Week', 7),
        _buildDateRangeChip('This Month', 30),
        _buildDateRangeChip('Last 3 Months', 90),
        _buildDateRangeChip('This Year', 365),
      ],
    );
  }

  Widget _buildDateRangeChip(String label, int days) {
    return InkWell(
      onTap: () => _setQuickDateRange(days),
      child: Chip(
        label: Text(label),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        side: BorderSide(color: Theme.of(context).primaryColor),
      ),
    );
  }

  void _setQuickDateRange(int days) {
    final now = DateTime.now();
    late DateTime start;
    
    if (days == 0) {
      // Today
      start = DateTime(now.year, now.month, now.day);
    } else if (days == 1) {
      // Yesterday
      final yesterday = now.subtract(Duration(days: 1));
      start = DateTime(yesterday.year, yesterday.month, yesterday.day);
    } else if (days == 7) {
      // This Week (starting from most recent Sunday)
      start = now.subtract(Duration(days: now.weekday));
    } else if (days == 30) {
      // This Month
      start = DateTime(now.year, now.month, 1);
    } else if (days == 90) {
      // Last 3 Months
      start = DateTime(now.year, now.month - 3, now.day);
    } else if (days == 365) {
      // This Year
      start = DateTime(now.year, 1, 1);
    }
    
    setState(() {
      _dateRange = DateTimeRange(start: start, end: now);
    });
  }

  Future<void> _selectDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedRange != null) {
      setState(() {
        _dateRange = pickedRange;
      });
    }
  }

  Widget _buildTransactionTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Transaction Type'),
        SizedBox(height: 12),
        SegmentedButton<String>(
          segments: [
            ButtonSegment<String>(value: 'All', label: Text('All')),
            ButtonSegment<String>(value: 'Expense', label: Text('Expense')),
            ButtonSegment<String>(value: 'Income', label: Text('Income')),
          ],
          selected: {_transactionType},
          onSelectionChanged: (Set<String> selection) {
            setState(() {
              _transactionType = selection.first;
            });
          },
          style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Amount Range'),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RM ${_amountRange.start.toInt()}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'RM ${_amountRange.end.toInt()}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        RangeSlider(
          values: _amountRange,
          min: 0,
          max: 5000,
          divisions: 50,
          labels: RangeLabels(
            'RM ${_amountRange.start.toInt()}',
            'RM ${_amountRange.end.toInt()}',
          ),
          onChanged: (RangeValues values) {
            setState(() {
              _amountRange = values;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCategoriesFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Categories'),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((category) {
            final isSelected = _selectedCategories.contains(category);
            return FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCategories.add(category);
                  } else {
                    _selectedCategories.remove(category);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Apply filters and return to previous screen
          Navigator.pop(context, {
            'dateRange': _dateRange,
            'amountRange': _amountRange,
            'selectedCategories': _selectedCategories,
            'transactionType': _transactionType,
          });
        },
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Apply Filters',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _dateRange = DateTimeRange(
        start: DateTime.now().subtract(Duration(days: 30)),
        end: DateTime.now(),
      );
      _amountRange = RangeValues(0, 5000);
      _selectedCategories = [];
      _transactionType = 'All';
    });
  }
}