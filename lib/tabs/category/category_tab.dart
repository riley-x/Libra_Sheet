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
          Expanded(
            child: Column(
              children: [
                const SizedBox(height: 10),
                Expanded(
                  child: CategoryHeatMap(
                    onSelect: (it) => print(it.name),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          SizedBox(width: 20),
          Container(
            width: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          SizedBox(width: 20),
          CategoryTabFilters(),
          SizedBox(width: 20),
        ],
      ),
    );
  }
}
