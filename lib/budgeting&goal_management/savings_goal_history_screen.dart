import 'package:flutter/material.dart';

class SavingsGoalHistoryScreen extends StatefulWidget {
  const SavingsGoalHistoryScreen({super.key});

  @override
  State<SavingsGoalHistoryScreen> createState() => _SavingsGoalHistoryScreenState();
}

class _SavingsGoalHistoryScreenState extends State<SavingsGoalHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
    );
  }
  
  AppBar _buildAppBar(){
    return AppBar(
      title: Text('Savings Goals History'),
    );
  }
}
