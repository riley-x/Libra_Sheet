import 'dart:math';

import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_coordinate_space.dart';
import 'package:libra_sheet/graphing/cartesian/discrete_cartesian_graph.dart';
import 'package:libra_sheet/graphing/series/series.dart';

class ColumnSeriesPoint<T> {
  final int index;
  final T item;
  final double value;
  final Color color;
  final Rect pixelPos;

  ColumnSeriesPoint({
    required this.index,
    required this.item,
    required this.value,
    required this.color,
    required this.pixelPos,
  });
}

/// A column series draws each point as a bar extending from y=0 to the value given by [valueMapper].
/// This series
class ColumnSeries<T> extends Series<T> {
  Color? color;
  final double Function(int i, T item) _valueMapper;
  double valueMapper(int i) => _valueMapper(i, data[i]);

  /// Supply a custom color for each point. By default the series [color] is used.
  final Color? Function(int i, T item)? colorMapper;

  /// A value betwen [-0.5, 0.5] on where to center each bar. 0 indicates the center of the bin
  /// while 0.5 indicates the midpoint between the next bin.
  double? offset;
  static const defaultOffset = 0.0;

  /// A value between [0, 1] for the width of the bar. 1 indicates taking the full bin width (no
  /// padding between bars). Generally offset +- width should be in [-0.5, 0.5].
  double? width;
  static const defaultWidth = 0.8;

  /// Cache the points to enable easy hit testing
  final List<ColumnSeriesPoint<T>> _renderedPoints = [];

  ColumnSeries({
    required super.name,
    required super.data,
    required double Function(int i, T item) valueMapper,
    this.offset,
    this.color,
    this.colorMapper,
  }) : _valueMapper = valueMapper;

  ColumnSeriesPoint<T> _addPoint(CartesianCoordinateSpace coordSpace, int i) {
    final out = ColumnSeriesPoint(
      index: i,
      item: data[i],
      value: valueMapper(i),
      color: colorMapper?.call(i, data[i]) ?? this.color ?? Colors.blue,
      pixelPos: coordSpace.userToPixelRect(boundingBox(i)),
    );
    assert(_renderedPoints.length == i);
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
      canvas.drawRect(point.pixelPos, painter);
    }
  }

  @override
  BoundingBox boundingBox(int i) {
    final y = valueMapper(i);
    final x = i.toDouble() + (offset ?? defaultOffset);
    final width = this.width ?? defaultWidth;
    return BoundingBox(xMin: x - width / 2, xMax: x + width / 2, yMin: min(0, y), yMax: max(0, y));
  }

  // @override
  // double? hoverValue(int i) {
  //   return valueMapper(i);
  // }

  @override
  Widget? hoverBuilder(BuildContext context, int i, DiscreteCartesianGraphPainter mainGraph) {
    if (i < 0 || i >= _renderedPoints.length) return null;
    final point = _renderedPoints[i];
    if (point.value == 0) return null;
    if (name.isEmpty) {
      return Text(
        mainGraph.yAxis.valToString(point.value),
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10.0,
          height: 10.0,
          decoration: BoxDecoration(
            color: point.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          "$name: ${mainGraph.yAxis.valToString(point.value)}",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  @override
  int? hitTest(Offset offset, CartesianCoordinateSpace coordSpace) {
    for (int i = 0; i < _renderedPoints.length; i++) {
      if (_renderedPoints[i].pixelPos.contains(offset)) return i;
    }
    return null;
  }
}

final testColumnSeries = ColumnSeries(
  name: 'test',
  data: [10000.0, 20000.0, 15000.0, -8000.0, -9000.001, 7123.45],
  valueMapper: (i, it) => it,
);
