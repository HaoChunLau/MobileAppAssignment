import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class SavingsGoalScreen extends StatefulWidget {
  const SavingsGoalScreen({super.key});

  @override
  State<SavingsGoalScreen> createState() => _SavingsGoalScreenState();
}

class _SavingsGoalScreenState extends State<SavingsGoalScreen> {
  // Sample data for savings goals
  final List<SavingsGoal> _goals = [
    SavingsGoal(
      id: '1',
      name: 'New Laptop',
      targetAmount: 3500.0,
      savedAmount: 1500.0,
      targetDate: DateTime(2025, 6, 15),
      icon: Icons.laptop,
      color: Colors.blue,
    ),
    SavingsGoal(
      id: '2',
      name: 'Vacation',
      targetAmount: 5000.0,
      savedAmount: 2000.0,
      targetDate: DateTime(2025, 12, 20),
      icon: Icons.beach_access,
      color: Colors.orange,
    ),
    SavingsGoal(
      id: '3',
      name: 'Emergency Fund',
      targetAmount: 10000.0,
      savedAmount: 3000.0,
      targetDate: DateTime(2026, 3, 1),
      icon: Icons.health_and_safety,
      color: Colors.red,
    ),
  ];

  // ========= Popup Windows for more action ========
  void _handleMenuSelection(String value) {
    switch (value) {
      case 'settings':
        Navigator.pushNamed(context, '/settings');
        break;
      case 'search':
        setState(() {
          /*_isSearchVisible = !_isSearchVisible;
          if (!_isSearchVisible) {
            _searchController.clear();
            _searchTerm = '';
          }*/
        });
        break;
      case 'sort':
        //_showSortDialog(context);
        break;
      case 'filter':
        //filterPopup();
        break;
      case 'history':
        _navigateToSavingsGoalHistoryScreen();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
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
                      /*_isSearchVisible ? Icons.search_off : */Icons.search,
                      size: 20,
                    ),
                    title: Text(/*_isSearchVisible ? 'Cancel Searching' : */'Search'),
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
      ),
      body: _goals.isEmpty
          ? _buildEmptyState()
          : _buildGoalsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddGoalScreen,
        child: const Icon(Icons.add),
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _goals.length,
      itemBuilder: (context, index) {
        final goal = _goals[index];
        final progress = goal.savedAmount / goal.targetAmount;
        final remainingAmount = goal.targetAmount - goal.savedAmount;
        final daysRemaining = goal.targetDate.difference(DateTime.now()).inDays;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(
                context, 
                '/savings_progress',
                arguments: goal,
              );
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
                          color: goal.color.withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          goal.icon,
                          size: 24,
                          color: goal.color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.name,
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
                      progress > 0.7 ? Colors.green : goal.color,
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Saved: RM ${goal.savedAmount.toStringAsFixed(2)}',
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
                      if (daysRemaining > 0)
                        Text(
                          '$daysRemaining days remaining',
                          style: TextStyle(
                            color: daysRemaining < 30 ? Colors.orange : Colors.grey[600],
                          ),
                        )
                      else
                        Text(
                          'Goal date passed',
                          style: TextStyle(
                            color: Colors.red[400],
                          ),
                        ),
                      ElevatedButton(
                        onPressed: () => _showAddContributionDialog(goal),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: goal.color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Add Money'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToAddGoalScreen(){
    Navigator.pushNamed(context, '/savings_add');
  }

  void _navigateToSavingsGoalHistoryScreen(){
    Navigator.pushNamed(context, '/savings_history');
  }

  /*void _showAddGoalDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    final ValueNotifier<DateTime> targetDate = ValueNotifier(
      DateTime.now().add(const Duration(days: 180))
    );

    IconData selectedIcon = Icons.savings;
    Color selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final icons = [
            Icons.savings, Icons.house, Icons.car_rental, Icons.school,
            Icons.beach_access, Icons.devices, Icons.flight, Icons.favorite,
            Icons.sports, Icons.shopping_bag, Icons.pets, Icons.watch,
          ];

          final colors = [
            Colors.blue, Colors.red, Colors.green, Colors.orange,
            Colors.purple, Colors.teal, Colors.amber, Colors.indigo,
            Colors.pink, Colors.cyan
          ];

          return AlertDialog(
            title: const Text('Add New Savings Goal'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Goal Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Target Amount (RM)',
                      border: OutlineInputBorder(),
                      prefixText: 'RM ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Target Date:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<DateTime>(
                    valueListenable: targetDate,
                    builder: (context, date, child) {
                      return OutlinedButton.icon(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                          );
                          if (picked != null) {
                            targetDate.value = picked;
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(DateFormat('MMM dd, yyyy').format(date)),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Icon:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: icons.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIcon = icons[index];
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: selectedIcon == icons[index]
                                  ? selectedColor.withAlpha((0.1 * 255).round())
                                  : Colors.transparent,
                              border: Border.all(
                                color: selectedIcon == icons[index]
                                    ? selectedColor
                                    : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              icons[index],
                              color: selectedIcon == icons[index]
                                  ? selectedColor
                                  : Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Color:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      scrollDirection: Axis.horizontal,
                      itemCount: colors.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedColor = colors[index];
                            });
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: colors[index],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedColor == colors[index]
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: selectedColor == colors[index]
                                  ? [
                                      BoxShadow(
                                        color: Colors.grey.withAlpha((0.5 * 255).round()),
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
                onPressed: () {
                  if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                    final amount = double.tryParse(amountController.text) ?? 0.0;
                    if (amount > 0) {
                      setState(() {
                        _goals.add(SavingsGoal(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: nameController.text,
                          targetAmount: amount,
                          savedAmount: 0.0,
                          targetDate: targetDate.value,
                          icon: selectedIcon,
                          color: selectedColor,
                        ));
                      });
                      Navigator.pop(context);
                    }
                  }
                },
                child: const Text('Add Goal'),
              ),
            ],
          );
        },
      ),
    );
  }*/

  void _showAddContributionDialog(SavingsGoal goal) {
    final TextEditingController amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Money to ${goal.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Progress: RM ${goal.savedAmount.toStringAsFixed(2)} of RM ${goal.targetAmount.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (RM)',
                border: OutlineInputBorder(),
                prefixText: 'RM ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (amountController.text.isNotEmpty) {
                final amount = double.tryParse(amountController.text) ?? 0.0;
                if (amount > 0) {
                  setState(() {
                    final index = _goals.indexWhere((g) => g.id == goal.id);
                    if (index != -1) {
                      final updatedGoal = SavingsGoal(
                        id: goal.id,
                        name: goal.name,
                        targetAmount: goal.targetAmount,
                        savedAmount: goal.savedAmount + amount,
                        targetDate: goal.targetDate,
                        icon: goal.icon,
                        color: goal.color,
                      );
                      _goals[index] = updatedGoal;
                    }
                  });
                  Navigator.pop(context);
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('RM ${amount.toStringAsFixed(2)} added to ${goal.name}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: goal.color,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
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