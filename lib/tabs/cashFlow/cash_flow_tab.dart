import 'dart:math';

import 'package:flutter/material.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filter_state.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/date_time_utils.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/graphing/category_stack_chart.dart';
import 'package:libra_sheet/graphing/red_green_bar_chart.dart';
import 'package:libra_sheet/tabs/cashFlow/cash_flow_state.dart';
import 'package:libra_sheet/tabs/cashFlow/cash_flow_tab_filters.dart';
import 'package:libra_sheet/tabs/navigation/libra_navigation.dart';
import 'package:provider/provider.dart';

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

  void onTap(BuildContext context, Category category, DateTime month) {
    toCategoryScreen(
      context,
      category,
      initialFilters: TransactionFilters(
        startTime: month,
        endTime: month.monthEnd(),
        categories: CategoryTristateMap({category}),
        accounts: context.read<CashFlowState>().accounts,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CashFlowState>();
    final monthList = context.watch<LibraAppState>().monthList;
    final nDates = monthList.length;
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
              months: monthList,
              data: state.showSubCategories ? state.incomeDataSubCats : state.incomeData,
              range: range,
              onTap: (category, month) => onTap(context, category, month),
            ),
          ),
          const SizedBox(height: 10),
          Text("Expenses", style: textStyle),
          Expanded(
            child: CategoryStackChart(
              months: monthList,
              data: state.showSubCategories ? state.expenseDataSubCats : state.expenseData,
              range: range,
              onTap: (category, month) => onTap(context, category, month),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Text("Net Income", style: textStyle),
          Expanded(child: RedGreenBarChart(state.netIncome.sublist(range.$1, range.$2))),
          const SizedBox(height: 10),
          Text("Investment Returns", style: textStyle),
          Expanded(child: RedGreenBarChart(state.netReturns.sublist(range.$1, range.$2))),
        ],
      );
    }
  }
}
