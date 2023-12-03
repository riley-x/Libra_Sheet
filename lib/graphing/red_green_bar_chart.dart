import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

final _dateFormat = DateFormat("MMM ''yy"); // single quote is escaped by doubling

/// This is a bar chart that plots a single series. Psotive values are shown in green and negative
/// values are shown as red bars.
class RedGreenBarChart extends StatelessWidget {
  final List<TimeIntValue> data;
  const RedGreenBarChart(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      primaryXAxis: CategoryAxis(
          // visibleMinimum: 0.5,
          // visibleMaximum: 1.5,
          ),
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
        // tooltipSettings: const InteractiveTooltip(
        //   format: 'series.name: \$point.y', // This totally messes up the tooltip for some reason
        // ),
      ),
      series: <ChartSeries>[
        ColumnSeries<TimeIntValue, String>(
          animationDuration: 300,
          dataSource: data,
          pointColorMapper: (datum, index) => (datum.value > 0) ? Colors.green : Colors.red,
          xValueMapper: (datum, index) => _dateFormat.format(datum.time),
          yValueMapper: (datum, index) => datum.value.asDollarDouble(),
        ),
      ],
    );
  }
}
