import 'package:flutter/material.dart';

class SavingsGoalAddScreen extends StatefulWidget {
  const SavingsGoalAddScreen({super.key});

  @override
  State<SavingsGoalAddScreen> createState() => _SavingsGoalAddScreenState();
}

class _SavingsGoalAddScreenState extends State<SavingsGoalAddScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
    );
  }
  
  AppBar _buildAppBar(){
    return AppBar(
      title: Text('Add Savings Goal'),
    );
  }
}
