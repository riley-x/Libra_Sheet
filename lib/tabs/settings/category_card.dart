import 'package:flutter/material.dart';
import 'package:libra_sheet/data/category.dart';

/// Card for a category that shows the color, name, and drag handle. This is the base card that
/// doesn't handle the children.
class BaseCategoryCard extends StatelessWidget {
  const BaseCategoryCard({
    super.key,
    required this.cat,
    required this.index,
    this.isSubCat = false,
    this.isLast = false,
    this.child,
    this.isExpanded,
    this.onExpandedChanged,
  });

  static const double subCatIndicatorWidth = 30;
  static const double subCatOffset = 10 + subCatIndicatorWidth;

  final Category cat;
  final int index;
  final bool isLast;
  final bool isSubCat;
  final bool? isExpanded; // null for no expansion
  final Widget? child;
  final Function()? onExpandedChanged;

  @override
  Widget build(BuildContext context) {
    bool hasDivider = !isLast || child != null || isSubCat;
    bool isShortDivider = child != null || (isSubCat && !isLast);
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: Row(
            children: [
              const SizedBox(width: 10),
              if (isSubCat)
                SizedBox(
                  width: subCatIndicatorWidth,
                  child: Placeholder(),
                ),
              Container(
                width: 30,
                height: 20,
                color: cat.color,
              ),
              const SizedBox(width: 10),
              Text(
                cat.name,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              if (isExpanded != null) ...[
                const SizedBox(width: 10),
                IconButton(
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  onPressed: onExpandedChanged,
                  icon: Icon((isExpanded!) ? Icons.expand_less : Icons.expand_more),
                ),
              ],
              const Spacer(),
              const SizedBox(width: 10),
              ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: (isShortDivider) ? subCatOffset : 0),
          child: (hasDivider) ? const Divider(height: 1, thickness: 1) : const SizedBox(height: 1),
        ),
        if (child != null) child!,
      ],
    );
  }
}

class CategoryCard extends StatefulWidget {
  const CategoryCard({
    super.key,
    required this.cat,
    required this.index,
    this.isLast = false,
  });

  final Category cat;
  final int index;
  final bool isLast;

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return BaseCategoryCard(
      cat: widget.cat,
      index: widget.index,
      isLast: widget.isLast,
      isExpanded: (widget.cat.hasSubCats()) ? isExpanded : null,
      onExpandedChanged: () => setState(() {
        isExpanded = !isExpanded;
      }),
      child: (widget.cat.hasSubCats() && isExpanded)
          ? SizedBox(
              height: 45.0 * widget.cat.subCats!.length,
              child: ReorderableListView(
                buildDefaultDragHandles: false,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: (oldIndex, newIndex) => print('$oldIndex $newIndex'),
                children: [
                  for (int i = 0; i < widget.cat.subCats!.length; i++)
                    BaseCategoryCard(
                      key: ObjectKey(widget.cat.subCats![i]),
                      cat: widget.cat.subCats![i],
                      index: i,
                      isLast: i == widget.cat.subCats!.length - 1,
                      isSubCat: true,
                    ),
                ],
              ),
            )
          : null,
    );
  }
}
