import 'dart:math';

import 'package:flutter/material.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/graphing/cartesian_axes.dart';
import 'package:libra_sheet/graphing/category_stack_chart.dart';
import 'package:libra_sheet/graphing/discrete_cartesian_graph.dart';
import 'package:libra_sheet/graphing/red_green_bar_chart.dart';
import 'package:libra_sheet/tabs/cashFlow/cash_flow_state.dart';
import 'package:libra_sheet/tabs/cashFlow/cash_flow_tab_filters.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class CashFlowTab extends StatelessWidget {
  const CashFlowTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CashFlowTab();
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
              SizedBox(height: 10),
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

    final textStyle = Theme.of(context).textTheme.headlineMedium;
    if (state.type == CashFlowType.categories) {
      return Column(
        children: [
          Text("Income", style: textStyle),
          Expanded(
            child: CategoryStackChart(
              state.showSubCategories ? state.incomeDataSubCats : state.incomeData,
              range,
              trackballDisplayMode: state.showSubCategories
                  ? TrackballDisplayMode.nearestPoint
                  : TrackballDisplayMode.groupAllPoints,
            ),
          ),
          Text("Expenses", style: textStyle),
          Expanded(
            child: CategoryStackChart(
              state.showSubCategories ? state.expenseDataSubCats : state.expenseData,
              range,
              trackballDisplayMode: state.showSubCategories
                  ? TrackballDisplayMode.nearestPoint
                  : TrackballDisplayMode.groupAllPoints,
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Text("Net Income", style: textStyle),
          Expanded(
            child: DiscreteCartesianGraph(
              axes: CartesianAxes(
                yAxis: CartesianAxis(
                  axisLoc: null,
                  valToString: formatOrder,
                ),
                xAxis: CartesianAxis(
                    // gridLines: [],
                    ),
              ),
            ),
          ),
          // Expanded(child: RedGreenBarChart(state.netIncome.sublist(range.$1, range.$2))),
          Text("Investment Returns", style: textStyle),
          Expanded(child: RedGreenBarChart(state.netReturns.sublist(range.$1, range.$2))),
        ],
      );
    }
  }
}
