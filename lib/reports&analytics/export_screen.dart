import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  Set<String> _selectedData = {'Expenses', 'Income'};
  bool _includeCategories = true;
  bool _includeNotes = true;

  // Available data types
  final List<String> _dataTypes = ['Expenses', 'Income', 'Budget', 'Savings'];
  
  // Available file formats
  final List<String> _fileFormats = ['CSV', 'PDF', 'Excel'];

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
      onPressed: _exportData,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
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

  void _exportData() {
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
              '${DateFormat('MMM d, y').format(_dateRange.start)} - ${DateFormat('MMM d, y').format(_dateRange.end)}'
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
            onPressed: () {
              // Here you would actually perform the export operation
              Navigator.pop(context);
              _showExportSuccessDialog();
            },
            child: Text('Confirm Export'),
          ),
        ],
      ),
    );
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
          'Your data has been exported successfully as $_fileFormat file.',
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