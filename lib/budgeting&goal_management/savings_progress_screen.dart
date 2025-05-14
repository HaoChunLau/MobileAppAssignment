import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app_assignment/utils/category_utils.dart';
import 'package:mobile_app_assignment/models/savings_goal_model.dart';

class SavingsProgressScreen extends StatefulWidget {
  const SavingsProgressScreen({super.key});

  @override
  State<SavingsProgressScreen> createState() => _SavingsProgressScreenState();
}

class _SavingsProgressScreenState extends State<SavingsProgressScreen> {
  late SavingsGoalModel goal;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Loading Savings Goals from firestore
  bool _isLoading = true; // Add this loading state
  List<SavingsGoalModel> _goals = []; // Initialize as empty list

  // Contributions will be loaded from Firestore using StreamBuilder

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  @override
  Widget build(BuildContext context) {
    goal = ModalRoute.of(context)!.settings.arguments as SavingsGoalModel;

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('savings').doc(goal.savingGoalId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            // Get the updated goal data
            final updatedGoalData = snapshot.data!.data() as Map<String, dynamic>;
            final updatedGoal = SavingsGoalModel.fromFirestore(snapshot.data!);

            final double progress = updatedGoal.currentSaved / updatedGoal.targetAmount;
            final double remainingAmount = updatedGoal.targetAmount - updatedGoal.currentSaved;
            final int daysRemaining = updatedGoal.targetDate.difference(DateTime.now()).inDays;

            double dailyRequired = 0;
            if (daysRemaining > 0) {
              dailyRequired = remainingAmount / daysRemaining;
            }

            final color = SavingCategoryUtils.getCategoryColor(updatedGoal.goalCategory);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGoalProgressCard(updatedGoal, progress, remainingAmount, daysRemaining, dailyRequired),
                const SizedBox(height: 24),
                if (goal.status == Status.active)...[
                  _buildContributionActions(updatedGoal),
                ],
                const SizedBox(height: 24),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('contributions')
                      .where('goalId', isEqualTo: updatedGoal.savingGoalId.toString())
                      .orderBy('date', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    final contributions = snapshot.data!.docs
                        .map((doc) => SavingsContribution.fromMap(doc.data()! as Map<String, dynamic>))
                        .toList();

                    return _buildContributionHistory(updatedGoal, contributions, color);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Loading your savings goals...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalProgressCard(
      SavingsGoalModel goal,
      double progress,
      double remainingAmount,
      int daysRemaining,
      double dailyRequired
      ) {
    final color = SavingCategoryUtils.getCategoryColor(goal.goalCategory);
    final icon = SavingCategoryUtils.getCategoryIcon(goal.goalCategory);

    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('savings')
            .where('userId', isEqualTo:  _auth.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorWidget(snapshot.error!);
          if (!snapshot.hasData) return _buildLoadingIndicator();

          final docs = snapshot.data?.docs ?? [];

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
                          color: color.withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          size: 30,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.title,
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
                  _buildProgressIndicator(progress, color),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildAmountInfo('Saved', 'RM ${goal.currentSaved.toStringAsFixed(2)}', Colors.green),
                      _buildAmountInfo('Goal', 'RM ${goal.targetAmount.toStringAsFixed(2)}', color),
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

  Widget _buildContributionActions(SavingsGoalModel goal) {
    final color = SavingCategoryUtils.getCategoryColor(goal.goalCategory);

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showAddContributionDialog(goal),
            icon: const Icon(Icons.add),
            label: const Text('Add Money'),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
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

  Widget _buildContributionHistory(SavingsGoalModel goal, List<SavingsContribution> contributions, Color color) {
    final bool isGoalCompleted = goal.currentSaved >= goal.targetAmount;

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
        contributions.isEmpty
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
          itemCount: contributions.length,
          itemBuilder: (context, index) {
            final contribution = contributions[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withAlpha((0.1 * 255).round()),
                  child: Icon(
                    contribution.amount > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    color: contribution.amount > 0 ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(
                  contribution.amount > 0
                      ? 'Added RM ${contribution.amount.toStringAsFixed(2)}'
                      : 'Withdraw RM ${(-contribution.amount).toStringAsFixed(2)}',
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
                trailing: isGoalCompleted
                    ? null // Hide delete icon when goal is completed
                    : IconButton(
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

  void _showAddContributionDialog(SavingsGoalModel goal) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final color = SavingCategoryUtils.getCategoryColor(goal.goalCategory);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Money to ${goal.title}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress information
              Row(
                children: [
                  Icon(Icons.savings, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${(goal.currentSaved/goal.targetAmount*100).toStringAsFixed(1)}% completed',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: goal.currentSaved/goal.targetAmount,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              const SizedBox(height: 16),
              Text(
                'Saved: RM ${goal.currentSaved.toStringAsFixed(2)} '
                    'of RM ${goal.targetAmount.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),

              // Amount input field with validation
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount to Add (RM)',
                  border: OutlineInputBorder(),
                  prefixText: 'RM ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid positive amount';
                  }
                  if (goal.currentSaved + amount > goal.targetAmount) {
                    return 'Amount exceeds remaining target';
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  border: OutlineInputBorder(),
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
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final amount = double.parse(amountController.text);

                final newContribution = SavingsContribution(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  goalId: goal.savingGoalId.toString(),
                  amount: amount,
                  date: DateTime.now(),
                  note: noteController.text,
                  type: 'deposit',
                );

                try {
                  // Add contribution document
                  await _firestore.collection('contributions').doc(newContribution.id).set(newContribution.toMap());

                  // Update savings goal document's currentSaved field
                  await _firestore.collection('savings').doc(goal.savingGoalId).update({
                    'currentSaved': FieldValue.increment(amount),
                    'lastUpdated': FieldValue.serverTimestamp(),
                  });

                  // After both succeed, close dialog and show success snackbar
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('RM ${amount.toStringAsFixed(2)} added to ${goal.title}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  // Handle errors in either operation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to add contribution: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Money'),
          )
        ],
      ),
    );
  }

  void _showWithdrawDialog(SavingsGoalModel goal) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Withdraw from ${goal.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current balance: RM ${goal.currentSaved.toStringAsFixed(2)}',
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
            onPressed: () async {
              if (amountController.text.isNotEmpty) {
                final amount = double.tryParse(amountController.text) ?? 0.0;
                if (amount > 0 && amount <= goal.currentSaved) {
                  Navigator.pop(context);

                  final newContribution = SavingsContribution(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    goalId: goal.savingGoalId.toString(),
                    amount: -amount,
                    date: DateTime.now(),
                    note: noteController.text,
                    type: 'withdrawal',
                  );

                  try {
                    // Add contribution document
                    await _firestore.collection('contributions').doc(newContribution.id).set(newContribution.toMap());

                    // Update savings goal document's currentSaved field
                    await _firestore.collection('savings').doc(goal.savingGoalId).update({
                      'currentSaved': FieldValue.increment(-amount),
                      'lastUpdated': FieldValue.serverTimestamp(),
                    });

                    // After both succeed, close dialog and show success snackbar
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('RM ${amount.toStringAsFixed(2)} added to ${goal.title}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    // Handle errors in either operation
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to add contribution: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else if (amount > goal.currentSaved) {
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

  void _showDeleteContributionDialog(SavingsContribution contribution) {
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
            onPressed: () async {
              Navigator.pop(context); // Close the dialog first
              try {
                // Delete the contribution document
                await _firestore.collection('contributions').doc(contribution.id).delete();

                // Update the savings goal's currentSaved field
                final goalRef = _firestore.collection('savings').doc(contribution.goalId);
                if (contribution.type == 'deposit') {
                  // If it's a deposit, subtract the amount
                  await goalRef.update({
                    'currentSaved': FieldValue.increment(-contribution.amount),
                    'lastUpdated': FieldValue.serverTimestamp(),
                  });
                } else if (contribution.type == 'withdrawal') {
                  // If it's a withdrawal, add the amount back
                  await goalRef.update({
                    'currentSaved': FieldValue.increment(-contribution.amount),
                    'lastUpdated': FieldValue.serverTimestamp(),
                  });
                }

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contribution deleted and savings updated'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                // Handle errors in either operation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete contribution: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
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

  Future<void> _loadGoals() async {
    try {
      setState(() => _isLoading = true);

      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('savings')
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .get();

      final goals = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return SavingsGoalModel.fromFirestore(doc);
      }).toList();

      setState(() {
        _goals = goals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading goals: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}