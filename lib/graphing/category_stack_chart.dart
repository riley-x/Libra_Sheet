import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

Widget trackballTooltipBuilder(BuildContext context, TrackballDetails trackballDetails) {
  return Container(
    width: 70,
    decoration: const BoxDecoration(color: Color.fromRGBO(66, 244, 164, 1)),
    child: Text('${trackballDetails.point?.cumulativeValue}'),
  );
}

/// Displays a stacked bar chart for category data. [data] should contain unstacked values in order
/// from bottom to top.
///
/// [range] can be optionally specified to make filtering on [data] simple. These are the [start, end)
/// indices in [data] to sublist. In this case each entry in [data.values] must have the same length.
/// Settings it to null will use the full range.
class CategoryStackChart extends StatelessWidget {
  final List<CategoryHistory> data;
  final (int, int)? range;
  final TrackballDisplayMode trackballDisplayMode;

  const CategoryStackChart(
    this.data,
    this.range, {
    super.key,
    this.trackballDisplayMode = TrackballDisplayMode.groupAllPoints,
  });

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
        tooltipDisplayMode: trackballDisplayMode,
        // builder: trackballDisplayMode == TrackballDisplayMode.nearestPoint ? trackballTooltipBuilder: null,
        /// The custom tooltip format totally messes up the tooltip in the groupAllPoints for some reason
        tooltipSettings: trackballDisplayMode == TrackballDisplayMode.groupAllPoints
            ? const InteractiveTooltip()
            : const InteractiveTooltip(format: 'series.name: \$point.y'),
      ),
      series: <ChartSeries>[
        for (final categoryHistory in data)
          StackedColumnSeries<TimeIntValue, String>(
            animationDuration: 300,
            dataSource: (range != null)
                ? categoryHistory.values.sublist(range!.$1, range!.$2)
                : categoryHistory.values,
            name: categoryHistory.category.name,
            color: categoryHistory.category.color,
            xValueMapper: (TimeIntValue data, _) => format.format(data.time),
            yValueMapper: (TimeIntValue data, _) => data.value.asDollarDouble(),
          ),
      ],
    );
  }
}
