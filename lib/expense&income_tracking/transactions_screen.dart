import 'package:flutter/material.dart';
import 'package:mobile_app_assignment/expense&income_tracking/expense_list_screen.dart';
import 'package:mobile_app_assignment/expense&income_tracking/income_list_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}
class _TransactionsScreenState extends State<TransactionsScreen>{
  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent default pop
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Transactions'),
            automaticallyImplyLeading: false,
            bottom: TabBar(
              tabs: [
                Tab(text: 'Expenses'),
                Tab(text: 'Income'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              ExpenseListScreen(),
              IncomeListScreen(),
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
                          leading: Icon(Icons.remove_circle, color: Colors.red),
                          title: Text('Add Expense'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/add_expense');
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.add_circle, color: Colors.green),
                          title: Text('Add Income'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/add_income');
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            child: Icon(Icons.add),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(),
        ),
      ),
    );
  }

  // ========== Bottom Navigation ==========
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

  // ========== Navigation Methods ==========
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