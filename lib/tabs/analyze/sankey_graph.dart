import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/sankey/tiered_sankey_plot.dart';
import 'package:libra_sheet/tabs/analyze/analyze_tab_state.dart';

(Widget, List<Widget>) sankeyGraph(BuildContext context, AnalyzeTabState state, ThemeData theme) {
  final graph = TieredSankeyPlot(nodes: state.sankeyNodes);

  return (graph, const []);
}
