import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/test_data.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class CategoryStackChart extends StatelessWidget {
  final List<CategoryHistory> data;
  final (int, int) range;
  const CategoryStackChart(this.data, this.range, {super.key});

  @override
  Widget build(BuildContext context) {
    final format = DateFormat("MMM ''yy"); // single quote is escaped by doubling
    return SfCartesianChart(
      primaryXAxis: CategoryAxis(
          // visibleMinimum: 0.5,
          // visibleMaximum: 1.5,
          ),
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        // tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
        tooltipSettings: const InteractiveTooltip(
          format: 'series.name: \$point.y',
        ),
      ),
      series: <ChartSeries>[
        for (final categoryHistory in data)
          StackedColumnSeries<TimeIntValue, String>(
            animationDuration: 300,
            dataSource: categoryHistory.values.sublist(range.$1, range.$2),
            name: categoryHistory.category.name,
            color: categoryHistory.category.color,
            xValueMapper: (TimeIntValue data, _) => format.format(data.time),
            yValueMapper: (TimeIntValue data, _) =>
                data.value.asDollarDouble() *
                ((categoryHistory.category.type == ExpenseType.expense) ? -1 : 1),
          ),
      ],
    );
  }
}

final chartData1 = [
  CategoryHistory(
    testCategories[0],
    [
      TimeIntValue(time: DateTime(2010), value: 100),
      TimeIntValue(time: DateTime(2011), value: 200),
      TimeIntValue(time: DateTime(2012), value: 300),
    ],
  ),
  CategoryHistory(
    testCategories[1],
    [
      TimeIntValue(time: DateTime(2010), value: 500),
      TimeIntValue(time: DateTime(2011), value: 200),
      TimeIntValue(time: DateTime(2012), value: 300),
    ],
  ),
  CategoryHistory(
    testCategories[2],
    [
      TimeIntValue(time: DateTime(2010), value: 400),
      TimeIntValue(time: DateTime(2011), value: 200),
      TimeIntValue(time: DateTime(2012), value: 300),
    ],
  ),
];
