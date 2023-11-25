import 'package:flutter/material.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/graphing/heat_map_painter.dart';

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
      valueMapper: (it) => widget.values[it.key]?.asDollarDouble() ?? 0,
      colorMapper: (it) => it.color,
      labelMapper: (it) => "${it.name}\n${(widget.values[it.key] ?? 0).dollarString()}",
      nestedData: (widget.showSubCategories) ? (it) => it.subCats : null,
      textStyle: Theme.of(context).textTheme.labelLarge,
      paddingMapper: (depth) => (widget.showSubCategories && depth == 0) ? (10, 10) : (2, 2),
    );
    return GestureDetector(
      onTapUp: (it) => _onTapUp(painter, it),
      child: CustomPaint(
        painter: painter,
        // foregroundPainter: ,
        size: Size.infinite,
      ),
    );
  }
}
