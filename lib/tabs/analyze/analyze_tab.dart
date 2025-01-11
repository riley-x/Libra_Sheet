import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/components/buttons/time_frame_selector.dart';
import 'package:libra_sheet/components/menus/account_checkbox_menu.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_axes.dart';
import 'package:libra_sheet/graphing/cartesian/month_axis.dart';
import 'package:libra_sheet/graphing/cartesian/pooled_tooltip.dart';
import 'package:libra_sheet/graphing/series/rectangle_series.dart';
import 'package:libra_sheet/graphing/wrapper/category_stack_chart.dart';
import 'package:libra_sheet/tabs/analyze/analyze_tab_state.dart';
import 'package:libra_sheet/tabs/analyze/analyze_tab_view_selector.dart';
import 'package:libra_sheet/tabs/analyze/analyze_tab_view_state.dart';
import 'package:libra_sheet/tabs/analyze/double_sided_graph.dart';
import 'package:libra_sheet/tabs/analyze/flows_graph.dart';
import 'package:libra_sheet/tabs/analyze/heatmap_graph.dart';
import 'package:libra_sheet/tabs/analyze/net_income_graph.dart';
import 'package:provider/provider.dart';

class AnalyzeTab extends StatelessWidget {
  const AnalyzeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _Charts()),
        VerticalDivider(width: 1, thickness: 1),
        SizedBox(width: 290, child: _Options()),
      ],
    );
  }
}

class _Charts extends StatelessWidget {
  const _Charts({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AnalyzeTabState>();
    final appState = context.watch<LibraAppState>();
    final currentView = state.currentView;
    final theme = Theme.of(context);

    final Widget graph;
    final List<Widget> headerElements;
    switch (currentView) {
      case AnalyzeTabView.doubleStack:
        (graph, headerElements) = doubleSidedGraph(context, state, theme);
      case AnalyzeTabView.netIncome:
        (graph, headerElements) = netIncomeGraph(state, theme);
      case AnalyzeTabView.expenseFlow:
        (graph, headerElements) = flowsGraph(context, state, theme, true);
      case AnalyzeTabView.incomeFlow:
        (graph, headerElements) = flowsGraph(context, state, theme, false);
      case AnalyzeTabView.expenseHeatmap:
        final categories = [appState.categories.expense, ...appState.categories.expense.subCats];
        (graph, headerElements) = heatmapGraph(context, state, theme, categories);
      case AnalyzeTabView.incomeHeatmap:
        final categories = [appState.categories.income, ...appState.categories.income.subCats];
        (graph, headerElements) = heatmapGraph(context, state, theme, categories);
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

class _Options extends StatelessWidget {
  const _Options({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AnalyzeTabState>();
    final style = Theme.of(context).textTheme.titleMedium;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          /// Title
          const SizedBox(height: 10),
          Text(
            "Options",
            style: Theme.of(context).textTheme.headlineMedium,
          ),

          /// Type
          const SizedBox(height: 10),
          Text("Display", style: style),
          const SizedBox(height: 5),
          const AnalyzeTabViewSelector(),
          const SizedBox(height: 30),
          const Divider(height: 3, thickness: 3),

          /// Time frame
          const SizedBox(height: 15),
          Text("Time Frame", style: style),
          const SizedBox(height: 5),
          const _TimeFrameSelector(),
          const SizedBox(height: 30),
          const Divider(height: 3, thickness: 3),

          /// Accounts
          const SizedBox(height: 15),
          AccountChips(
            selected: state.accounts,
            style: style,
            whenChanged: (_, __) => state.load(),
          ),
        ],
      ),
    );
  }
}

/// Segmented button for the time frame
class _TimeFrameSelector extends StatelessWidget {
  const _TimeFrameSelector({super.key});
  static final _format = DateFormat.yMMM();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AnalyzeTabState>();
    final dates = state.combinedHistory.times;

    String getText() {
      if (state.timeFrame.selection == TimeFrameEnum.all) return '';
      final dateRange = state.timeFrame.getDateRange(dates);
      final startMonth = dateRange.$1 ?? dates.first;
      final endMonth = dateRange.$2 ?? dates.last;
      if (startMonth.isAtSameMomentAs(endMonth)) {
        return _format.format(startMonth);
      } else {
        return "${_format.format(startMonth)} - ${_format.format(endMonth)}";
      }
    }

    return Column(
      children: [
        TimeFrameSelector(
          months: dates,
          selected: state.timeFrame,
          onSelect: state.setTimeFrame,
        ),
        const SizedBox(height: 3),
        Text(getText(), style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 3),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: _MiniChart(),
        ),
      ],
    );
  }
}

class _MiniChart extends StatelessWidget {
  const _MiniChart({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AnalyzeTabState>();
    final dates = state.combinedHistory.times;

    /// Show a highlight of the currently selected range
    (int, int)? highlightRange = state.timeFrame.getRange(dates);
    if (highlightRange == (0, dates.length)) {
      highlightRange = null;
    } else {
      highlightRange = (highlightRange.$1, highlightRange.$2 - 1);
    }

    return SizedBox(
      height: 120,
      child: CategoryStackChart(
        xAxis: MonthAxis(
          theme: Theme.of(context),
          axisLoc: 0,
          dates: dates,
          axisPainter: Paint()
            ..color = Theme.of(context).colorScheme.outline
            ..strokeWidth = 1,
        ),
        yAxis: CartesianAxis(
          theme: Theme.of(context),
          axisLoc: null,
          labels: [],
        ),
        data: state.combinedHistory,
        onRange: state.setTimeFrame,
        hoverTooltip: (painter, i) => PooledTooltip(painter, i, series: const []), // just show date
        extraSeries: [
          if (highlightRange != null)
            RectangleSeries(
              name: 'Current Range',
              color: Colors.blue.withAlpha(80),
              data: [
                Rect.fromLTRB(
                  highlightRange.$1.toDouble(),
                  double.infinity,
                  highlightRange.$2.toDouble(),
                  double.infinity,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
