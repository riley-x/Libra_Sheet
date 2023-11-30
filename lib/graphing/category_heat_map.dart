import 'package:flutter/material.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/graphing/heat_map_painter.dart';

/// Paints a list of [categories] as a heatmap based on their [values]. This is a StatefulWidget
/// that wraps [HeatMapPainter] to paint either the top-level categories or the nested categories.
/// It also handles tap detection.
class CategoryHeatMap extends StatefulWidget {
  final Function(Category)? onSelect;
  final bool showSubCategories;
  final List<Category> categories;
  final Map<int, int> values;

  const CategoryHeatMap({
    required this.categories,
    required this.values,
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
    final painter = HeatMapPainter<Category>(
      widget.categories,
      valueMapper: (it) => widget.values[it.key]?.asDollarDouble().abs() ?? 0,
      colorMapper: (it) => it.color,
      labelMapper: (it) => "${it.name}\n${(widget.values[it.key]?.abs() ?? 0).dollarString()}",
      nestedData: (widget.showSubCategories) ? (it) => it.subCats : null,
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
