import 'package:flutter/material.dart';
import 'package:libra_sheet/components/buttons/time_frame_selector.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filters.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/date_time_utils.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/graphing/wrapper/category_heat_map.dart';
import 'package:libra_sheet/tabs/category/category_tab_state.dart';
import 'package:libra_sheet/tabs/navigation/libra_navigation.dart';
import 'package:provider/provider.dart';

import 'category_tab_filters.dart';

/// This tab shows a heat map of the category values, with a list of filters/time selections on the
/// right.
class CategoryTab extends StatelessWidget {
  const CategoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(width: 20),
        Expanded(
          child: Column(
            children: [
              SizedBox(height: 20),
              Expanded(child: _HeatMap()),
              SizedBox(height: 10),
            ],
          ),
        ),
        SizedBox(width: 20),
        VerticalDivider(width: 1, thickness: 1),
        SizedBox(width: 20),
        SizedBox(width: 250, child: CategoryTabFilters()),
        SizedBox(width: 20),
      ],
    );
  }
}

class _HeatMap extends StatelessWidget {
  const _HeatMap({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<LibraAppState>();
    final state = context.watch<CategoryTabState>();
    final categories = (state.expenseType == ExpenseType.expense)
        ? [appState.categories.expense, ...appState.categories.expense.subCats]
        : [appState.categories.income, ...appState.categories.income.subCats];

    return CategoryHeatMap(
      categories: categories,
      individualValues: state.individualValues,
      aggregateValues: state.aggregateValues,
      onSelect: (it) => toCategoryScreen(
        context,
        it,
        initialFilters: TransactionFilters(
          categories: CategoryTristateMap([it]),
          startTime:
              state.timeFrame.selection == TimeFrameEnum.all ? null : state.timeFrameMonths?.$1,
          endTime: state.timeFrame.selection != TimeFrameEnum.custom
              ? null
              : state.timeFrameMonths?.$2.monthEnd(),
          accounts: state.accounts,
        ),
      ),
      showSubCategories: state.showSubCategories,
      averageDenominator: state.showAverages && state.timeFrameMonths != null
          ? 1 + state.timeFrameMonths!.$2.monthDiff(state.timeFrameMonths!.$1)
          : null,
    );
  }
}
