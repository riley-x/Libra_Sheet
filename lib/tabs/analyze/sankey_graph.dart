import 'package:flutter/material.dart';
import 'package:libra_sheet/components/buttons/time_frame_selector.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filters.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/graphing/sankey/sankey_node.dart';
import 'package:libra_sheet/graphing/sankey/tiered_sankey_plot.dart';
import 'package:libra_sheet/tabs/analyze/analyze_tab_state.dart';
import 'package:libra_sheet/tabs/analyze/analyze_tab_view_state.dart';
import 'package:libra_sheet/tabs/navigation/libra_navigation.dart';
import 'package:libra_sheet/data/date_time_utils.dart';

(Widget, List<Widget>) sankeyGraph(BuildContext context, AnalyzeTabState state, ThemeData theme) {
  final viewState = state.currentViewState as SankeyView;

  void onTap(SankeyNode node) {
    if (node.data != null && node.data is Category) {
      final dateRange = state.timeFrame.getDateRange(state.combinedHistory.times);
      toCategoryScreen(
        context,
        node.data,
        initialFilters: TransactionFilters(
          categories: CategoryTristateMap([node.data]),
          startTime: state.timeFrame.selection == TimeFrameEnum.all ? null : dateRange.$1,
          endTime:
              state.timeFrame.selection != TimeFrameEnum.custom ? null : dateRange.$2?.monthEnd(),
          accounts: state.accounts,
        ),
        initialHistoryTimeFrame: state.timeFrame,
      );
    }
  }

  final graph = Padding(
    padding: const EdgeInsets.only(top: 8.0, bottom: 2.0),
    child: TieredSankeyPlot(
      nodes: state.sankeyNodes,
      valueToString: (value) =>
          viewState.showAverages ? (value / state.numMonths).formatDollar() : value.formatDollar(),
      onTap: onTap,
    ),
  );

  final headerElements = [
    Text('Monthly Averages', style: theme.textTheme.bodyMedium),
    const SizedBox(width: 10),
    Checkbox(
      value: viewState.showAverages,
      onChanged: (bool? value) => state.setViewState(viewState.withAverages(value == true)),
    ),
  ];

  return (graph, headerElements);
}
