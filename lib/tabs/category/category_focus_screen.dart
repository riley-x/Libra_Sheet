import 'package:flutter/material.dart';
import 'package:libra_sheet/components/common_back_bar.dart';
import 'package:libra_sheet/components/transaction_filter_grid.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/libra_app_state.dart';
import 'package:libra_sheet/graphing/category_heat_map.dart';
import 'package:libra_sheet/graphing/line.dart';
import 'package:libra_sheet/tabs/category/category_tab_state.dart';
import 'package:libra_sheet/tabs/home/chart_with_title.dart';
import 'package:provider/provider.dart';

class CategoryFocusScreen extends StatelessWidget {
  const CategoryFocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryOrNull = context.watch<CategoryTabState>().categoriesFocused.lastOrNull;
    if (categoryOrNull == null) return Placeholder();
    final category = categoryOrNull!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        CommonBackBar(
          leftText: category.name,
          rightText: category.value.dollarString(),
          onBack: () {
            context.read<CategoryTabState>().clearFocus();
          },
        ),
        const SizedBox(height: 5),
        Container(
          height: 2,
          color: Theme.of(context).colorScheme.outline,
        ),
        Expanded(child: _Body(category: category)),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    super.key,
    required this.category,
  });

  final CategoryValue category;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(),
            child: TransactionFilterGrid(
              context.watch<CategoryTabState>().categoryFocusedTransactions,
              fixedColumns: 1,
              maxRowsForName: 3,
              onSelect: context.read<LibraAppState>().focusTransaction,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Container(
          width: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        Expanded(
          child: Column(
            children: [
              /// this empircally matches the extra height caused by the icon button in the transaction filter grid
              const SizedBox(height: 7),
              Expanded(
                child: ChartWithTitle(
                  textLeft: 'Category History',
                  textStyle: Theme.of(context).textTheme.headlineSmall,
                  child: TestGraph(),
                ),
              ),
              if (category.hasSubCats()) ...[
                const SizedBox(height: 5),
                Container(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CategoryHeatMap(
                      category.subCats!,
                      onSelect: (it) {
                        context.read<CategoryTabState>().focusCategory(it);
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
