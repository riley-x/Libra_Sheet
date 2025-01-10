import 'package:flutter/material.dart';
import 'package:libra_sheet/components/buttons/time_frame_selector.dart';
import 'package:libra_sheet/components/menus/account_checkbox_menu.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/tabs/analyze/analyze_tab_state.dart';
import 'package:libra_sheet/tabs/analyze/analyze_tab_view_selector.dart';
import 'package:libra_sheet/tabs/analyze/analyze_tab_view_state.dart';
import 'package:libra_sheet/tabs/analyze/double_sided_graph.dart';
import 'package:libra_sheet/tabs/analyze/net_income_graph.dart';
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
        (graph, headerElements) = doubleSidedGraph(context, state, theme);
      case AnalyzeTabView.netIncome:
        (graph, headerElements) = netIncomeGraph(state, theme);
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
