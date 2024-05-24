import 'package:flutter/material.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_axes.dart';
import 'package:libra_sheet/graphing/cartesian/discrete_cartesian_graph.dart';
import 'package:libra_sheet/graphing/cartesian/month_axis.dart';
import 'package:libra_sheet/graphing/cartesian/snap_line_hover.dart';
import 'package:libra_sheet/graphing/series/dashed_horiztonal_line.dart';
import 'package:libra_sheet/graphing/series/series.dart';
import 'package:libra_sheet/graphing/series/stack_column_series.dart';

/// Displays a stacked bar chart for category data. [data] should contain unstacked values in order
/// from bottom to top.
///
/// [range] can be optionally specified to make filtering on [data] simple. These are the [start, end)
/// indices in [data] to sublist. Setting it to null will use the full range.
class CategoryStackChart extends StatelessWidget {
  final CategoryHistory data;
  final (int, int)? range;
  final Function(Category, DateTime)? onTap;

  /// If not null, will draw a dashed line behind the bars to indicate the average.
  final Color? averageColor;

  const CategoryStackChart({
    super.key,
    required this.data,
    this.range,
    this.onTap,
    this.averageColor,
  });

  @override
  Widget build(BuildContext context) {
    final incomeList = <Series>[];
    final expenseList = <Series>[];
    for (final categoryHistory in data.categories) {
      final series = StackColumnSeries<int>(
        name: categoryHistory.category.name,
        color: categoryHistory.category.color,
        data: categoryHistory.values.looseRange(range),
        valueMapper: (i, item) => item.asDollarDouble(),
      );

      if (!data.invertExpenses && categoryHistory.category.type == ExpenseFilterType.expense) {
        expenseList.add(series);
      } else {
        incomeList.add(series);
      }
    }

    return DiscreteCartesianGraph(
      yAxis: CartesianAxis(
        theme: Theme.of(context),
        axisLoc: null,
        valToString: formatDollar,
      ),
      xAxis: MonthAxis(
        theme: Theme.of(context),
        axisLoc: 0,
        dates: data.times.looseRange(range),
        // Using [looseRange] here is pretty important because if [range] is calculated in a Widget
        // build and [data] is calculated in a notifier callback or async, they can be out of sync.
      ),
      data: SeriesCollection([
        if (averageColor != null)
          DashedHorizontalLine(
            y: data.getDollarAverageMonthlyTotal(range),
            color: averageColor!,
            lineWidth: 1.5,
          ),
        ...incomeList,
        ...expenseList,
      ]),
      hoverTooltip: (painter, loc) => PooledTooltip(
        painter,
        loc,

        /// Positive expenses => inverted (first entry is bottom of stack)
        /// Negative expenses => normal
        series: incomeList.reversed.toList() + expenseList,
      ),
      onTap: (onTap == null)
          ? null
          : (iSeries, series, iData) {
              if (range != null) iData += range!.$1;
              // The -1 because of the dashed horizontal line inflates the series index by 1.
              if (averageColor != null) iSeries--;
              onTap?.call(data.categories[iSeries].category, data.times[iData]);
            },
    );
  }
}
