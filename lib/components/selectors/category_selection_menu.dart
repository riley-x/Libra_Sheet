import 'package:flutter/material.dart';
import 'package:libra_sheet/components/selectors/libra_dropdown_menu.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/libra_app_state.dart';
import 'package:provider/provider.dart';

List<Category?> _items(LibraAppState state, ExpenseFilterType type) {
  List<Category?> items = state.flattenedCategories(type);
  switch (type) {
    case ExpenseFilterType.income:
      items = <Category?>[ignoreCategory, incomeCategory] + items;
    case ExpenseFilterType.expense:
      items = <Category?>[ignoreCategory, expenseCategory] + items;
    case ExpenseFilterType.all:
      items = <Category?>[ignoreCategory, incomeCategory, expenseCategory] + items;
  }
  return items;
}

Widget _builder(BuildContext context, Category? cat) {
  return Text(
    cat?.name ?? '',
    style: Theme.of(context).textTheme.labelLarge,
  );
}

/// Dropdown button for choosing a single category
class CategorySelectionMenu extends StatelessWidget {
  final ExpenseFilterType type;
  final Category? selected;
  final Function(Category?)? onChanged;
  final BorderRadius? borderRadius;
  final double height;
  const CategorySelectionMenu({
    super.key,
    this.selected,
    this.onChanged,
    this.borderRadius,
    this.height = 30,
    this.type = ExpenseFilterType.all,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<LibraAppState>();

    return LibraDropdownMenu<Category?>(
      selected: selected,
      items: _items(appState, type),
      builder: (cat) => _builder(context, cat),
      onChanged: onChanged,
      borderRadius: borderRadius,
      height: height,
    );
  }
}

/// As above, but wrapped in a FormField
class CategorySelectionFormField extends StatelessWidget {
  const CategorySelectionFormField({
    super.key,
    this.initial,
    this.includeNone = false,
    this.borderRadius,
    this.height = 30,
    this.type = ExpenseFilterType.all,
    this.onSave,
  });

  final ExpenseFilterType type;
  final Category? initial;
  final bool includeNone;
  final Function(Category?)? onSave;
  final BorderRadius? borderRadius;
  final double height;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<LibraAppState>();
    return LibraDropdownFormField<Category?>(
      initial: initial,
      items: _items(appState, type),
      builder: (cat) => _builder(context, cat),
      borderRadius: borderRadius,
      height: height,
      onSave: onSave,
    );
  }
}
