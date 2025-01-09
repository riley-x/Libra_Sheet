import 'package:flutter/material.dart';
import 'package:libra_sheet/components/buttons/time_frame_selector.dart';
import 'package:libra_sheet/components/menus/account_checkbox_menu.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filters.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/date_time_utils.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_axes.dart';
import 'package:libra_sheet/graphing/cartesian/month_axis.dart';
import 'package:libra_sheet/graphing/cartesian/pooled_tooltip.dart';
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
        Expanded(
          child: Column(
            children: [
              SizedBox(height: 10),
              Expanded(child: _Charts()),
              SizedBox(height: 10),
            ],
          ),
        ),
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

    switch (state.viewState) {
      case DoubleStackView():
        return const _DoubleSidedChart();
      default:
        return const Placeholder();
    }
  }
}

class _DoubleSidedChart extends StatelessWidget {
  const _DoubleSidedChart({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AnalyzeTabState>();
    final range = state.timeFrame.getRange(state.incomeData.times);

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

    return CategoryStackChart(
      data: state.combinedHistory,
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
