import 'package:flutter/material.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/int_dollar.dart';

class HeatMapPainter<T> extends CustomPainter {
  final List<T> data;
  final Color Function(T)? colorMapper;
  final double Function(T) valueMapper;
  final String Function(T)? labelMapper;

  HeatMapPainter(
    this.data, {
    this.colorMapper,
    required this.valueMapper,
    this.labelMapper,
    bool doSort = true,
  }) {
    /// Sort largest to smallest
    if (doSort) {
      this.data.sort((a, b) {
        final diff = valueMapper(b) - valueMapper(a);
        if (diff < 0) {
          return -1;
        } else if (diff == 0) {
          return 0;
        } else {
          return 1;
        }
      });
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < data.length; i++) {
      paint.color = colorMapper?.call(data[i]) ?? Colors.teal;
      canvas.drawRect(
          Rect.fromLTWH(10, 30.0 * i, valueMapper(data[i]), 30), paint);
    }
    // Offset endingPoint = Offset(size.width, size.height / 2);
  }

  @override
  bool shouldRepaint(HeatMapPainter<T> oldDelegate) {
    return data != oldDelegate.data ||
        colorMapper != oldDelegate.colorMapper ||
        valueMapper != oldDelegate.valueMapper ||
        labelMapper != oldDelegate.labelMapper;
  }
}

class HeatMap extends StatefulWidget {
  const HeatMap({super.key});

  @override
  State<HeatMap> createState() => _HeatMapState();
}

class _HeatMapState extends State<HeatMap> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: HeatMapPainter<MapEntry<Category, int>>(
        testCategoryValues.entries.toList(),
        valueMapper: (it) => it.value.asDollarDouble(),
      ),
      size: Size.infinite,
    );
  }
}

final testCategoryValues = {
  Category(name: 'cat 1'): 357000,
  Category(name: 'cat 2'): 23000,
  Category(name: 'cat 3'): 1012200,
};
