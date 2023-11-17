import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/category_stack_chart.dart';

class CashFlowTab extends StatelessWidget {
  const CashFlowTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Income",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        CategoryStackChart(chartData1),
        Text(
          "Expenses",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        CategoryStackChart(chartData1),
      ],
    );
  }
}

class ChartData {
  final String x;
  final double y1;
  final double y2;
  final double y3;
  final double y4;

  const ChartData(this.x, this.y1, this.y2, this.y3, this.y4);
}
