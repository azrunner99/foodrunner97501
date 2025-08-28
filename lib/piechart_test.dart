import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('PieChart Test')),
        body: Center(
          child: SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(value: 40, color: Colors.blue, title: 'Blue'),
                  PieChartSectionData(value: 30, color: Colors.red, title: 'Red'),
                  PieChartSectionData(value: 30, color: Colors.green, title: 'Green'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
