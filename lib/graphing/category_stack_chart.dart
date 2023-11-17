import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class CategoryStackChart extends StatelessWidget {
  final List<CategoryHistory> data;
  const CategoryStackChart(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    final format =
        DateFormat("MMM ''yy"); // single quote is escaped by doubling
    return SfCartesianChart(
      primaryXAxis: CategoryAxis(
          // visibleMinimum: 0.5,
          // visibleMaximum: 1.5,
          ),
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        tooltipSettings: const InteractiveTooltip(
          format: 'series.name: \$point.y',
        ),
      ),
      series: <ChartSeries>[
        for (final categoryHistory in chartData1)
          StackedColumnSeries<TimeValue, String>(
            dataSource: categoryHistory.values,
            name: categoryHistory.category.name,
            xValueMapper: (TimeValue data, _) => format.format(data.time),
            yValueMapper: (TimeValue data, _) => data.value,
          ),
      ],
    );
  }
}

final chartData1 = [
  CategoryHistory(
    Category(name: "category1"),
    [
      TimeValue(time: DateTime(2010), value: 100),
      TimeValue(time: DateTime(2011), value: 200),
      TimeValue(time: DateTime(2012), value: 300),
      TimeValue(time: DateTime(2013), value: 300),
      TimeValue(time: DateTime(2014), value: 300),
    ],
  ),
  CategoryHistory(
    Category(name: "category2"),
    [
      TimeValue(time: DateTime(2010), value: 100),
      TimeValue(time: DateTime(2011), value: 200),
      TimeValue(time: DateTime(2012), value: 300),
    ],
  ),
  CategoryHistory(
    Category(name: "category3"),
    [
      TimeValue(time: DateTime(2010), value: 100),
      TimeValue(time: DateTime(2011), value: 200),
      TimeValue(time: DateTime(2012), value: 300),
    ],
  ),
];
