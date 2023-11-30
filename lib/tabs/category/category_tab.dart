import 'package:flutter/material.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/graphing/category_heat_map.dart';
import 'package:libra_sheet/tabs/category/category_focus_screen.dart';
import 'package:libra_sheet/tabs/category/category_tab_state.dart';
import 'package:provider/provider.dart';

import 'category_tab_filters.dart';

/// This tab shows a heat map of the category values, with a list of filters/time selections on the
/// right. Selecting a category transfers to a nested screen with transactions, a history line graph,
/// and a subcat heatmap.
class CategoryTab extends StatelessWidget {
  const CategoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CategoryTabState>();
    if (state.categoriesFocused.isNotEmpty) {
      return const CategoryFocusScreen();
    } else {
      return const _CategoryTab();
    }
  }
}

/// Main screen of the category tab: main heatmap with filters column on the right.
class _CategoryTab extends StatelessWidget {
  const _CategoryTab({super.key});

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
        ? appState.categories.expense.subCats
        : appState.categories.income.subCats;
    return CategoryHeatMap(
      categories: categories,
      values: state.values,
      onSelect: (it) => context.read<CategoryTabState>().focusCategory(it),
      showSubCategories: state.showSubCategories,
    );
  }
}
