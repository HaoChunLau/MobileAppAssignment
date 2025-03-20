import 'package:flutter/material.dart';

class EditExpenseScreen extends StatefulWidget {
  final String category;
  final String subcategory;
  final double amount;
  final String description;
  final DateTime date;

  const EditExpenseScreen({
    super.key,
    required this.category,
    required this.subcategory,
    required this.amount,
    required this.description,
    required this.date,
  });

  @override
  EditExpenseScreenState createState() => EditExpenseScreenState();
}

class EditExpenseScreenState extends State<EditExpenseScreen> {
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late String _selectedCategory;
  late String _selectedSubcategory;
  late DateTime _selectedDate;

  final List<String> _categories = ['Food', 'Transport', 'Shopping', 'Bills'];
  final Map<String, List<String>> _subcategories = {
    'Food': ['Breakfast', 'Lunch', 'Dinner', 'Snacks'],
    'Transport': ['Bus', 'Train', 'Taxi', 'Fuel'],
    'Shopping': ['Clothes', 'Electronics', 'Groceries'],
    'Bills': ['Electricity', 'Water', 'Internet'],
  };

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.amount.toString());
    _descriptionController = TextEditingController(text: widget.description);
    _selectedCategory = widget.category;
    _selectedSubcategory = widget.subcategory;
    _selectedDate = widget.date;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Expense")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Amount (RM)"),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: "Category"),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                  _selectedSubcategory = _subcategories[newValue]![0];
                });
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedSubcategory,
              decoration: const InputDecoration(labelText: "Subcategory"),
              items: _subcategories[_selectedCategory]!.map((String subcategory) {
                return DropdownMenuItem<String>(
                  value: subcategory,
                  child: Text(subcategory),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedSubcategory = newValue!;
                });
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text("Date: ${_selectedDate.toLocal()}".split(' ')[0]),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: const Text("Select Date"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Save edited expense logic will be implemented later
                Navigator.pop(context);
              },
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}
