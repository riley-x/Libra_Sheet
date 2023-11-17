import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/category_stack_chart.dart';

class CashFlowTab extends StatefulWidget {
  const CashFlowTab({super.key});

  @override
  State<CashFlowTab> createState() => _CashFlowTabState();
}

enum _TimeFrame { oneYear, lastYear, all }

class _CashFlowTabState extends State<CashFlowTab> {
  _TimeFrame timeFrame = _TimeFrame.all;

  @override
  Widget build(BuildContext context) {
    final n = chartData1.first.values.length;
    final range = switch (timeFrame) {
      _TimeFrame.oneYear => (0, 2),
      _TimeFrame.lastYear => (0, 1),
      _TimeFrame.all => (0, n),
    };
    return Column(
      children: [
        Text(
          "Income",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Expanded(child: CategoryStackChart(chartData1, range)),
        Text(
          "Expenses",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Expanded(child: CategoryStackChart(chartData1, range)),
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
