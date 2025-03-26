import 'package:flutter/material.dart';
import 'package:libra_sheet/components/dialogs/confirmation_dialog.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filters.dart';
import 'package:libra_sheet/data/date_time_utils.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/graphing/wrapper/red_green_bar_chart.dart';
import 'package:libra_sheet/tabs/analyze/analyze_tab_state.dart';
import 'package:libra_sheet/tabs/analyze/analyze_tab_view_state.dart';
import 'package:libra_sheet/tabs/navigation/libra_navigation.dart';

(Widget, List<Widget>) otherGraph(BuildContext context, AnalyzeTabState state, ThemeData theme) {
  final viewState = state.currentViewState as OtherView;
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
    Text('Cumulative', style: theme.textTheme.bodyMedium),
    const SizedBox(width: 10),
    Checkbox(
      value: viewState.cumulative,
      onChanged: (bool? value) => state.setViewState(viewState.withCumulative(value == true)),
    ),
    const Spacer(),
    Text('Total: ${total.dollarString()}'),
    const SizedBox(width: 10),
    IconButton(
      icon: const Icon(Icons.info_outline),
      onPressed: () {
        showConfirmationDialog(
          context: context,
          title: 'Net Other',
          msg: 'This graph shows the net value of all transactions categorized'
              ' as the special "Other" category.',
          showCancel: false,
        );
      },
    ),
    const SizedBox(width: 10),
  ];

  final graph = RedGreenBarChart(
    state.netOther.looseRange(range).cumulate(viewState.cumulative),
    onSelect: (_, point) => toCategory(point.time),
    onRange: state.setTimeFrame,
    showAverage: !viewState.cumulative,
  );

  return (graph, headerElements);
}
