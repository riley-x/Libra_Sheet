import 'package:flutter/material.dart';
import 'package:libra_sheet/components/menus/category_menu_builder.dart';
import 'package:libra_sheet/components/menus/libra_dropdown_menu.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:provider/provider.dart';

/// Dropdown selector for choosing a single category.
///
/// You can supply a list of [categories] to show in the dropdown menu, or choose all categories
/// of a specific type using [type]. Specify only one of [categories] or [type].
class CategorySelectionMenu extends StatelessWidget {
  final List<Category>? categories;
  final ExpenseFilterType type;
  final Category? selected;
  final Function(Category?)? onChanged;
  final BorderRadius? borderRadius;
  final double height;
  final bool superAsNone;

  /// When using [type], show the super category [Category.income] or [Category.expense].
  final bool showUncategorized;

  const CategorySelectionMenu({
    super.key,
    this.categories,
    this.selected,
    this.onChanged,
    this.borderRadius,
    this.height = 30,
    this.type = ExpenseFilterType.all,
    this.superAsNone = false,
    this.showUncategorized = true,
  });

  @override
  Widget build(BuildContext context) {
    var cats = categories;
    if (cats == null) {
      final appState = context.watch<LibraAppState>();
      _items(appState, type, showUncategorized);
    }
    return LibraDropdownMenu<Category?>(
      selected: selected,
      items: cats!,
      builder: (cat) => categoryMenuBuilder(context, cat, superAsNone: superAsNone),
      selectedBuilder: (context, cat) =>
          categoryMenuBuilder(context, cat, superAsNone: superAsNone, selected: true),
      onChanged: onChanged,
      borderRadius: borderRadius,
      height: height,
    );
  }
}

/// Same as [CategorySelectionMenu], but wrapped in a FormField
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
    this.showUncategorized = true,
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
  final bool showUncategorized;
  final bool superAsNone;

  @override
  Widget build(BuildContext context) {
    var cats = categories;
    if (cats == null) {
      final appState = context.watch<LibraAppState>();
      cats = _items(appState, type, showUncategorized);
    }
    return LibraDropdownFormField<Category?>(
      initial: initial,
      items: cats,
      builder: (cat) => categoryMenuBuilder(context, cat, superAsNone: superAsNone),
      selectedBuilder: (context, cat) =>
          categoryMenuBuilder(context, cat, superAsNone: superAsNone, selected: true),
      borderRadius: borderRadius,
      height: height,
      onSave: onSave,
      validator: validator,
    );
  }
}

List<Category> _items(
  LibraAppState state,
  ExpenseFilterType type, [
  bool showUncategorized = true,
]) {
  List<Category> items = state.categories.flattenedCategories(type);
  if (showUncategorized) {
    switch (type) {
      case ExpenseFilterType.income:
        items.insert(0, Category.income);
      case ExpenseFilterType.expense:
        items.insert(0, Category.expense);
      case ExpenseFilterType.all:
        items.insertAll(0, [Category.income, Category.expense]);
    }
  }
  items.insert(0, Category.ignore);
  return items;
}
