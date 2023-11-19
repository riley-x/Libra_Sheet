import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/category_heat_map.dart';
import 'package:libra_sheet/graphing/heat_map_painter.dart';
import 'package:libra_sheet/tabs/category/category_tab_state.dart';
import 'package:provider/provider.dart';

import 'category_tab_filters.dart';

class CategoryTab extends StatelessWidget {
  const CategoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CategoryTabState(),
      child: Row(
        children: [
          const SizedBox(width: 10),
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
      ),
    );
  }
}

class _HeatMap extends StatelessWidget {
  const _HeatMap({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CategoryTabState>();
    return CategoryHeatMap(
      onSelect: (it) => print(it.name),
      showSubCategories: state.showSubCategories,
    );
  }
}
