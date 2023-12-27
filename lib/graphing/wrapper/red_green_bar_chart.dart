import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_axes.dart';
import 'package:libra_sheet/graphing/cartesian/discrete_cartesian_graph.dart';
import 'package:libra_sheet/graphing/cartesian/month_axis.dart';
import 'package:libra_sheet/graphing/series/dashed_horiztonal_line.dart';
import 'package:libra_sheet/graphing/series/series.dart';
import 'package:libra_sheet/graphing/series/column_series.dart';
import 'package:syncfusion_flutter_charts/charts.dart' as syf;

final _dateFormat = DateFormat("MMM ''yy"); // single quote is escaped by doubling

/// This is a bar chart that plots a single series. Positive values are shown in green and negative
/// values are shown as red bars.
class RedGreenBarChart extends StatelessWidget {
  final List<TimeIntValue> data;
  const RedGreenBarChart(
    this.data, {
    super.key,
    this.onSelect,
  });

  final Function(int i, TimeIntValue)? onSelect;

  @override
  Widget build(BuildContext context) {
    final average = getDollarAverage2(data, (it) => it.value);
    return DiscreteCartesianGraph(
      yAxis: CartesianAxis(
        theme: Theme.of(context),
        axisLoc: null,
        valToString: formatOrder,
      ),
      xAxis: MonthAxis(
        theme: Theme.of(context),
        axisLoc: 0,
        dates: data.map((e) => e.time).toList(),
      ),
      data: SeriesCollection([
        DashedHorizontalLine(
          color: average > 0 ? Colors.green : Colors.red,
          y: average,
          lineWidth: 1.5,
        ),
        ColumnSeries<TimeIntValue>(
          name: '',
          data: data,
          valueMapper: (i, item) => item.value.asDollarDouble(),
          colorMapper: (i, item) => item.value > 0 ? Colors.green : Colors.red,
        ),
      ]),
      onTap: (onSelect == null) ? null : (_, __, i) => onSelect!(i, data[i]),
    );
  }
}

/// This is a bar chart that plots a single series. Psotive values are shown in green and negative
/// values are shown as red bars.
class SyncfusionRedGreenBarChart extends StatelessWidget {
  final List<TimeIntValue> data;
  const SyncfusionRedGreenBarChart(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return syf.SfCartesianChart(
      primaryXAxis: syf.CategoryAxis(
          // These options move the axis the y=0, but it looks bad because the boxes overlap it.
          // placeLabelsNearAxisLine: false,
          // crossesAt: 0,
          // axisLine: const AxisLine(color: Colors.black, width: 2),
          // majorTickLines: const MajorTickLines(size: 0),
          // majorGridLines: const MajorGridLines(width: 0),
          ),
      trackballBehavior: syf.TrackballBehavior(
        enable: true,
        activationMode: syf.ActivationMode.singleTap,
        // tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
        // tooltipSettings: const InteractiveTooltip(
        //   format: 'series.name: \$point.y', // This totally messes up the tooltip for some reason
        // ),
      ),

      series: <syf.ChartSeries>[
        syf.ColumnSeries<TimeIntValue, String>(
          animationDuration: 300,
          dataSource: data,
          pointColorMapper: (datum, index) => (datum.value >= 0) ? Colors.green : Colors.red,
          xValueMapper: (datum, index) => _dateFormat.format(datum.time),
          yValueMapper: (datum, index) => datum.value.asDollarDouble(),
        ),
        syf.LineSeries(
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
        syf.CategoryAxis(
          name: '2nd xAxis',
          labelPlacement: syf.LabelPlacement.onTicks,
          isVisible: false,
        ),
      ],

      /// Hide the trackball for the y=0 line
      /// https://www.syncfusion.com/forums/154846/how-to-disable-a-trackball-for-a-specific-series
      onTrackballPositionChanging: (syf.TrackballArgs args) {
        syf.ChartSeries<dynamic, dynamic>? series = args.chartPointInfo.series;
        if (series?.name == "y = 0") {
          args.chartPointInfo.header = '';
          args.chartPointInfo.label = '';
        }
      },
    );
  }
}
