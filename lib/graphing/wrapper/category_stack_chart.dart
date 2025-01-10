import 'package:flutter/material.dart';
import 'package:libra_sheet/components/buttons/time_frame_selector.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_axes.dart';
import 'package:libra_sheet/graphing/cartesian/discrete_cartesian_graph.dart';
import 'package:libra_sheet/graphing/cartesian/month_axis.dart';
import 'package:libra_sheet/graphing/series/dashed_horiztonal_line.dart';
import 'package:libra_sheet/graphing/series/series.dart';
import 'package:libra_sheet/graphing/series/stack_column_series.dart';

import '../cartesian/pooled_tooltip.dart';

/// Displays a stacked bar chart for category data. [data] should contain unstacked values in order
/// from bottom to top.
///
/// [range] can be optionally specified to make filtering on [data] simple. These are the [start, end)
/// indices in [data] to sublist. Setting it to null will use the full range.
class CategoryStackChart extends StatelessWidget {
  final CategoryHistory data;
  final (int, int)? range;
  final Function(Category, DateTime)? onTap;
  final Function(TimeFrame)? onRange;
  final Widget? Function(DiscreteCartesianGraphPainter, int?)? hoverTooltip;
  final MonthAxis? xAxis;
  final CartesianAxis? yAxis;
  final List<Series> extraSeriesBefore;
  final List<Series> extraSeries;
  final double? width;

  /// If not null, will draw a dashed line behind the bars to indicate the average.
  final Color? averageColor;

  const CategoryStackChart({
    super.key,
    required this.data,
    this.range,
    this.onTap,
    this.onRange,
    this.averageColor,
    this.hoverTooltip,
    this.xAxis,
    this.yAxis,
    this.width,
    this.extraSeriesBefore = const [],
    this.extraSeries = const [],
  });

  @override
  Widget build(BuildContext context) {
    final positiveSeries = <Series>[];
    final negativeSeries = <Series>[];

    final positiveCategories = <Category>[];
    final negativeCategories = <Category>[];

    void splitDoubleSided(CategoryHistoryEntry categoryHistory, Color color) {
      final posSeries = StackColumnSeries<int>(
        name: categoryHistory.category.name,
        width: width,
        fillColor: color.withAlpha(50),
        strokeColor: color,
        data: categoryHistory.values.looseRange(range),
        valueMapper: (i, item) => item >= 0 ? item.asDollarDouble() : 0,
      );
      final negSeries = StackColumnSeries<int>(
        name: categoryHistory.category.name,
        width: width,
        fillColor: color.withAlpha(50),
        strokeColor: color,
        data: categoryHistory.values.looseRange(range),
        valueMapper: (i, item) => item <= 0 ? item.asDollarDouble() : 0,
      );
      positiveSeries.add(posSeries);
      negativeSeries.add(negSeries);
      positiveCategories.add(categoryHistory.category);
      negativeCategories.add(categoryHistory.category);
    }

    for (final categoryHistory in data.categories) {
      if (categoryHistory.category.isOther) {
        splitDoubleSided(categoryHistory, Colors.blue);
      } else if (categoryHistory.category == Category.ignore) {
        splitDoubleSided(categoryHistory, Colors.grey.shade500);
      } else {
        final series = StackColumnSeries<int>(
          name: categoryHistory.category.name,
          width: width,
          fillColor: categoryHistory.category.color,
          data: categoryHistory.values.looseRange(range),
          valueMapper: (i, item) => item.asDollarDouble(),
        );

        if (categoryHistory.category.type == ExpenseFilterType.expense) {
          negativeSeries.add(series);
          negativeCategories.add(categoryHistory.category);
        } else {
          positiveSeries.add(series);
          positiveCategories.add(categoryHistory.category);
        }
      }
    }

    // Using [looseRange] here is pretty important because if [range] is calculated in a Widget
    // build and [data] is calculated in a notifier callback or async, they can be out of sync.
    final months = data.times.looseRange(range);
    return DiscreteCartesianGraph(
      yAxis: yAxis ??
          CartesianAxis(
            theme: Theme.of(context),
            axisLoc: null,
            valToString: formatDollar,
          ),
      xAxis: xAxis ??
          MonthAxis(
            theme: Theme.of(context),
            axisLoc: 0,
            dates: months,
          ),
      data: SeriesCollection([
        ...extraSeriesBefore,
        if (averageColor != null)
          DashedHorizontalLine(
            y: data.getDollarAverageMonthlyTotal(range),
            color: averageColor!,
            lineWidth: 1.5,
          ),
        ...positiveSeries,
        ...negativeSeries,
        ...extraSeries,
      ]),
      hoverTooltip: hoverTooltip ??
          (painter, loc) => PooledTooltip(
                painter,
                loc,

                /// Positive expenses => inverted (first entry is bottom of stack)
                /// Negative expenses => normal
                series: positiveSeries.reversed.toList() + negativeSeries,
              ),
      onTap: (onTap == null)
          ? null
          : (iSeries, series, iData) {
              if (range != null) iData += range!.$1;

              iSeries -= extraSeriesBefore.length;
              if (averageColor != null) iSeries--;

              if (iSeries < positiveCategories.length) {
                onTap?.call(positiveCategories[iSeries], data.times[iData]);
              } else {
                onTap?.call(
                    negativeCategories[iSeries - positiveCategories.length], data.times[iData]);
              }
            },
      onRange: (onRange == null)
          ? null
          : (xStart, xEnd) => onRange!(TimeFrame(
                TimeFrameEnum.custom,
                customStart: months[xStart],
                customEndInclusive: months[xEnd],
              )),
    );
  }
}
