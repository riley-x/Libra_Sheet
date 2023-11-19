import 'package:flutter/material.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/graphing/heat_map_painter.dart';

class CategoryHeatMap extends StatefulWidget {
  final Function(CategoryValue)? onSelect;
  final bool showSubCategories;
  final List<CategoryValue> categories;

  const CategoryHeatMap(
    this.categories, {
    super.key,
    this.onSelect,
    this.showSubCategories = false,
  });

  @override
  State<CategoryHeatMap> createState() => _CategoryHeatMapState();
}

class _CategoryHeatMapState extends State<CategoryHeatMap> {
  void _onTapUp(HeatMapPainter<CategoryValue> painter, TapUpDetails details) {
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
    final painter = HeatMapPainter<CategoryValue>(
      widget.categories,
      valueMapper: (it) => it.value.asDollarDouble(),
      colorMapper: (it) => it.color,
      labelMapper: (it) => "${it.name}\n${it.value.dollarString()}",
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

final testCategoryValues = [
  CategoryValue(name: 'cat 1', color: Colors.amber, value: 357000),
  CategoryValue(name: 'cat 2', color: Colors.blue, value: 23000),
  CategoryValue(name: 'cat 3', color: Colors.green, value: 1000000, subCats: [
    CategoryValue(name: 'subcat 1', color: Colors.grey, value: 200000),
    CategoryValue(name: 'subcat 2', color: Colors.greenAccent, value: 200000),
    CategoryValue(name: 'subcat 3', color: Colors.lightGreen, value: 200000),
    CategoryValue(name: 'subcat 4', color: Colors.lightGreenAccent, value: 200000),
    CategoryValue(name: 'subcat 5', color: Colors.green, value: 200000),
  ]),
  CategoryValue(name: 'cat 4', color: Colors.red, value: 223000),
  CategoryValue(name: 'cat 5', color: Colors.purple, value: 43000),
];
