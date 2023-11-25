import 'package:flutter/material.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/tabs/settings/edit_categories_screen.dart';
import 'package:provider/provider.dart';

/// Base card that shows the color, name, and drag handle. This base card doesn't handle any
/// children.
class BaseCategoryCard extends StatelessWidget {
  const BaseCategoryCard({
    super.key,
    required this.cat,
    required this.index,
    this.parentColor,
    this.isLast = false,
    this.isExpanded,
    this.onExpandedChanged,
  }) : isSubCat = parentColor != null;

  static const double height = 45;
  static const double colorBoxWidth = 6;
  static const double colorBoxHeight = height - 10;
  static const double subCatIndicatorWidth = 30;
  static const double subCatOffset = 10 + subCatIndicatorWidth;

  final Category cat;
  final int index;
  final bool isLast;
  final bool isSubCat;
  final Color? parentColor;
  final bool? isExpanded; // null for no expansion
  final Function()? onExpandedChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// Divider
        if (index != 0 || isSubCat)
          Positioned(
            left: (isSubCat) ? subCatOffset : 5,
            right: 5,
            top: 0,
            height: 1,
            child: const Divider(height: 1, thickness: 1),
          ),

        /// Main row
        SizedBox(
          height: height,
          child: InkWell(
            onTap: () => context.read<EditCategoriesState>().setFocus(cat),
            splashFactory: NoSplash.splashFactory,
            child: Row(
              children: [
                const SizedBox(width: 10),

                /// Indicator and color boxes
                if (isSubCat)
                  CustomPaint(
                    painter: SubcategoryIndicator(
                      color: parentColor ?? Colors.black,
                      isLast: isLast,
                    ),
                    size: const Size(subCatIndicatorWidth, height),
                  ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: colorBoxWidth,
                      height: colorBoxHeight,
                      color: cat.color,
                    ),
                    if (isExpanded == true)
                      CustomPaint(
                        painter: SubcategoryIndicatorParent(color: cat.color ?? Colors.black),
                        size: const Size(colorBoxWidth, height),
                      ),
                  ],
                ),

                /// Rest of row
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
                if (!isSubCat) ...[
                  const SizedBox(width: 10),
                  IconButton(
                      onPressed: () => context.read<EditCategoriesState>().setFocus(
                            Category(
                              level: 2,
                              name: '',
                              color: Colors.lightBlue,
                              parent: cat,
                            ),
                          ),
                      icon: const Icon(Icons.add)),
                ],
                const SizedBox(width: 10),
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CategoryCard extends StatefulWidget {
  const CategoryCard({
    super.key,
    required this.cat,
    required this.index,
  });

  final Category cat;
  final int index;

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BaseCategoryCard(
          cat: widget.cat,
          index: widget.index,
          isExpanded: (widget.cat.subCats.isNotEmpty) ? isExpanded : null,
          onExpandedChanged: () => setState(() {
            isExpanded = !isExpanded;
          }),
        ),
        if (widget.cat.subCats.isNotEmpty && isExpanded)
          SizedBox(
            height: BaseCategoryCard.height * widget.cat.subCats.length,
            child: ReorderableListView(
              buildDefaultDragHandles: false,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) =>
                  context.read<LibraAppState>().categories.reorder(widget.cat, oldIndex, newIndex),
              children: [
                for (int i = 0; i < widget.cat.subCats.length; i++)
                  BaseCategoryCard(
                    key: ObjectKey(widget.cat.subCats[i]),
                    cat: widget.cat.subCats[i],
                    index: i,
                    isLast: i == widget.cat.subCats.length - 1,
                    parentColor: widget.cat.color,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The "connector" line between parent and child categories, for the subcategories
class SubcategoryIndicator extends CustomPainter {
  final Color color;
  final bool isLast;

  const SubcategoryIndicator({
    required this.color,
    this.isLast = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint brush = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    if (!isLast) {
      canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        brush,
      );
      canvas.drawLine(
        Offset(size.width / 2, size.height / 2),
        Offset(size.width, size.height / 2),
        brush,
      );
    } else {
      final path = Path()
        ..moveTo(size.width / 2, 0)
        ..lineTo(size.width / 2, size.height / 2)
        ..lineTo(size.width, size.height / 2);
      canvas.drawPath(path, brush);
    }
  }

  @override
  bool shouldRepaint(covariant SubcategoryIndicator oldDelegate) {
    return color != oldDelegate.color || isLast != oldDelegate.isLast;
  }
}

/// The "connector" line between parent and child categories, for the parent
class SubcategoryIndicatorParent extends CustomPainter {
  final Color color;

  const SubcategoryIndicatorParent({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint brush = Paint()
      ..color = color
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(size.width / 2, size.height / 2),
      Offset(size.width / 2, size.height),
      brush,
    );
  }

  @override
  bool shouldRepaint(covariant SubcategoryIndicatorParent oldDelegate) {
    return color != oldDelegate.color;
  }
}
