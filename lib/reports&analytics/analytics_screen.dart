import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Analytics")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Spending & Income Analytics",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: BarChart(
                BarChartData(
                  barGroups: _buildBarChartGroups(),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    return [
      PieChartSectionData(value: 40, title: "Food", color: Colors.blue, radius: 50),
      PieChartSectionData(value: 20, title: "Transport", color: Colors.red, radius: 50),
      PieChartSectionData(value: 25, title: "Shopping", color: Colors.green, radius: 50),
      PieChartSectionData(value: 15, title: "Bills", color: Colors.orange, radius: 50),
    ];
  }

  List<BarChartGroupData> _buildBarChartGroups() {
    return [
      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 800, color: Colors.blue)]),
      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 300, color: Colors.red)]),
      BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 600, color: Colors.green)]),
      BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 1500, color: Colors.orange)]),
    ];
  }
}