import 'package:flutter/material.dart';

class BudgetOverviewScreen extends StatefulWidget {
  const BudgetOverviewScreen({Key? key}) : super(key: key);

  @override
  State<BudgetOverviewScreen> createState() => _BudgetOverviewScreenState();
}

class _BudgetOverviewScreenState extends State<BudgetOverviewScreen> {
  // Sample data for budget categories
  final List<BudgetCategory> _categories = [
    BudgetCategory(
      name: 'Food & Drinks',
      allocated: 1000.0,
      spent: 750.0,
      icon: Icons.restaurant,
      color: Colors.orange,
    ),
    BudgetCategory(
      name: 'Transportation',
      allocated: 500.0,
      spent: 250.0,
      icon: Icons.directions_car,
      color: Colors.blue,
    ),
    BudgetCategory(
      name: 'Entertainment',
      allocated: 300.0,
      spent: 270.0,
      icon: Icons.movie,
      color: Colors.red,
    ),
    BudgetCategory(
      name: 'Utilities',
      allocated: 400.0,
      spent: 120.0,
      icon: Icons.lightbulb,
      color: Colors.green,
    ),
    BudgetCategory(
      name: 'Shopping',
      allocated: 600.0,
      spent: 450.0,
      icon: Icons.shopping_bag,
      color: Colors.purple,
    ),
    BudgetCategory(
      name: 'Health',
      allocated: 200.0,
      spent: 80.0,
      icon: Icons.local_hospital,
      color: Colors.teal,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    double totalAllocated = _categories.fold(0, (sum, item) => sum + item.allocated);
    double totalSpent = _categories.fold(0, (sum, item) => sum + item.spent);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/budget_setting');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverallBudgetCard(totalAllocated, totalSpent),
            const SizedBox(height: 24),
            _buildCategorySection(),
            const SizedBox(height: 16),
            _buildBudgetList(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/budget_setting');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Create New Budget'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallBudgetCard(double totalAllocated, double totalSpent) {
    double percentUsed = totalAllocated > 0 ? (totalSpent / totalAllocated) : 0;
    
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
              'Monthly Budget Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBudgetInfoColumn('Allocated', 'RM ${totalAllocated.toStringAsFixed(2)}', Colors.blue),
                _buildBudgetInfoColumn('Spent', 'RM ${totalSpent.toStringAsFixed(2)}', Colors.red),
                _buildBudgetInfoColumn('Remaining', 'RM ${(totalAllocated - totalSpent).toStringAsFixed(2)}', Colors.green),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Overall Progress',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
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
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Budget Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to a screen to manage categories
              },
              child: const Text('Manage'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBudgetList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final progress = category.allocated > 0 ? category.spent / category.allocated : 0;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: category.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        category.icon,
                        color: category.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/budget_setting',
                          arguments: category,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RM ${category.spent.toStringAsFixed(2)} of RM ${category.allocated.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: progress > 0.9 ? Colors.red : 
                               progress > 0.75 ? Colors.orange : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress.toDouble(),
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress > 0.9 ? Colors.red : 
                    progress > 0.75 ? Colors.orange : category.color,
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

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