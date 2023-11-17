import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/heat_map.dart';
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
                Expanded(child: HeatMap()),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          SizedBox(width: 10),
          CategoryTabFilters(),
          SizedBox(width: 10),
        ],
      ),
    );
  }
}
