import 'package:dash_painter/dash_painter.dart';
import 'package:flutter/material.dart';
import 'package:libra_sheet/components/buttons/time_frame_selector.dart';
import 'package:libra_sheet/components/menus/account_checkbox_menu.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filters.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/date_time_utils.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_axes.dart';
import 'package:libra_sheet/graphing/cartesian/discrete_cartesian_graph.dart';
import 'package:libra_sheet/graphing/cartesian/month_axis.dart';
import 'package:libra_sheet/graphing/cartesian/pooled_tooltip.dart';
import 'package:libra_sheet/graphing/series/dashed_horiztonal_line.dart';
import 'package:libra_sheet/graphing/series/line_series.dart';
import 'package:libra_sheet/graphing/series/series.dart';
import 'package:libra_sheet/graphing/series/stack_column_series.dart';
import 'package:libra_sheet/graphing/wrapper/category_stack_chart.dart';
import 'package:libra_sheet/tabs/analyze/analyze_tab_state.dart';
import 'package:libra_sheet/tabs/analyze/analyze_tab_view_selector.dart';
import 'package:libra_sheet/tabs/analyze/analyze_tab_view_state.dart';
import 'package:libra_sheet/tabs/navigation/libra_navigation.dart';
import 'package:provider/provider.dart';

class AnalyzeTab extends StatelessWidget {
  const AnalyzeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _Charts()),
        VerticalDivider(width: 1, thickness: 1),
        SizedBox(width: 20),
        SizedBox(width: 250, child: _Options()),
        SizedBox(width: 20),
      ],
    );
  }
}

class _Charts extends StatelessWidget {
  const _Charts({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AnalyzeTabState>();
    final currentView = state.currentView;
    final theme = Theme.of(context);

    final Widget graph;
    final List<Widget> headerElements;
    switch (currentView) {
      case AnalyzeTabView.doubleStack:
        (graph, headerElements) = _doubleSidedGraph(context, state, theme);
      case AnalyzeTabView.netIncome:
        (graph, headerElements) = _netIncomeGraph(state, theme);
      default:
        (graph, headerElements) = (const Placeholder(), const []);
    }

    return Column(
      children: [
        SizedBox(
          height: 42, // height of checkbox inkwell
          child: Row(
            children: [
              if (headerElements.isNotEmpty) ...[
                const SizedBox(width: 10),
                // Text(
                //   'View Options',
                //   style: Theme.of(context)
                //       .textTheme
                //       .labelLarge
                //       ?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer),
                // ),
                // const SizedBox(width: 20),
                ...headerElements,
              ],
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
        Expanded(child: graph),
        const SizedBox(height: 10),
      ],
    );
  }
}

(Widget, List<Widget>) _doubleSidedGraph(
    BuildContext context, AnalyzeTabState state, ThemeData theme) {
  final range = state.timeFrame.getRange(state.incomeData.times);
  final viewState = state.currentViewState as DoubleStackView;
  final total = state.netIncome.looseRange(range).sum();

  void onTap(Category category, DateTime month) {
    toCategoryScreen(
      context,
      category,
      initialHistoryTimeFrame: state.timeFrame,
      initialFilters: TransactionFilters(
        startTime: month,
        endTime: month.monthEnd(),
        categories: CategoryTristateMap({category}),
        accounts: Set.from(state.accounts),
      ),
    );
  }

  final headerElements = [
    Text('Show Subcats', style: theme.textTheme.bodyMedium),
    const SizedBox(width: 10),
    Checkbox(
      value: viewState.showSubcats,
      onChanged: (bool? value) => state.setViewState(viewState.withSubcats(value == true)),
    ),
    const Spacer(),
    Text('Total: ${total.dollarString()}'),
    const SizedBox(width: 10),
  ];

  final graph = CategoryStackChart(
    data: viewState.showSubcats ? state.combinedHistorySubCats : state.combinedHistory,
    range: range,
    onTap: (category, month) => onTap(category, month),
    onRange: state.setTimeFrame,
    xAxis: MonthAxis(
      theme: Theme.of(context),
      axisLoc: 0,
      dates: state.combinedHistory.times.looseRange(range),
      axisPainter: Paint()
        ..color = Theme.of(context).colorScheme.onSurface
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..isAntiAlias = false,
    ),
    extraSeriesBefore: [
      DashedHorizontalLine(
        y: state.incomeData.getDollarAverageMonthlyTotal(range),
        color: Colors.green,
        lineWidth: 1.5,
      ),
      DashedHorizontalLine(
        y: state.expenseData.getDollarAverageMonthlyTotal(range),
        color: Colors.red.shade700,
        lineWidth: 1.5,
      ),
    ],
  );

  return (graph, headerElements);
}

(Widget, List<Widget>) _netIncomeGraph(AnalyzeTabState state, ThemeData theme) {
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

class _Options extends StatelessWidget {
  const _Options({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AnalyzeTabState>();
    return Column(
      children: [
        /// Title
        const SizedBox(height: 10),
        Text(
          "Options",
          style: Theme.of(context).textTheme.headlineMedium,
        ),

        /// Type
        const SizedBox(height: 10),
        const Text("Display"),
        const SizedBox(height: 5),
        const AnalyzeTabViewSelector(),

        /// Time frame
        const SizedBox(height: 15),
        const Text("Time Frame"),
        const SizedBox(height: 5),
        const _TimeFrameSelector(),

        /// Accounts
        const SizedBox(height: 15),
        AccountChips(
          selected: state.accounts,
          style: Theme.of(context).textTheme.bodyMedium,
          whenChanged: (_, __) => state.load(),
        ),
      ],
    );
  }
}

/// Segmented button for the time frame
class _TimeFrameSelector extends StatelessWidget {
  const _TimeFrameSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final monthList = context.watch<LibraAppState>().monthList;
    final state = context.watch<AnalyzeTabState>();
    return TimeFrameSelector(
      months: monthList,
      selected: state.timeFrame,
      onSelect: state.setTimeFrame,
    );
  }
}
