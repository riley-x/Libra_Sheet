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
      primaryXAxis: DateTimeAxis(
        // dateFormat: DateFormat.y(),
        dateFormat: DateFormat.yMMM(),
        // interactiveTooltip: InteractiveTooltip(
        //   enable: true,
        //   borderColor: Colors.red,
        //   borderWidth: 2,
        // ),
        // majorGridLines: const MajorGridLines(width: 0),
      ),
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        tooltipSettings: const InteractiveTooltip(
          format: 'point.x: \$point.y',
        ),
      ),
      // zoomPanBehavior: ZoomPanBehavior( // this needs to elevate to a StatefulWidget I think
      //   enableSelectionZooming: true,
      //   selectionRectBorderColor: Colors.red,
      //   selectionRectBorderWidth: 1,
      //   selectionRectColor: Colors.grey,
      // ),
      series: <ChartSeries>[
        LineSeries<TimeValue, DateTime>(
          dataSource: appState.chartData,
          xValueMapper: (TimeValue sales, _) => sales.time,
          yValueMapper: (TimeValue sales, _) => sales.value,
        ),
      ],
    );
  }
}
