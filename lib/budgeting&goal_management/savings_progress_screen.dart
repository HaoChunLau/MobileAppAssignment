import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app_assignment/budgeting&goal_management/savings_goal_screen.dart';

class SavingsProgressScreen extends StatefulWidget {
  const SavingsProgressScreen({super.key});

  @override
  State<SavingsProgressScreen> createState() => _SavingsProgressScreenState();
}

class _SavingsProgressScreenState extends State<SavingsProgressScreen> {
  // Sample data for contributions history
  final List<Contribution> _contributions = [
    Contribution(
      id: '1',
      amount: 500.0,
      date: DateTime.now().subtract(const Duration(days: 30)),
      note: 'Initial deposit',
    ),
    Contribution(
      id: '2',
      amount: 300.0,
      date: DateTime.now().subtract(const Duration(days: 20)),
      note: 'Monthly savings',
    ),
    Contribution(
      id: '3',
      amount: 200.0,
      date: DateTime.now().subtract(const Duration(days: 10)),
      note: 'Birthday gift',
    ),
    Contribution(
      id: '4',
      amount: 500.0,
      date: DateTime.now().subtract(const Duration(days: 5)),
      note: 'Bonus',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final SavingsGoal goal = ModalRoute.of(context)!.settings.arguments as SavingsGoal;
    final double progress = goal.savedAmount / goal.targetAmount;
    final double remainingAmount = goal.targetAmount - goal.savedAmount;
    final int daysRemaining = goal.targetDate.difference(DateTime.now()).inDays;
    
    // Calculate daily required amount to reach goal
    double dailyRequired = 0;
    if (daysRemaining > 0) {
      dailyRequired = remainingAmount / daysRemaining;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEditGoalScreen(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGoalProgressCard(goal, progress, remainingAmount, daysRemaining, dailyRequired),
            const SizedBox(height: 24),
            _buildContributionActions(goal),
            const SizedBox(height: 24),
            _buildContributionHistory(goal),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProgressCard(
    SavingsGoal goal, 
    double progress, 
    double remainingAmount, 
    int daysRemaining, 
    double dailyRequired
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: goal.color.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    goal.icon,
                    size: 30,
                    color: goal.color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Target date: ${DateFormat('MMMM dd, yyyy').format(goal.targetDate)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildProgressIndicator(progress, goal.color),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAmountInfo('Saved', 'RM ${goal.savedAmount.toStringAsFixed(2)}', Colors.green),
                _buildAmountInfo('Goal', 'RM ${goal.targetAmount.toStringAsFixed(2)}', goal.color),
                _buildAmountInfo('Remaining', 'RM ${remainingAmount.toStringAsFixed(2)}', 
                  remainingAmount > 0 ? Colors.orange : Colors.green),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTimeInfo(
                  'Days Remaining',
                  daysRemaining > 0 ? '$daysRemaining days' : 'Goal date passed',
                  daysRemaining < 30 && daysRemaining > 0 ? Colors.orange : 
                  daysRemaining <= 0 ? Colors.red : Colors.black,
                ),
                if (daysRemaining > 0 && remainingAmount > 0)
                  _buildTimeInfo(
                    'Daily Need',
                    'RM ${dailyRequired.toStringAsFixed(2)}',
                    dailyRequired > 100 ? Colors.red : Colors.blue,
                  ),
                if (remainingAmount <= 0)
                  _buildTimeInfo(
                    'Status',
                    'Goal Achieved! 🎉',
                    Colors.green,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress ${(progress * 100).toInt()}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              progress >= 1 ? 'Completed!' : '${(progress * 100).toInt()}% of goal',
              style: TextStyle(
                color: progress >= 1 ? Colors.green : Colors.grey[600],
                fontWeight: progress >= 1 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress > 1 ? 1 : progress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            progress >= 1 ? Colors.green : color,
          ),
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),
      ],
    );
  }

  Widget _buildAmountInfo(String title, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeInfo(String title, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildContributionActions(SavingsGoal goal) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showAddContributionDialog(goal),
            icon: const Icon(Icons.add),
            label: const Text('Add Money'),
            style: ElevatedButton.styleFrom(
              backgroundColor: goal.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showWithdrawDialog(goal),
            icon: const Icon(Icons.remove),
            label: const Text('Withdraw'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContributionHistory(SavingsGoal goal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contribution History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _contributions.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No contributions yet',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _contributions.length,
                itemBuilder: (context, index) {
                  final contribution = _contributions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: goal.color.withAlpha((0.1 * 255).round()),
                        child: Icon(
                          contribution.amount > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          color: contribution.amount > 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(
                        contribution.amount > 0 
                            ? 'Added RM ${contribution.amount.toStringAsFixed(2)}'
                            : 'Withdrew RM ${(-contribution.amount).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: contribution.amount > 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat('MMM dd, yyyy').format(contribution.date)),
                          if (contribution.note.isNotEmpty)
                            Text(
                              contribution.note,
                              style: const TextStyle(fontStyle: FontStyle.italic),
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.grey),
                        onPressed: () => _showDeleteContributionDialog(contribution),
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  void _showAddContributionDialog(SavingsGoal goal) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Money to ${goal.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                border: OutlineInputBorder(),
                hintText: 'E.g., Salary, Gift, etc.',
              ),
              maxLines: 2,
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
                    _contributions.insert(0, Contribution(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      amount: amount,
                      date: DateTime.now(),
                      note: noteController.text,
                    ));
                    
                    // In a real app, you would update the goal's saved amount in a database
                    // For now, we're just simulating it
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

  void _showWithdrawDialog(SavingsGoal goal) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Withdraw from ${goal.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current balance: RM ${goal.savedAmount.toStringAsFixed(2)}',
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
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Reason (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Why are you withdrawing?',
              ),
              maxLines: 2,
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
                if (amount > 0 && amount <= goal.savedAmount) {
                  setState(() {
                    _contributions.insert(0, Contribution(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      amount: -amount, // Negative value for withdrawal
                      date: DateTime.now(),
                      note: noteController.text,
                    ));
                    
                    // In a real app, you would update the goal's saved amount in a database
                    // For now, we're just simulating it
                  });
                  Navigator.pop(context);
                  
                  // Show message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('RM ${amount.toStringAsFixed(2)} withdrawn from ${goal.name}'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } else if (amount > goal.savedAmount) {
                  // Show error message if trying to withdraw more than available
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cannot withdraw more than the available amount'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  void _navigateToEditGoalScreen(){
    Navigator.pushNamed(context, '/savings_edit');
  }

  /*void _showEditGoalDialog(SavingsGoal goal) {
    final TextEditingController nameController = TextEditingController(text: goal.name);
    final TextEditingController amountController = TextEditingController(text: goal.targetAmount.toString());
    final ValueNotifier<DateTime> targetDate = ValueNotifier(goal.targetDate);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Savings Goal'),
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
                  // In a real app, you would update the goal in a database
                  // For now, just show a success message
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Goal updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }*/

  void _showDeleteContributionDialog(Contribution contribution) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contribution'),
        content: const Text('Are you sure you want to delete this contribution? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _contributions.removeWhere((c) => c.id == contribution.id);
              });
              Navigator.pop(context);
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contribution deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class Contribution {
  final String id;
  final double amount;
  final DateTime date;
  final String note;

  Contribution({
    required this.id,
    required this.amount,
    required this.date,
    required this.note,
  });
}

// class SavingsGoal {
//   final String id;
//   final String name;
//   final double targetAmount;
//   final double savedAmount;
//   final DateTime targetDate;
//   final IconData icon;
//   final Color color;

//   SavingsGoal({
//     required this.id,
//     required this.name,
//     required this.targetAmount,
//     required this.savedAmount,
//     required this.targetDate,
//     required this.icon,
//     required this.color,
//   });
// }