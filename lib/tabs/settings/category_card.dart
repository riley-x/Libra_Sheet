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
          height: 45,
          child: Row(
            children: [
              const SizedBox(width: 10),
              if (isSubCat)
                SizedBox(
                  width: subCatIndicatorWidth,
                  child: CustomPaint(
                    painter: SubcategoryIndicator(
                      color: Colors.blue,
                      isLast: isLast,
                    ),
                    size: Size.infinite,
                  ),
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
        // Padding(
        //   padding: EdgeInsets.only(left: (isShortDivider) ? subCatOffset : 0),
        //   child: (hasDivider) ? const Divider(height: 1, thickness: 1) : const SizedBox(height: 1),
        // ),
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
      ..strokeWidth = 3
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
