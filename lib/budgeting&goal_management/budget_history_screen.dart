import 'package:flutter/material.dart';

class BudgetHistoryScreen extends StatefulWidget {
  const BudgetHistoryScreen({super.key});

  @override
  State<BudgetHistoryScreen> createState() => _BudgetHistoryScreenState();
}

class _BudgetHistoryScreenState extends State<BudgetHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }
  
  AppBar _buildAppBar(){
    return AppBar(
      title: Text('Budget History'),
    );
  }
  Widget _buildBody(){
    return Column(
      children: [
        Text('TODO'),
      ],
    );
  }
}
