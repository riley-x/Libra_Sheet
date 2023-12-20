import 'dart:math';

import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/cartesian_coordinate_space.dart';

class BoundingBox {
  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;

  const BoundingBox({
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
  });

  BoundingBox.fromPoint(Offset point)
      : xMin = point.dx,
        xMax = point.dx,
        yMin = point.dy,
        yMax = point.dy;
}

/// An abstract class representing information for a data series in a graph.
abstract class Series<T> {
  final String name;
  final List<T> data;

  const Series({
    required this.name,
    required this.data,
  });

  void paint(Canvas canvas, CartesianCoordinateSpace coordSpace);

  /// This returns the bounding rectangle of all drawing objects associated with data[i] = x.
  /// The returned BoundingBox is in user coordinates.
  BoundingBox boundingBox(int i);

  /// This returns the bounding rectangle of all drawing objects associated with this series.
  /// The returned BoundingBox is in user coordinates.
  BoundingBox totalBoundingBox() {
    if (data.isEmpty) {
      return const BoundingBox(xMin: 0, xMax: 1, yMin: 0, yMax: 1);
    }

    var xMin = double.infinity;
    var yMin = double.infinity;
    var xMax = double.negativeInfinity;
    var yMax = double.negativeInfinity;
    for (int i = 0; i < data.length; i++) {
      final ext = boundingBox(i);
      xMin = min(xMin, ext.xMin);
      xMax = max(xMax, ext.xMax);
      yMin = min(yMin, ext.yMin);
      yMax = max(yMax, ext.yMax);
    }
    return BoundingBox(xMin: xMin, xMax: xMax, yMin: yMin, yMax: yMax);
  }
}

final testSeries = LineSeries(
  name: 'test',
  data: [10000.0, 20000.0, 15000.0, -8000.0, -9000.0, 7000.0],
  valueMapper: (i, it) => Offset(i.toDouble(), it),
);

extension SeriesExtension<T> on List<Series<T>> {
  bool hasData() {
    for (final series in this) {
      if (series.data.isNotEmpty) return true;
    }
    return false;
  }
}

class LineSeriesPoint<T> {
  final int index;
  final T item;
  final Offset value;
  final Offset pixelPos;

  LineSeriesPoint({
    required this.index,
    required this.item,
    required this.value,
    required this.pixelPos,
  });
}

class LineSeries<T> extends Series<T> {
  final Color color;
  final Offset Function(int i, T item) valueMapper;
  final Paint _painter;

  /// Cache the points to enable easy hit testing
  final List<LineSeriesPoint<T>> _renderedPoints = [];

  LineSeries({
    required super.name,
    required super.data,
    required this.valueMapper,
    this.color = Colors.blue,
  }) : _painter = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

  LineSeriesPoint<T> _addPoint(CartesianCoordinateSpace coordSpace, int i) {
    final item = data[i];
    final value = valueMapper(i, item);
    final pixelPos = coordSpace.userToPixel(value);
    final out = LineSeriesPoint(index: i, item: item, value: value, pixelPos: pixelPos);
    _renderedPoints.add(out);
    return out;
  }

  @override
  void paint(Canvas canvas, CartesianCoordinateSpace coordSpace) {
    _renderedPoints.clear();
    if (data.length <= 1) return;

    final path = Path();
    final start = _addPoint(coordSpace, 0);
    path.moveTo(start.pixelPos.dx, start.pixelPos.dy);
    for (int i = 1; i < data.length; i++) {
      final curr = _addPoint(coordSpace, i);
      path.lineTo(curr.pixelPos.dx, curr.pixelPos.dy);
    }

    canvas.drawPath(path, _painter);
  }

  @override
  BoundingBox boundingBox(int i) {
    return BoundingBox.fromPoint(valueMapper(i, data[i]));
  }
}
