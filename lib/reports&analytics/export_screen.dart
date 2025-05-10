import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app_assignment/models/transaction_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  ExportScreenState createState() => ExportScreenState();
}

class ExportScreenState extends State<ExportScreen> {
  // Export options
  String _fileFormat = 'CSV';
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(Duration(days: 30)),
    end: DateTime.now(),
  );
  final Set<String> _selectedData = {'Expenses', 'Income'};
  bool _includeCategories = true;
  bool _includeNotes = true;
  bool _isExporting = false;
  String _errorMessage = '';

  // Available data types (removed Budget and Savings for now)
  final List<String> _dataTypes = ['Expenses', 'Income'];

  // Available file formats (only CSV is implemented for now)
  final List<String> _fileFormats = ['CSV'];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Export Data'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            _buildFileFormatSection(),
            SizedBox(height: 20),
            _buildDateRangeSection(),
            SizedBox(height: 20),
            _buildDataSelectionSection(),
            SizedBox(height: 20),
            _buildOptionsSection(),
            SizedBox(height: 32),
            _buildExportButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFileFormatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('File Format'),
        SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: _fileFormats.map((format) {
            return ChoiceChip(
              label: Text(format),
              selected: _fileFormat == format,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _fileFormat = format;
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Date Range'),
        SizedBox(height: 12),
        InkWell(
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
        _buildDateRangeChip('This Month', 30),
        _buildDateRangeChip('Last 3 Months', 90),
        _buildDateRangeChip('This Year', 365),
        _buildDateRangeChip('All Time', 1000),
      ],
    );
  }

  Widget _buildDateRangeChip(String label, int days) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        setState(() {
          _dateRange = DateTimeRange(
            start: DateTime.now().subtract(Duration(days: days)),
            end: DateTime.now(),
          );
        });
      },
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  Widget _buildDataSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Data to Export'),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _dataTypes.map((type) {
            return FilterChip(
              label: Text(type),
              selected: _selectedData.contains(type),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedData.add(type);
                  } else {
                    // Don't allow deselecting all options
                    if (_selectedData.length > 1) {
                      _selectedData.remove(type);
                    }
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Additional Options'),
        SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(4.0),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Include Categories'),
                  subtitle: Text('Add category information to exported data'),
                  value: _includeCategories,
                  onChanged: (value) {
                    setState(() {
                      _includeCategories = value;
                    });
                  },
                ),
                Divider(height: 1),
                SwitchListTile(
                  title: Text('Include Notes'),
                  subtitle: Text('Include transaction notes in the export'),
                  value: _includeNotes,
                  onChanged: (value) {
                    setState(() {
                      _includeNotes = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExportButton() {
    return ElevatedButton(
      onPressed: _isExporting ? null : _exportData,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isExporting
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Exporting...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.download),
                SizedBox(width: 8),
                Text(
                  'Export Data',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _exportData() async {
    // Show export options summary
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export Data Summary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryItem('File Format', _fileFormat),
            SizedBox(height: 8),
            _buildSummaryItem(
              'Date Range',
              '${DateFormat('MMM d, y').format(_dateRange.start)} - ${DateFormat('MMM d, y').format(_dateRange.end)}',
            ),
            SizedBox(height: 8),
            _buildSummaryItem('Data Types', _selectedData.join(', ')),
            SizedBox(height: 8),
            _buildSummaryItem('Include Categories', _includeCategories ? 'Yes' : 'No'),
            SizedBox(height: 8),
            _buildSummaryItem('Include Notes', _includeNotes ? 'Yes' : 'No'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performExport();
            },
            child: Text('Confirm Export'),
          ),
        ],
      ),
    );
  }

  Future<void> _performExport() async {
    setState(() {
      _isExporting = true;
      _errorMessage = '';
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _isExporting = false;
          _errorMessage = 'No user logged in';
        });
        return;
      }

      // Fetch transactions from Firestore
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_dateRange.start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(_dateRange.end))
          .get();

      List<TransactionModel> transactions = querySnapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .where((transaction) {
            if (_selectedData.contains('Expenses') && _selectedData.contains('Income')) {
              return true;
            } else if (_selectedData.contains('Expenses')) {
              return transaction.isExpense;
            } else if (_selectedData.contains('Income')) {
              return !transaction.isExpense;
            }
            return false;
          })
          .toList();

      if (transactions.isEmpty) {
        setState(() {
          _isExporting = false;
          _errorMessage = 'No transactions found for the selected date range and data types';
        });
        return;
      }

      // Generate CSV content
      StringBuffer csvContent = StringBuffer();
      // Write headers
      List<String> headers = ['Date', 'Type', 'Amount'];
      if (_includeCategories) {
        headers.add('Category');
      }
      if (_includeNotes) {
        headers.add('Notes');
      }
      csvContent.writeln(headers.join(','));

      // Write data rows
      for (var transaction in transactions) {
        List<String> row = [
          DateFormat('yyyy-MM-dd').format(transaction.date),
          transaction.isExpense ? 'Expense' : 'Income',
          transaction.amount.toStringAsFixed(2),
        ];
        if (_includeCategories) {
          row.add(transaction.category);
        }
        if (_includeNotes) {
          row.add('"${(transaction.notes ?? '').replaceAll('"', '""')}"'); // Escape quotes in notes
        }
        csvContent.writeln(row.join(','));
      }

      // Save the CSV file to temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = 'transactions_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(csvContent.toString());

      // Share the file
      await Share.shareXFiles([XFile(filePath)], text: 'Here is your exported financial data');

      setState(() {
        _isExporting = false;
      });

      // Show success dialog
      _showExportSuccessDialog();
    } catch (e) {
      setState(() {
        _isExporting = false;
        _errorMessage = 'Failed to export data: $e';
      });
    }
  }

  Widget _buildSummaryItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  void _showExportSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Export Successful'),
          ],
        ),
        content: Text(
          'Your data has been exported successfully as $_fileFormat file and shared.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
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
}