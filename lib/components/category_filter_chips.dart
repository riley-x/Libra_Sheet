import 'package:flutter/material.dart';
import 'package:libra_sheet/data/objects/category.dart';

/// Lays out a set of filter chips for each category and its sub categories. If a category has
/// sub categories, it is layed out on its own row, and its sub categories in an indented row beneath.
/// All categories without children are jointly placed into a Wrap at the top.
class CategoryFilterChips extends StatelessWidget {
  final List<Category> soloCategories = [];
  final List<Category> parentCategories = [];
  final bool Function(Category cat)? selected;
  final Function(Category cat, bool selected)? onSelected;

  CategoryFilterChips({
    super.key,
    required List<Category> categories,
    this.selected,
    this.onSelected,
  }) {
    for (final cat in categories) {
      if (cat.subCats.isNotEmpty) {
        parentCategories.add(cat);
      } else {
        soloCategories.add(cat);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.0, // gap between adjacent chips
          runSpacing: 4.0, // gap between lines
          children: <Widget>[
            for (final cat in soloCategories)
              _BaseChip(
                cat,
                selected: selected,
                onSelected: onSelected,
              ),
          ],
        ),
        for (final cat in parentCategories) ...[
          const SizedBox(height: 10),
          _BaseChip(
            cat,
            selected: selected,
            onSelected: onSelected,
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Wrap(
              spacing: 8.0, // gap between adjacent chips
              runSpacing: 4.0, // gap between lines
              children: <Widget>[
                for (final subCat in cat.subCats ?? [])
                  _BaseChip(
                    subCat,
                    selected: selected,
                    onSelected: onSelected,
                    rounded: true,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _BaseChip extends StatelessWidget {
  const _BaseChip(this.category, {super.key, this.selected, this.onSelected, this.rounded = false});

  final Category category;
  final bool rounded;
  final bool Function(Category cat)? selected;
  final Function(Category cat, bool selected)? onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(category.name),
      selected: selected?.call(category) ?? false,
      onSelected: (selected) {
        onSelected?.call(category, selected);
      },
      showCheckmark: false,
      shape: (rounded) ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)) : null,
    );
  }
}
