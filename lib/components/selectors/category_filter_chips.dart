import 'package:flutter/material.dart';
import 'package:libra_sheet/components/libra_chip.dart';
import 'package:libra_sheet/components/selectors/dropdown_checkbox_menu.dart';
import 'package:libra_sheet/data/category.dart';

/// Lays out active category filters. Clicking the category removes it from the filter. This widget
/// has no way to add filters; use CategoryFilterMenu instead.
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
      spacing: 10,
      runSpacing: 4,
      children: [
        for (final cat in categories)
          if (map.get(cat) != false)
            LibraChip(
              cat.name,
              onTap: () {
                map.set(cat, false);
                notify?.call();
              },
            ),
      ],
    );
  }
}

Widget dropdownCategoryBuilder(BuildContext context, Category? cat) {
  return Padding(
    padding: EdgeInsets.only(left: ((cat?.level ?? 0) > 1) ? 20 : 0),
    child: Text(
      cat?.name ?? '',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelLarge,
    ),
  );
}

/// Select multiple categories in a dropdown checklist.
class DropdownCategoryMenu extends StatelessWidget {
  const DropdownCategoryMenu({
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
      items: categories,
      builder: dropdownCategoryBuilder,
      isChecked: map.get,
      isTristate: (cat) => cat.hasSubCats(),
      onChanged: (cat, selected) {
        map.set(cat, selected);
        notify?.call();
      },
    );
  }
}
