import 'package:flutter/material.dart';
import 'package:libra_sheet/components/menus/category_menu_builder.dart';
import 'package:libra_sheet/components/menus/libra_dropdown_menu.dart';
import 'package:libra_sheet/data/objects/category.dart';

/// Dropdown selector for choosing a single category.
class CategorySelectionMenu extends StatelessWidget {
  final List<Category> categories;
  final Category? selected;
  final Function(Category?)? onChanged;
  final BorderRadius? borderRadius;
  final double height;
  final bool superAsNone;

  const CategorySelectionMenu({
    super.key,
    required this.categories,
    this.selected,
    this.onChanged,
    this.borderRadius,
    this.height = 30,
    this.superAsNone = false,
  });

  @override
  Widget build(BuildContext context) {
    return LibraDropdownMenu<Category?>(
      selected: selected,
      items: categories,
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
    required this.categories,
    this.initial,
    this.borderRadius,
    this.height = 30,
    this.onSave,
    this.validator,
    this.superAsNone = false,
  });

  final List<Category> categories;
  final Category? initial;
  final Function(Category?)? onSave;
  final String? Function(Category?)? validator;
  final BorderRadius? borderRadius;
  final double height;
  final bool superAsNone;

  @override
  Widget build(BuildContext context) {
    return LibraDropdownFormField<Category?>(
      initial: initial,
      items: categories,
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
