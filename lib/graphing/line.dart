import 'package:libra_sheet/data/test_state.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

class TestGraph extends StatelessWidget {
  const TestGraph({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<LibraAppState>();

    return SfCartesianChart(
      primaryXAxis: DateTimeCategoryAxis(
        // dateFormat: DateFormat.y(),
        dateFormat: DateFormat.yMMMd(),
        majorGridLines: const MajorGridLines(width: 0),
      ),
      series: <ChartSeries>[
        LineSeries<TimeValue, DateTime>(
          dataSource: appState.chartData,
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
