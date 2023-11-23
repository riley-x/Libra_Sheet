import 'package:flutter/material.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/libra_app_state.dart';
import 'package:provider/provider.dart';

/// Card for a category that allows editing the color, name, and level
class CategoryCard extends StatelessWidget {
  const CategoryCard(this.cat, {super.key, this.isLast = false});

  final Category cat;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(top: 12, bottom: 12, left: (cat.level == 1) ? 10 : 40),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  cat.name,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Container(
                width: 30,
                height: 20,
                color: cat.color,
              ),
              const SizedBox(width: 50),
            ],
          ),
        ),
        if (isLast) const Divider(height: 1, thickness: 1),
        if (!isLast) const SizedBox(height: 1),
      ],
    );
  }
}

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
            height: 45.0 * categories.length,
            child: ReorderableListView(
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) => {},
              children: <Widget>[
                for (int i = 0; i < categories.length; i++)
                  CategoryCard(categories[i],
                      key: ObjectKey(categories[i]), isLast: i != categories.length - 1),
              ],
            ),
          ),
      ],
    );
  }
}
