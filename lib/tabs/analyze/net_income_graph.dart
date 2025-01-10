import 'package:dash_painter/dash_painter.dart';
import 'package:flutter/material.dart';
import 'package:libra_sheet/components/buttons/time_frame_selector.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_axes.dart';
import 'package:libra_sheet/graphing/cartesian/discrete_cartesian_graph.dart';
import 'package:libra_sheet/graphing/cartesian/month_axis.dart';
import 'package:libra_sheet/graphing/cartesian/pooled_tooltip.dart';
import 'package:libra_sheet/graphing/series/dashed_horiztonal_line.dart';
import 'package:libra_sheet/graphing/series/line_series.dart';
import 'package:libra_sheet/graphing/series/series.dart';
import 'package:libra_sheet/graphing/series/stack_column_series.dart';
import 'package:libra_sheet/tabs/analyze/analyze_tab_state.dart';
import 'package:libra_sheet/tabs/analyze/analyze_tab_view_state.dart';

(Widget, List<Widget>) netIncomeGraph(AnalyzeTabState state, ThemeData theme) {
  final viewState = state.currentViewState as NetIncomeView;
  final range = state.timeFrame.getRange(state.incomeData.times);
  final dates = state.combinedHistory.times.looseRange(range);

  final total = viewState.includeOther == true
      ? state.netIncome.looseRange(range).sum() + state.netOther.looseRange(range).sum()
      : viewState.includeOther == null
          ? state.netOther.looseRange(range).sum()
          : state.netIncome.looseRange(range).sum();
  final average = total.asDollarDouble() / dates.length;

  final headerElements = [
    Text('Include Other', style: theme.textTheme.bodyMedium),
    const SizedBox(width: 10),
    Checkbox(
      value: viewState.includeOther,
      onChanged: (bool? value) => state.setViewState(viewState.withOther(value)),
      tristate: true,
    ),
    const Spacer(),
    Text('Total: ${total.dollarString()}'),
    const SizedBox(width: 10),
  ];

  final graph = DiscreteCartesianGraph(
    yAxis: CartesianAxis(
      theme: theme,
      axisLoc: null,
      valToString: formatDollar,
    ),
    xAxis: MonthAxis(
      theme: theme,
      axisLoc: 0,
      dates: dates,
    ),
    data: SeriesCollection([
      DashedHorizontalLine(
        color: viewState.includeOther == null ? Colors.blue : theme.colorScheme.onSurface,
        y: average,
        lineWidth: 0,
      ),
      if (viewState.includeOther != null) ...[
        LineSeries<int>(
          name: "Total Income",
          color: Colors.green,
          strokeWidth: 0.5,
          dash: const DashPainter(step: 2, span: 5),
          data: state.incomeData.getMonthlyTotals(range),
          valueMapper: (i, item) => Offset(i.toDouble(), item.asDollarDouble()),
          gradient: LinearGradient(
            colors: [
              Colors.green.withAlpha(0),
              Colors.green.withAlpha(40),
              Colors.green.withAlpha(100),
            ],
            stops: const [0, 0.6, 1],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        LineSeries<int>(
          name: "Total Expenses",
          color: Colors.red.shade700,
          strokeWidth: 0.5,
          dash: const DashPainter(step: 2, span: 5),
          data: state.expenseData.getMonthlyTotals(range).invert(),
          valueMapper: (i, item) => Offset(i.toDouble(), item.asDollarDouble()),
          gradient: LinearGradient(
            colors: [
              Colors.red.shade700.withAlpha(0),
              Colors.red.shade700.withAlpha(40),
              Colors.red.shade700.withAlpha(100),
            ],
            stops: const [0, 0.6, 1],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        StackColumnSeries<TimeIntValue>(
          name: 'Net Income',
          width: 0.6,
          data: state.netIncome.looseRange(range),
          valueMapper: (i, item) => item.value.asDollarDouble(),
          fillColorMapper: (i, item) => item.value > 0 ? Colors.green : Colors.red,
        ),
      ],
      if (viewState.includeOther != false)
        StackColumnSeries<TimeIntValue>(
          name: 'Net Other',
          width: 0.6,
          data: state.netOther.looseRange(range),
          valueMapper: (i, item) => item.value.asDollarDouble(),
          fillColorMapper: (i, item) => Colors.blue.withAlpha(50), // match CategoryStackChart
          strokeColor: Colors.blue,
        ),
    ]),
    hoverTooltip: (painter, loc) => PooledTooltip(
      painter,
      loc,
      includeTotal: false,
    ),
    onRange: (xStart, xEnd) => state.setTimeFrame(
      TimeFrame(
        TimeFrameEnum.custom,
        customStart: dates[xStart],
        customEndInclusive: dates[xEnd],
      ),
    ),
  );

  return (graph, headerElements);
}
