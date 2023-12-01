import 'package:flutter/material.dart';
import 'package:libra_sheet/components/menus/libra_dropdown_menu.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:provider/provider.dart';

/// Dropdown selector for choosing a single category
class CategorySelectionMenu extends StatelessWidget {
  /// The list of categories to show in the dropdown menu. You can alternatively choose all categories
  /// of a specific type using [type]. Specify only one of [categories] or [type].
  final List<Category>? categories;
  final ExpenseFilterType type;
  final Category? selected;
  final Function(Category?)? onChanged;
  final BorderRadius? borderRadius;
  final double height;
  final bool superAsNone;

  const CategorySelectionMenu({
    super.key,
    this.categories,
    this.selected,
    this.onChanged,
    this.borderRadius,
    this.height = 30,
    this.type = ExpenseFilterType.all,
    this.superAsNone = false,
  });

  @override
  Widget build(BuildContext context) {
    var cats = categories;
    if (cats == null) {
      final appState = context.watch<LibraAppState>();
      _items(appState, type);
    }
    return LibraDropdownMenu<Category?>(
      selected: selected,
      items: cats!,
      builder: (cat) => _builder(context, cat, superAsNone),
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
    this.categories,
    this.initial,
    this.borderRadius,
    this.height = 30,
    this.type = ExpenseFilterType.all,
    this.onSave,
    this.validator,
    this.superAsNone = false,
  });

  /// The list of categories to show in the dropdown menu. You can alternatively choose all categories
  /// of a specific type using [type]. Specify only one of [categories] or [type].
  final List<Category?>? categories;
  final ExpenseFilterType type;
  final Category? initial;
  final Function(Category?)? onSave;
  final String? Function(Category?)? validator;
  final BorderRadius? borderRadius;
  final double height;
  final bool superAsNone;

  @override
  Widget build(BuildContext context) {
    var cats = categories;
    if (cats == null) {
      final appState = context.watch<LibraAppState>();
      cats = _items(appState, type);
    }
    return LibraDropdownFormField<Category?>(
      initial: initial,
      items: cats,
      builder: (cat) => _builder(context, cat, superAsNone),
      borderRadius: borderRadius,
      height: height,
      onSave: onSave,
      validator: validator,
    );
  }
}

List<Category?> _items(LibraAppState state, ExpenseFilterType type) {
  List<Category?> items = state.categories.flattenedCategories(type);
  switch (type) {
    case ExpenseFilterType.income:
      items = <Category?>[Category.ignore, Category.income] + items;
    case ExpenseFilterType.expense:
      items = <Category?>[Category.ignore, Category.expense] + items;
    case ExpenseFilterType.all:
      items = <Category?>[Category.ignore, Category.income, Category.expense] + items;
  }
  return items;
}

Widget _builder(BuildContext context, Category? cat, bool superAsNone) {
  if (superAsNone && cat?.level == 0) cat = null;
  return Text(
    cat?.name ?? 'None',
    style: (cat == null)
        ? Theme.of(context).textTheme.labelLarge?.copyWith(fontStyle: FontStyle.italic)
        : Theme.of(context).textTheme.labelLarge,
  );
}
