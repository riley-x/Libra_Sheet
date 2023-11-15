import 'package:libra_sheet/data/time_value.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

class TestGraph extends StatelessWidget {
  const TestGraph({super.key, required this.chartData});

  final List<TimeValue> chartData;

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      primaryXAxis: DateTimeCategoryAxis(
        // dateFormat: DateFormat.y(),
        dateFormat: DateFormat.yMMMd(),
      ),
      series: <ChartSeries>[
        LineSeries<TimeValue, DateTime>(
          dataSource: chartData,
          xValueMapper: (TimeValue sales, _) => sales.time,
          yValueMapper: (TimeValue sales, _) => sales.value,
        ),
      ],
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
      ),
    );
  }
}
