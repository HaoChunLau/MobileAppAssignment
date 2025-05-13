import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:mobile_app_assignment/expense&income_tracking/expense_list_screen.dart';
import 'package:mobile_app_assignment/expense&income_tracking/income_list_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  int _currentIndex = 1;
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showMonthPicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Transactions - ${DateFormat('MMM yyyy').format(_selectedDate)}'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_today),
                tooltip: 'Select Month',
                onPressed: () => _selectMonth(context),
              ),
            ],
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Expenses'),
                Tab(text: 'Income'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              ExpenseListScreen(selectedDate: _selectedDate),
              IncomeListScreen(selectedDate: _selectedDate),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return SizedBox(
                    height: 120,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.remove_circle, color: Colors.red),
                          title: const Text('Add Expense'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/add_expense').then((_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Expense added successfully'),
                                  backgroundColor: Colors.green,
                                  action: SnackBarAction(
                                    label: 'OK',
                                    textColor: Colors.blue,
                                    onPressed: () {},
                                  ),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            });
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.add_circle, color: Colors.green),
                          title: const Text('Add Income'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/add_income').then((_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Income added successfully'),
                                  backgroundColor: Colors.green,
                                  action: SnackBarAction(
                                    label: 'OK',
                                    textColor: Colors.blue,
                                    onPressed: () {},
                                  ),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            tooltip: 'Add Transaction',
            child: const Icon(Icons.add),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(),
        ),
      ),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _handleBottomNavigationTap,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet), label: 'Transactions'),
        BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Budget'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reports'),
        BottomNavigationBarItem(icon: Icon(Icons.savings), label: 'Savings'),
      ],
    );
  }

  void _handleBottomNavigationTap(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/budget_overview');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/reports_overview');
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/savings_goal');
    } else {
      setState(() => _currentIndex = index);
    }
  }
}