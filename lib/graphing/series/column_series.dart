import 'dart:math';

import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_coordinate_space.dart';
import 'package:libra_sheet/graphing/series/series.dart';

class ColumnSeriesPoint<T> {
  final int index;
  final T item;
  final double value;
  final Color color;
  final BoundingBox pixelPos;

  ColumnSeriesPoint({
    required this.index,
    required this.item,
    required this.value,
    required this.color,
    required this.pixelPos,
  });
}

/// A column series maps
class ColumnSeries<T> extends Series<T> {
  Color? color;
  final double Function(int i, T item) valueMapper;
  final Color? Function(int i, T item)? colorMapper;

  /// A value betwen [-0.5, 0.5] on where to center each bar. 0 indicates the center of the bin
  /// while 0.5 indicates the midpoint between the next bin.
  double? offset;
  static const _defaultOffset = 0.0;

  /// A value between [0, 1] for the width of the bar. 1 indicates taking the full bin width (no
  /// padding between bars). Generally offset +- width should be in [-0.5, 0.5].
  double? width;
  static const _defaultWidth = 0.6;

  /// Cache the points to enable easy hit testing
  final List<ColumnSeriesPoint<T>> _renderedPoints = [];

  ColumnSeries({
    required super.name,
    required super.data,
    required this.valueMapper,
    this.offset = 0,
    this.color,
    this.colorMapper,
  });

  ColumnSeriesPoint<T> _addPoint(CartesianCoordinateSpace coordSpace, int i) {
    final out = ColumnSeriesPoint(
      index: i,
      item: data[i],
      value: valueMapper(i, data[i]),
      color: colorMapper?.call(i, data[i]) ?? this.color ?? Colors.blue,
      pixelPos: boundingBox(i),
    );
    _renderedPoints.add(out);
    return out;
  }

  @override
  void paint(Canvas canvas, CartesianCoordinateSpace coordSpace) {
    _renderedPoints.clear();
    for (int i = 0; i < data.length; i++) {
      final point = _addPoint(coordSpace, i);
      final painter = Paint()
        ..color = point.color
        ..style = PaintingStyle.fill;
      canvas.drawRect(coordSpace.userToPixelRect(point.pixelPos), painter);
    }
  }

  @override
  BoundingBox boundingBox(int i) {
    final y = valueMapper(i, data[i]);
    final x = i.toDouble() + (offset ?? _defaultOffset);
    final width = this.width ?? _defaultWidth;
    return BoundingBox(xMin: x - width / 2, xMax: x + width / 2, yMin: min(0, y), yMax: max(0, y));
  }
}

final testColumnSeries = ColumnSeries(
  name: 'test',
  data: [10000.0, 20000.0, 15000.0, -8000.0, -9000.0, 7000.0],
  valueMapper: (i, it) => it,
);
