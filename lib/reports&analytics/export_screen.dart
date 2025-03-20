import 'package:flutter/material.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  ExportScreenState createState() => ExportScreenState();
}

class ExportScreenState extends State<ExportScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedFormat = 'CSV';

  final List<String> _formats = ['CSV', 'PDF'];

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _exportData() {
    // Placeholder for actual export logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Exporting data as $_selectedFormat...")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Export Data")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Date Range", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _selectDate(context, true),
                  child: Text(_startDate == null ? "Start Date" : _startDate!.toLocal().toString().split(' ')[0]),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _selectDate(context, false),
                  child: Text(_endDate == null ? "End Date" : _endDate!.toLocal().toString().split(' ')[0]),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Select Format", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedFormat,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _formats.map((String format) {
                return DropdownMenuItem<String>(
                  value: format,
                  child: Text(format),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedFormat = newValue!;
                });
              },
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _exportData,
                child: const Text("Export Data"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}