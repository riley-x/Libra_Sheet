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
          // These options move the axis the y=0, but it looks bad because the boxes overlap it.
          // placeLabelsNearAxisLine: false,
          // crossesAt: 0,
          // axisLine: const AxisLine(color: Colors.black, width: 2),
          // majorTickLines: const MajorTickLines(size: 0),
          // majorGridLines: const MajorGridLines(width: 0),
          ),
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        // tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
        // tooltipSettings: const InteractiveTooltip(
        //   format: 'series.name: \$point.y', // This totally messes up the tooltip for some reason
        // ),
      ),

      series: <ChartSeries>[
        ColumnSeries<TimeIntValue, String>(
          animationDuration: 300,
          dataSource: data,
          pointColorMapper: (datum, index) => (datum.value >= 0) ? Colors.green : Colors.red,
          xValueMapper: (datum, index) => _dateFormat.format(datum.time),
          yValueMapper: (datum, index) => datum.value.asDollarDouble(),
        ),
        LineSeries(
          name: "y = 0",
          xAxisName: '2nd xAxis',
          dataSource: data,
          xValueMapper: (datum, index) => _dateFormat.format(datum.time),
          yValueMapper: (datum, index) => 0,
          enableTooltip: false,
          color: Theme.of(context).colorScheme.onBackground,
          width: 2,
          animationDuration: 0,
        ),
      ],

      /// Create a second axis so that the y=0 line starts from the edges
      /// https://www.syncfusion.com/forums/179342/categoryaxis-with-splineseries-and-column-overlap-issue
      axes: [
        CategoryAxis(
          name: '2nd xAxis',
          labelPlacement: LabelPlacement.onTicks,
          isVisible: false,
        ),
      ],

      /// Hide the trackball for the y=0 line
      /// https://www.syncfusion.com/forums/154846/how-to-disable-a-trackball-for-a-specific-series
      onTrackballPositionChanging: (TrackballArgs args) {
        ChartSeries<dynamic, dynamic>? series = args.chartPointInfo.series;
        if (series?.name == "y = 0") {
          args.chartPointInfo.header = '';
          args.chartPointInfo.label = '';
        }
      },
    );
  }
}
