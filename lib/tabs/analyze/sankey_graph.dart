import 'package:flutter/material.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/graphing/sankey/tiered_sankey_plot.dart';
import 'package:libra_sheet/tabs/analyze/analyze_tab_state.dart';
import 'package:libra_sheet/tabs/analyze/analyze_tab_view_state.dart';

(Widget, List<Widget>) sankeyGraph(BuildContext context, AnalyzeTabState state, ThemeData theme) {
  final viewState = state.currentViewState as SankeyView;

  final graph = TieredSankeyPlot(
    nodes: state.sankeyNodes,
    valueToString: (value) =>
        viewState.showAverages ? (value / state.numMonths).formatDollar() : value.formatDollar(),
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
