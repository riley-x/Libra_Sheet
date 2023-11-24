import 'package:flutter/material.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/libra_app_state.dart';
import 'package:libra_sheet/tabs/settings/category_card.dart';
import 'package:provider/provider.dart';

/// Settings screen for editing categories
class EditCategoriesScreen extends StatelessWidget {
  const EditCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        children: [
          _CategorySection(false),
          SizedBox(height: 30),
          _CategorySection(true),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection(this.isExpense, {super.key});

  final bool isExpense;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<LibraAppState>();
    final categories = (isExpense) ? appState.expenseCategories : appState.incomeCategories;

    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 15),
            Text(
              (isExpense) ? 'Expense' : 'Income',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Spacer(),
            IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
          ],
        ),
        if (categories.isNotEmpty)
          SizedBox(
            height: BaseCategoryCard.height * categories.countFlattened(),
            child: ReorderableListView(
              buildDefaultDragHandles: false,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (o, n) => appState.reorderCategories(isExpense, o, n),
              children: <Widget>[
                for (int i = 0; i < categories.length; i++)
                  CategoryCard(
                    cat: categories[i],
                    index: i,
                    key: ObjectKey(categories[i]),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
