import 'package:flutter/material.dart';

class SavingsGoalEditScreen extends StatefulWidget {
  const SavingsGoalEditScreen({super.key});

  @override
  State<SavingsGoalEditScreen> createState() => _SavingsGoalEditScreenState();
}

class _SavingsGoalEditScreenState extends State<SavingsGoalEditScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
    );
  }
  
  AppBar _buildAppBar(){
    return AppBar(
      title: Text('Edit Savings Goal'),
    );
  }
}
