import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

class DateTimeGraph extends StatelessWidget {
  final List<ChartSeries> data;

  const DateTimeGraph(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No data',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(
        // dateFormat: DateFormat.y(),
        dateFormat: DateFormat("MMM ''yy"),
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
      series: data,
      // <ChartSeries>[
      //   LineSeries<TimeValue, DateTime>(
      //     animationDuration: 300,
      //     dataSource: appState.chartData,
      //     xValueMapper: (TimeValue sales, _) => sales.time,
      //     yValueMapper: (TimeValue sales, _) => sales.value,
      //   ),
      // ],
    );
  }
}
