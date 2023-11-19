import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/category_heat_map.dart';
import 'package:libra_sheet/tabs/category/category_focus_screen.dart';
import 'package:libra_sheet/tabs/category/category_tab_state.dart';
import 'package:provider/provider.dart';

import 'category_tab_filters.dart';

class CategoryTab extends StatelessWidget {
  const CategoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CategoryTabState(),
      child: Consumer<CategoryTabState>(
        builder: (context, state, child) {
          if (state.categoriesFocused.isNotEmpty) {
            return const CategoryFocusScreen();
          } else {
            return const _CategoryTab();
          }
        },
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 20),
        const Expanded(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: _HeatMap(),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Container(
          width: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        const SizedBox(width: 20),
        const CategoryTabFilters(),
        const SizedBox(width: 20),
      ],
    );
  }
}

class _HeatMap extends StatelessWidget {
  const _HeatMap({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CategoryTabState>();
    return CategoryHeatMap(
      testCategoryValues,
      onSelect: (it) {
        context.read<CategoryTabState>().focusCategory(it);
      },
      showSubCategories: state.showSubCategories,
    );
  }
}
