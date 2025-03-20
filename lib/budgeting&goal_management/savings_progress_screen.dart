import 'package:flutter/material.dart';

class SavingsProgressScreen extends StatelessWidget {
  const SavingsProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double savingsGoal = 1000; // Example goal amount
    double currentSavings = 600; // Example current savings amount
    double progress = currentSavings / savingsGoal;

    return Scaffold(
      appBar: AppBar(title: const Text("Savings Progress")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your Savings Progress",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text("Goal: RM$savingsGoal"),
            Text("Saved: RM$currentSavings"),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              color: progress >= 1.0 ? Colors.green : Colors.blue,
              minHeight: 12,
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Back"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
