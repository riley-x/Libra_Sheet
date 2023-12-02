import 'package:flutter/material.dart';
import 'package:libra_sheet/components/cards/libra_chip.dart';
import 'package:libra_sheet/components/menus/category_menu_builder.dart';
import 'package:libra_sheet/components/menus/dropdown_checkbox_menu.dart';
import 'package:libra_sheet/data/objects/category.dart';

/// Select multiple categories in a dropdown checklist.
class CategoryCheckboxMenu extends StatelessWidget {
  const CategoryCheckboxMenu({
    super.key,
    required this.categories,
    required this.map,
    required this.notify,
  });

  final List<Category> categories;
  final CategoryTristateMap map;
  final Function()? notify;

  @override
  Widget build(BuildContext context) {
    return DropdownCheckboxMenu<Category>(
      icon: Icons.add,
      items: categories,
      builder: categoryMenuBuilder,
      isChecked: map.checkboxState,
      isTristate: (cat) => cat.level == 1 && cat.subCats.isNotEmpty,
      onChanged: (cat, selected) {
        map.set(cat, selected);
        notify?.call();
      },
    );
  }
}

/// Lays out active category filters. Clicking the category removes it from the filter. This widget
/// has no way to add filters; use DropdownCategoryMenu instead.
class CategoryFilterChips extends StatelessWidget {
  const CategoryFilterChips({
    super.key,
    required this.categories,
    required this.map,
    required this.notify,
  });

  final List<Category> categories;
  final CategoryTristateMap map;
  final Function()? notify;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 4,
      children: [
        for (final cat in categories)
          if (map.isActive(cat))
            LibraChip(
              cat.name,
              color: cat.color,
              onTap: () {
                map.set(cat, false);
                notify?.call();
              },
            ),
      ],
    );
  }
}
