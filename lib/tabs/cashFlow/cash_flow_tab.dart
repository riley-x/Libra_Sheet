import 'dart:math';

import 'package:flutter/material.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/graphing/category_stack_chart.dart';
import 'package:libra_sheet/tabs/cashFlow/cash_flow_state.dart';
import 'package:libra_sheet/tabs/cashFlow/cash_flow_tab_filters.dart';
import 'package:provider/provider.dart';

class CashFlowTab extends StatelessWidget {
  const CashFlowTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CashFlowState(context.read<LibraAppState>()),
      child: const _CashFlowTab(),
    );
  }
}

/// Main screen of the cash flow tab: graphs with filters column on the right.
class _CashFlowTab extends StatelessWidget {
  const _CashFlowTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Column(
            children: [
              SizedBox(height: 20),
              Expanded(child: _CashFlowCharts()),
              SizedBox(height: 10),
            ],
          ),
        ),
        VerticalDivider(width: 1, thickness: 1),
        SizedBox(width: 20),
        SizedBox(width: 250, child: CashFlowTabFilters()),
        SizedBox(width: 20),
      ],
    );
  }
}

class _CashFlowCharts extends StatelessWidget {
  const _CashFlowCharts({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CashFlowState>();
    final nDates = context.watch<LibraAppState>().monthList.length;
    final range = switch (state.timeFrame) {
      CashFlowTimeFrame.oneYear => (max(0, nDates - 12), nDates),
      CashFlowTimeFrame.lastYear => (max(0, nDates - 24), (max(0, nDates - 12))),
      CashFlowTimeFrame.all => (0, nDates),
    };
    return Column(
      children: [
        Text(
          "Income",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Expanded(child: CategoryStackChart(state.incomeData, range)),
        Text(
          "Expenses",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Expanded(child: CategoryStackChart(state.expenseData, range)),
        const SizedBox(height: 10),
      ],
    );
  }
}
