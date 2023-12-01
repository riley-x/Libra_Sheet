import 'package:flutter/material.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/graphing/heat_map_painter.dart';

/// Paints a list of [categories] as a heatmap based on their values. This is a StatefulWidget
/// that wraps [HeatMapPainter] to paint either the top-level categories or the nested categories.
/// It also handles tap detection.
///
/// [individualValues] is a map category.key: int_value for each category on its own, while
/// [aggregateValues] aggregates subcat totals into the parent level = 1 categories.
///
/// The latter is used when not [showSubCategories], while for former is needed to show the
/// "un-sub-categorized" leftovers when [showSubCategories].
class CategoryHeatMap extends StatefulWidget {
  final Function(Category)? onSelect;
  final bool showSubCategories;
  final List<Category> categories;
  final Map<int, int> aggregateValues;
  final Map<int, int> individualValues;

  const CategoryHeatMap({
    required this.categories,
    required this.aggregateValues,
    required this.individualValues,
    super.key,
    this.onSelect,
    this.showSubCategories = false,
  });

  @override
  State<CategoryHeatMap> createState() => _CategoryHeatMapState();
}

class _CategoryHeatMapState extends State<CategoryHeatMap> {
  void _onTapUp(HeatMapPainter<Category> painter, TapUpDetails details) {
    if (widget.onSelect == null) return;
    for (int i = 0; i < painter.positions.length; i++) {
      if (painter.positions[i].$1.contains(details.localPosition)) {
        widget.onSelect!(painter.positions[i].$2);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int getValue(Category cat) {
      int? val;
      if (widget.showSubCategories) {
        val = widget.individualValues[cat.key];
      } else {
        val = widget.aggregateValues[cat.key];
      }
      return val?.abs() ?? 0;
    }

    List<Category>? getNested(Category cat) {
      if (cat.level == 1 && cat.subCats.isNotEmpty) {
        return List.of(cat.subCats) + [cat];
      } else {
        return null;
      }
    }

    String labelMapper(Category cat) {
      String name;
      if (cat.level == 0 || (widget.showSubCategories && cat.level == 1)) {
        name = "Uncategorized";
      } else {
        name = cat.name;
      }
      return "$name\n${getValue(cat).dollarString()}";
    }

    final painter = HeatMapPainter<Category>(
      widget.categories,
      valueMapper: (it) => getValue(it).asDollarDouble(),
      colorMapper: (it) => it.color,
      labelMapper: labelMapper,
      nestedData: (widget.showSubCategories) ? getNested : null,
      textStyle: Theme.of(context).textTheme.labelLarge,
      paddingMapper: (depth) => (widget.showSubCategories && depth == 0) ? (5, 5) : (2, 2),
    );
    return GestureDetector(
      onTapUp: (it) => _onTapUp(painter, it),
      child: RepaintBoundary(
        child: CustomPaint(
          painter: painter,
          // foregroundPainter: ,
          size: Size.infinite,
        ),
      ),
    );
  }
}
