import 'dart:math';

import 'package:flutter/material.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/graphing/category_stack_chart.dart';
import 'package:libra_sheet/tabs/cashFlow/cash_flow_state.dart';
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

class _CashFlowTab extends StatefulWidget {
  const _CashFlowTab({super.key});

  @override
  State<_CashFlowTab> createState() => _CashFlowTabState();
}

enum _TimeFrame { oneYear, lastYear, all }

class _CashFlowTabState extends State<_CashFlowTab> {
  _TimeFrame timeFrame = _TimeFrame.all;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CashFlowState>();
    final nDates = context.watch<LibraAppState>().monthList.length;
    final range = switch (timeFrame) {
      _TimeFrame.oneYear => (max(0, nDates - 12), nDates),
      _TimeFrame.lastYear => (max(0, nDates - 24), (max(0, nDates - 12))),
      _TimeFrame.all => (0, nDates),
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
        SegmentedButton<_TimeFrame>(
          showSelectedIcon: false,
          segments: const <ButtonSegment<_TimeFrame>>[
            ButtonSegment<_TimeFrame>(
              value: _TimeFrame.oneYear,
              label: Text('One year'),
            ),
            ButtonSegment<_TimeFrame>(
              value: _TimeFrame.lastYear,
              label: Text('Previous year'),
            ),
            ButtonSegment<_TimeFrame>(
              value: _TimeFrame.all,
              label: Text('All'),
            ),
          ],
          selected: <_TimeFrame>{timeFrame},
          onSelectionChanged: (Set<_TimeFrame> newSelection) {
            setState(() {
              // By default there is only a single segment that can be
              // selected at one time, so its value is always the first
              // item in the selected set.
              timeFrame = newSelection.first;
            });
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class ChartData {
  final String x;
  final double y1;
  final double y2;
  final double y3;
  final double y4;

  const ChartData(this.x, this.y1, this.y2, this.y3, this.y4);
}
