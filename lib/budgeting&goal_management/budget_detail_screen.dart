import 'package:flutter/material.dart';

class BudgetDetailScreen extends StatelessWidget {
  const BudgetDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }
  
  AppBar _buildAppBar(){
    return AppBar(
      title: Text('Budget Detail'),
    );
  }

  Widget _buildBody(){
    return Column(
    );
  }
}
