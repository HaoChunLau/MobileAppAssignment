import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BudgetSettingScreen extends StatefulWidget {
  const BudgetSettingScreen({Key? key}) : super(key: key);

  @override
  State<BudgetSettingScreen> createState() => _BudgetSettingScreenState();
}

class _BudgetSettingScreenState extends State<BudgetSettingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  
  IconData _selectedIcon = Icons.shopping_cart;
  Color _selectedColor = Colors.blue;
  
  // Predefined list of icons to choose from
  final List<IconData> _availableIcons = [
    Icons.shopping_cart,
    Icons.restaurant,
    Icons.directions_car,
    Icons.movie,
    Icons.lightbulb,
    Icons.local_hospital,
    Icons.shopping_bag,
    Icons.house,
    Icons.school,
    Icons.sports_basketball,
    Icons.airplanemode_active,
    Icons.pets,
  ];
  
  // Predefined list of colors to choose from
  final List<Color> _availableColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.amber,
    Colors.indigo,
    Colors.pink,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    // Check if we're editing an existing budget category
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments != null && arguments is BudgetCategory) {
        _nameController.text = arguments.name;
        _amountController.text = arguments.allocated.toString();
        _selectedIcon = arguments.icon;
        _selectedColor = arguments.color;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = ModalRoute.of(context)?.settings.arguments != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Budget' : 'Create Budget'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryNameField(),
              const SizedBox(height: 20),
              _buildAmountField(),
              const SizedBox(height: 24),
              const Text(
                'Category Icon',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildIconSelection(),
              const SizedBox(height: 24),
              const Text(
                'Category Color',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildColorSelection(),
              const SizedBox(height: 32),
              _buildPreview(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveBudget,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(isEditing ? 'Update Budget' : 'Create Budget'),
              ),
              if (isEditing) 
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: OutlinedButton(
                    onPressed: _deleteBudget,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Delete Budget'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Category Name',
        hintText: 'E.g., Food, Transportation, Entertainment',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a category name';
        }
        return null;
      },
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: const InputDecoration(
        labelText: 'Budget Amount (RM)',
        hintText: 'E.g., 500.00',
        border: OutlineInputBorder(),
        prefixText: 'RM ',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a budget amount';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return 'Please enter a valid positive amount';
        }
        return null;
      },
    );
  }

  Widget _buildIconSelection() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _availableIcons.length,
        itemBuilder: (context, index) {
          final icon = _availableIcons[index];
          final isSelected = icon == _selectedIcon;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedIcon = icon;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? _selectedColor.withOpacity(0.2) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? _selectedColor : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? _selectedColor : Colors.grey,
                size: 28,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildColorSelection() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        scrollDirection: Axis.horizontal,
        itemCount: _availableColors.length,
        itemBuilder: (context, index) {
          final color = _availableColors[index];
          final isSelected = color == _selectedColor;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedColor = color;
              });
            },
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 1,
                          blurRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreview() {
    final categoryName = _nameController.text.isNotEmpty
        ? _nameController.text
        : 'Category Name';
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _selectedIcon,
                    color: _selectedColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  categoryName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RM 0.00 of RM ${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const Text(
                  '0%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: 0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(_selectedColor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  void _saveBudget() {
    if (_formKey.currentState!.validate()) {
      // In a real app, you would save this data to a database
      // For now, we'll just navigate back
      Navigator.pop(context);
      
      // Show a snackbar to indicate success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _deleteBudget() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: const Text('Are you sure you want to delete this budget category?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
              
              // Show a snackbar to indicate deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Budget deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// BudgetCategory class for reference (should match with the one in BudgetOverviewScreen)
class BudgetCategory {
  final String name;
  final double allocated;
  final double spent;
  final IconData icon;
  final Color color;

  BudgetCategory({
    required this.name,
    required this.allocated,
    required this.spent,
    required this.icon,
    required this.color,
  });
}