import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_axes.dart';
import 'package:libra_sheet/graphing/cartesian/discrete_cartesian_graph.dart';
import 'package:libra_sheet/graphing/cartesian/month_axis.dart';
import 'package:libra_sheet/graphing/series/series.dart';
import 'package:libra_sheet/graphing/series/stack_column_series.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// TODO change input format so we don't need this
List<DateTime> _getDefaultDates() {
  final now = DateTime.now();
  return [
    for (int i = 0; i < 12; i++) DateTime(now.year, now.month - i, 1),
  ];
}

final _defaultDates = _getDefaultDates();

/// Displays a stacked bar chart for category data. [data] should contain unstacked values in order
/// from bottom to top.
///
/// [range] can be optionally specified to make filtering on [data] simple. These are the [start, end)
/// indices in [data] to sublist. In this case each entry in [data.values] must have the same length.
/// Setting it to null will use the full range.
class CategoryStackChart extends StatelessWidget {
  final List<CategoryHistory> data;
  final (int, int)? range;
  final Function(Category, DateTime)? onTap;

  const CategoryStackChart({
    super.key,
    required this.data,
    this.range,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DiscreteCartesianGraph(
      yAxis: CartesianAxis(
        theme: Theme.of(context),
        axisLoc: null,
        valToString: formatOrder,
      ),
      xAxis: MonthAxis(
        theme: Theme.of(context),
        axisLoc: 0,
        dates: data.firstOrNull?.values.map((e) => e.time).toList() ?? _defaultDates,
        // gridLines: [],
      ),
      data: SeriesCollection([
        for (final categoryHistory in data)
          StackColumnSeries<TimeIntValue>(
            name: categoryHistory.category.name,
            color: categoryHistory.category.color,
            data: (range != null)
                ? categoryHistory.values.sublist(range!.$1, range!.$2)
                : categoryHistory.values,
            valueMapper: (i, item) => item.value.asDollarDouble(),
          ),
      ]),
      onTap: (onTap == null)
          ? null
          : (iSeries, series, iData) {
              if (range != null) iData += range!.$1;
              onTap?.call(data[iSeries].category, data[iSeries].values[iData].time);
            },
    );
  }
}

class SyncfusionCategoryStackChart extends StatelessWidget {
  final List<CategoryHistory> data;
  final (int, int)? range;
  final TrackballDisplayMode trackballDisplayMode;

  const SyncfusionCategoryStackChart(
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

            /// Problem with onPointTap: this can trigger multiple times on nearby points, seems to
            /// have some fudge allowance on click position.
            // onPointTap: (pointInteractionDetails) {
            //   if (pointInteractionDetails.pointIndex != null) {
            //     // CartesianChartPoint x =
            //     //     pointInteractionDetails.dataPoints?[pointInteractionDetails.pointIndex!];
            //     print(pointInteractionDetails.pointIndex);
            //     print(pointInteractionDetails.seriesIndex);
            //   }
            // },
          ),
      ],
    );
  }
}
