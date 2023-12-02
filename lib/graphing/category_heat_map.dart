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
///
/// P.S. remember this is used to paint level = 1 nested heatmaps too...which doesn't need
/// aggregateValues.
///
/// TODO maybe also better to switch to accepting a single parent instead of [categories].
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
    int getValue(Category cat, int depth) {
      int? val;
      if (depth == 0) {
        val = widget.aggregateValues[cat.key];
      } else {
        val = widget.individualValues[cat.key];
      }
      return val?.abs() ?? 0;
    }

    List<Category>? getNested(Category cat, int depth) {
      if (depth == 0 && cat.level == 1 && cat.subCats.isNotEmpty) {
        return List.of(cat.subCats) + [cat];
      } else {
        return null;
      }
    }

    String labelMapper(Category cat, int depth) {
      String name;
      if (cat.level == 0) {
        name = "Uncategorized";
      } else {
        name = cat.name;
      }
      return "$name\n${getValue(cat, depth).dollarString()}";
    }

    final painter = HeatMapPainter<Category>(
      widget.categories,
      valueMapper: (it, depth) => getValue(it, depth).asDollarDouble(),
      colorMapper: (it, depth) => it.color,
      labelMapper: labelMapper,
      nestedData: (widget.showSubCategories) ? getNested : null,
      textStyle: Theme.of(context).textTheme.labelLarge,
      paddingMapper: (depth) => (!widget.showSubCategories)
          ? (3, 3)
          : (depth == 0)
              ? (3, 3)
              : (1, 1),
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
