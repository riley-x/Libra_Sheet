import 'package:flutter/material.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filters.dart';
import 'package:libra_sheet/data/date_time_utils.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/graphing/wrapper/red_green_bar_chart.dart';
import 'package:libra_sheet/tabs/analyze/analyze_tab_state.dart';
import 'package:libra_sheet/tabs/navigation/libra_navigation.dart';

(Widget, List<Widget>) otherGraph(BuildContext context, AnalyzeTabState state, ThemeData theme) {
  final range = state.timeFrame.getRange(state.incomeData.times);
  final total = state.netOther.looseRange(range).sum();

  void toCategory(DateTime month) {
    toCategoryScreen(
      context,
      Category.other,
      initialHistoryTimeFrame: state.timeFrame,
      initialFilters: TransactionFilters(
        startTime: month,
        endTime: month.monthEnd(),
        categories: CategoryTristateMap({Category.other}),
        accounts: Set.from(state.accounts),
      ),
    );
  }

  final headerElements = [
    Text(
      'Net value of transactions categorized as "Other"',
      style: theme.textTheme.labelLarge,
    ),
    const Spacer(),
    Text('Total: ${total.dollarString()}'),
    const SizedBox(width: 10),
  ];

  final graph = RedGreenBarChart(
    state.netOther.looseRange(range),
    onSelect: (_, point) => toCategory(point.time),
    onRange: state.setTimeFrame,
  );

  return (graph, headerElements);
}
