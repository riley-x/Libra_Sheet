import 'package:flutter/material.dart';
import 'package:libra_sheet/components/transaction_filter_grid.dart';
import 'package:libra_sheet/data/int_dollar.dart';
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
        Row(
          children: [
            IconButton(
              onPressed: () {
                context.read<CategoryTabState>().clearFocus();
              },
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              category.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Spacer(),
            Text(
              category.value.dollarString(),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(width: 15),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          height: 2,
          color: Theme.of(context).colorScheme.outline,
        ),
        Expanded(
          child: Row(
            children: [
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(),
                  child: TransactionFilterGrid(
                    context.watch<CategoryTabState>().categoryFocusedTransactions,
                    fixedColumns: 1,
                    maxRowsForName: 3,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                width: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              Expanded(
                child: ChartWithTitle(
                  /// this empircally matches the extra height caused by the icon button in the transaction filter grid
                  padding: const EdgeInsets.only(top: 7),
                  textLeft: 'Balance History',
                  textStyle: Theme.of(context).textTheme.headlineSmall,
                  child: TestGraph(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
