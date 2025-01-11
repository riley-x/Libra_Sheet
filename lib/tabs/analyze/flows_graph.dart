import 'package:flutter/material.dart';
import 'package:libra_sheet/components/buttons/time_frame_selector.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filters.dart';
import 'package:libra_sheet/data/date_time_utils.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_axes.dart';
import 'package:libra_sheet/graphing/cartesian/discrete_cartesian_graph.dart';
import 'package:libra_sheet/graphing/cartesian/month_axis.dart';
import 'package:libra_sheet/graphing/cartesian/pooled_tooltip.dart';
import 'package:libra_sheet/graphing/series/series.dart';
import 'package:libra_sheet/graphing/series/violin_series.dart';
import 'package:libra_sheet/tabs/analyze/analyze_tab_state.dart';
import 'package:libra_sheet/tabs/analyze/analyze_tab_view_state.dart';
import 'package:libra_sheet/tabs/navigation/libra_navigation.dart';

(Widget, List<Widget>) flowsGraph(
    BuildContext context, AnalyzeTabState state, ThemeData theme, bool isExpense) {
  final viewState = state.currentViewState as FlowsView;
  final range = state.timeFrame.getRange(state.incomeData.times);
  final dates = state.combinedHistory.times.looseRange(range);
  final history = isExpense
      ? (viewState.showSubcats ? state.expenseDataSubCats : state.expenseData)
      : (viewState.showSubcats ? state.incomeDataSubCats : state.incomeData);
  final spacing = history.getTotal(range).asDollarDouble().abs() * 0.001;

  final headerElements = <Widget>[
    // Text('Show Subcats', style: theme.textTheme.bodyMedium),
    // const SizedBox(width: 10),
    // Checkbox(
    //   value: viewState.showSubcats,
    //   onChanged: (bool? value) => state.setViewState(viewState.withSubcats(value == true)),
    // ),
    // const VerticalDivider(width: 30, thickness: 3, indent: 4, endIndent: 4),
    Text('Proportional', style: theme.textTheme.bodyMedium),
    const SizedBox(width: 10),
    Checkbox(
      value: !viewState.justified,
      onChanged: (bool? value) => state.setViewState(viewState.withJustified(value == false)),
    ),
  ];

  List<Series> createSeries() {
    final out = <Series>[];
    double total = 0;
    for (final categoryHistory in history.categories) {
      final values = categoryHistory.values.looseRange(range);
      final maxValue = values.max(abs: true).asDollarDouble();
      if (maxValue == 0) continue;

      out.add(ViolinSeries<int>(
        name: categoryHistory.category.name,
        color: categoryHistory.category.color,
        data: values,
        valueMapper: (i, val) => viewState.justified
            ? val.abs().asDollarDouble() / maxValue
            : val.abs().asDollarDouble(),
        labelMapper: (i, val) => val.abs().dollarString(),
        height: viewState.justified ? total + 0.5 : total + maxValue / 2,
      ));
      total += viewState.justified ? 1.01 : maxValue + spacing;
    }
    return out;
  }

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

  final graph = DiscreteCartesianGraph(
    yAxis: CartesianAxis(
      theme: theme,
      axisLoc: null,
      valToString: formatDollar,
      labels: [],
      dataPadFrac: 0.01,
    ),
    xAxis: MonthAxis(
      theme: theme,
      axisLoc: null,
      dates: dates,
    ),
    data: SeriesCollection([
      ...createSeries(),
    ]),
    hoverTooltip: (painter, loc) => PooledTooltip(
      painter,
      loc,
      includeTotal: false,
      reverse: true,
    ),
    onRange: (xStart, xEnd) => state.setTimeFrame(
      TimeFrame(
        TimeFrameEnum.custom,
        customStart: dates[xStart],
        customEndInclusive: dates[xEnd],
      ),
    ),
    onTap: (iSeries, series, iData) {
      onTap(history.categories[iSeries].category, dates[iData]);
    },
  );

  return (graph, headerElements);
}
