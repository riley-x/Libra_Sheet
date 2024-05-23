import 'package:flutter/material.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filter_state.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filters.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/date_time_utils.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/graphing/wrapper/category_stack_chart.dart';
import 'package:libra_sheet/graphing/wrapper/red_green_bar_chart.dart';
import 'package:libra_sheet/tabs/cashFlow/cash_flow_state.dart';
import 'package:libra_sheet/tabs/cashFlow/cash_flow_tab_filters.dart';
import 'package:libra_sheet/tabs/navigation/libra_nav.dart';
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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CashFlowState>();
    final range = state.timeFrame.getRange(state.incomeData.times);
    final textStyle = Theme.of(context).textTheme.headlineMedium;

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

    if (state.type == CashFlowType.categories) {
      return Column(
        children: [
          Text("Income", style: textStyle),
          Expanded(
            child: CategoryStackChart(
              data: state.showSubCategories ? state.incomeDataSubCats : state.incomeData,
              range: range,
              onTap: (category, month) => onTap(category, month),
              averageColor: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          Text("Expenses", style: textStyle),
          Expanded(
            child: CategoryStackChart(
              data: state.showSubCategories ? state.expenseDataSubCats : state.expenseData,
              range: range,
              onTap: (category, month) => onTap(category, month),
              averageColor: Colors.red.shade700,
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Text("Net Income", style: textStyle),
          Expanded(
            child: RedGreenBarChart(
              state.netIncome.sublist(range.$1, range.$2),
              onSelect: (_, point) {
                // Navigate to transaction tab and show transactions from this month.
                // Top-level filter state is the one used by the transaction tab.
                final filterState = context.read<TransactionFilterState>();
                filterState.setFilters(TransactionFilters(
                  startTime: point.time,
                  endTime: point.time.monthEnd(),
                  accounts: Set.from(state.accounts),
                ));
                context.read<LibraAppState>().setTab(LibraNavDestination.transactions.index);
              },
            ),
          ),
          const SizedBox(height: 16),
          Text("Other", style: textStyle),
          Expanded(
            child: RedGreenBarChart(
              state.netReturns.sublist(range.$1, range.$2),
              onSelect: (_, point) => onTap(Category.other, point.time),
            ),
          ),
        ],
      );
    }
  }
}
