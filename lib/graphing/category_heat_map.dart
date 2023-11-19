import 'package:flutter/material.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/graphing/heat_map_painter.dart';

class CategoryHeatMap extends StatefulWidget {
  final Function(Category)? onSelect;
  // final List<CategoryValue> categories;

  const CategoryHeatMap({
    super.key,
    // required this.categories,
    this.onSelect,
  });

  @override
  State<CategoryHeatMap> createState() => _CategoryHeatMapState();
}

class _CategoryHeatMapState extends State<CategoryHeatMap> {
  void _onTapUp(HeatMapPainter<MapEntry<Category, int>> painter, TapUpDetails details) {
    if (widget.onSelect == null) return;
    for (int i = 0; i < painter.positions.length; i++) {
      if (painter.positions[i].contains(details.localPosition)) {
        if (i >= painter.data.length) return; // shouldn't happen
        widget.onSelect!(painter.data[i].key);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final painter = HeatMapPainter<MapEntry<Category, int>>(
      testCategoryValues.entries.toList(),
      valueMapper: (it) => it.value.asDollarDouble(),
      colorMapper: (it) => it.key.color,
      labelMapper: (it) => "${it.key.name}\n${it.value.dollarString()}",
      textStyle: Theme.of(context).textTheme.labelLarge,
      paddingMapper: (depth) => (depth == 0) ? (10, 10) : (2, 2),
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

final testCategoryValues = {
  Category(name: 'cat 1', color: Colors.amber): 357000,
  Category(name: 'cat 2', color: Colors.blue): 23000,
  Category(name: 'cat 3', color: Colors.green): 1012200,
  Category(name: 'cat 4', color: Colors.red): 223000,
  Category(name: 'cat 5', color: Colors.purple): 43000,
};
