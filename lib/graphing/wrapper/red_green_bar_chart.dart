import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/components/buttons/time_frame_selector.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_axes.dart';
import 'package:libra_sheet/graphing/cartesian/discrete_cartesian_graph.dart';
import 'package:libra_sheet/graphing/cartesian/month_axis.dart';
import 'package:libra_sheet/graphing/series/dashed_horiztonal_line.dart';
import 'package:libra_sheet/graphing/series/series.dart';
import 'package:libra_sheet/graphing/series/column_series.dart';

final _dateFormat = DateFormat("MMM ''yy"); // single quote is escaped by doubling

/// This is a bar chart that plots a single series. Positive values are shown in green and negative
/// values are shown as red bars.
class RedGreenBarChart extends StatelessWidget {
  final List<TimeIntValue> data;
  const RedGreenBarChart(
    this.data, {
    super.key,
    this.onSelect,
    this.onRange,
  });

  final Function(int i, TimeIntValue)? onSelect;
  final Function(TimeFrame)? onRange;

  @override
  Widget build(BuildContext context) {
    final average = getDollarAverage2(data, (it) => it.value);
    final months = data.map((e) => e.time).toList();
    return DiscreteCartesianGraph(
      yAxis: CartesianAxis(
        theme: Theme.of(context),
        axisLoc: null,
        valToString: formatDollar,
      ),
      xAxis: MonthAxis(
        theme: Theme.of(context),
        axisLoc: 0,
        dates: months,
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
          fillColorMapper: (i, item) => item.value > 0 ? Colors.green : Colors.red,
        ),
      ]),
      onTap: (onSelect == null) ? null : (_, __, i) => onSelect!(i, data[i]),
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
