import 'package:flutter/material.dart';
import 'package:libra_sheet/components/menus/category_menu_builder.dart';
import 'package:libra_sheet/components/menus/dropdown_selector.dart';
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
    return DropdownSelector<Category?>(
      selected: selected,
      items: categories,
      builder: (context, cat) => categoryMenuBuilder(context, cat, superAsNone: superAsNone),
      selectedBuilder: (context, cat) =>
          categoryMenuBuilder(context, cat, superAsNone: superAsNone, selected: true),
      onSelected: onChanged,
      borderRadius: borderRadius,
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
    this.height = 35,
    this.onSave,
    this.validator,
    this.superAsNone = false,
    this.nullText,
  });

  final List<Category?> categories;
  final Category? initial;
  final Function(Category?)? onSave;
  final String? Function(Category?)? validator;
  final BorderRadius? borderRadius;
  final double? height;
  final bool superAsNone;
  final String? nullText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LibraDropdownFormField<Category?>(
        initial: initial,
        items: categories,
        builder: (context, cat) =>
            categoryMenuBuilder(context, cat, superAsNone: superAsNone, nullText: nullText),
        selectedBuilder: (context, cat) => categoryMenuBuilder(
          context,
          cat,
          superAsNone: superAsNone,
          selected: true,
          nullText: nullText,
        ),
        borderRadius: borderRadius,
        onSave: onSave,
        validator: validator,
      ),
    );
  }
}

/// Shows subcategories in a nested menu
class CategorySelectionFormFieldV2 extends StatelessWidget {
  const CategorySelectionFormFieldV2({
    super.key,
    required this.categories,
    this.initial,
    this.borderRadius,
    this.height = 35,
    this.onSave,
    this.validator,
    this.superAsNone = false,
    this.nullText,
  });

  final List<Category?> categories;
  final Category? initial;
  final Function(Category?)? onSave;
  final String? Function(Category?)? validator;
  final BorderRadius? borderRadius;
  final double? height;
  final bool superAsNone;
  final String? nullText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LibraDropdownFormField<Category?>(
        initial: initial,
        items: categories,
        builder: (context, cat) => categoryMenuBuilder(
          context,
          cat,
          indentSubcats: false,
          superAsNone: superAsNone,
          nullText: nullText,
        ),
        selectedBuilder: (context, cat) => categoryMenuBuilder(
          context,
          cat,
          superAsNone: superAsNone,
          selected: true,
          nullText: nullText,
        ),
        borderRadius: borderRadius,
        onSave: onSave,
        validator: validator,
        subItems: (item) {
          if (item != null && item.subCats.isNotEmpty) {
            return item.subCats;
          }
          return null;
        },
      ),
    );
  }
}

/// Doesn't wrap with FormField which is annoying and hard to see state
class CategorySelectionDropDownV2 extends StatelessWidget {
  const CategorySelectionDropDownV2({
    super.key,
    required this.categories,
    this.selected,
    this.onSelected,
    this.borderRadius,
    this.height,
    this.superAsNone = false,
    this.nullText,
    this.hasError = false,
  });

  final List<Category?> categories;
  final Category? selected;
  final Function(Category?)? onSelected;
  final BorderRadius? borderRadius;
  final double? height;
  final bool superAsNone;
  final String? nullText;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: BorderedDropdownSelector<Category?>(
        selected: selected,
        onSelected: onSelected,
        items: categories,
        subItems: (item) {
          if (item != null && item.subCats.isNotEmpty) {
            return item.subCats;
          }
          return null;
        },
        borderRadius: borderRadius,
        hasError: hasError,
        builder: (context, cat) => categoryMenuBuilder(
          context,
          cat,
          indentSubcats: false,
          superAsNone: superAsNone,
          nullText: nullText,
        ),
        selectedBuilder: (context, cat) => categoryMenuBuilder(
          context,
          cat,
          superAsNone: superAsNone,
          selected: true,
          nullText: nullText,
        ),
      ),
    );
  }
}
