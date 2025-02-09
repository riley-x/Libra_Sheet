import 'dart:math';

import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_coordinate_space.dart';
import 'package:libra_sheet/graphing/cartesian/discrete_cartesian_graph.dart';
import 'package:libra_sheet/graphing/extensions.dart';
import 'package:libra_sheet/graphing/series/series.dart';
import 'package:dash_painter/dash_painter.dart';

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
  final Color? fillColor;
  final Offset Function(int i, T item) valueMapper;
  final Paint linePainter;
  final double strokeWidth;

  /// The gradient's y-rect is defined such that stop 0.0 = the x-axis loc and stop 1.0 = towards
  /// y_max, but with offset equal to the max of (x_axis - y_min) and (y_max - x_axis). This aligns
  /// with the fill, which extends to the x-axis.
  ///
  /// Note that when the line alternates around the axis, you can achieve a nice symmetric fill by
  /// using [TileMode.mirror] in the gradient.
  final Gradient? gradient;
  final DashPainter? dash;

  /// Cache the points to enable easy hit testing
  final List<LineSeriesPoint<T>> _renderedPoints = [];

  LineSeries({
    required super.name,
    required super.data,
    required this.valueMapper,
    this.color = Colors.blue,
    this.fillColor,
    this.strokeWidth = 3,
    this.gradient,
    this.dash,
  }) : linePainter = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

  LineSeriesPoint<T> _addPoint(CartesianCoordinateSpace coordSpace, int i) {
    final item = data[i];
    final value = valueMapper(i, item);
    final pixelPos = coordSpace.userToPixel(value);
    final out = LineSeriesPoint(index: i, item: item, value: value, pixelPos: pixelPos);
    _renderedPoints.add(out);
    return out;
  }

  @override
  void paint(CustomPainter painter, Canvas canvas, CartesianCoordinateSpace coordSpace) {
    _renderedPoints.clear();
    if (data.length <= 1) return;

    /// Render and path
    final path = Path();

    final start = _addPoint(coordSpace, 0);
    path.moveToOffset(start.pixelPos);

    for (int i = 1; i < data.length; i++) {
      final curr = _addPoint(coordSpace, i);
      path.lineTo(curr.pixelPos.dx, curr.pixelPos.dy);
    }

    /// Main line
    if (dash != null) {
      dash!.paint(canvas, path, linePainter);
    } else {
      canvas.drawPath(path, linePainter);
    }

    /// Gradient
    if (fillColor != null || gradient != null) {
      final axisPixelY = coordSpace.yAxis.userToPixel(0);
      path.lineTo(_renderedPoints.last.pixelPos.dx, axisPixelY);
      path.lineTo(_renderedPoints.first.pixelPos.dx, axisPixelY);
      path.close();

      final maxDiff = max(
        (coordSpace.yAxis.pixelMax - axisPixelY).abs(),
        (coordSpace.yAxis.pixelMin - axisPixelY).abs(),
      );
      canvas.drawPath(
          path,
          Paint()
            ..color = fillColor ?? Colors.black // black is default which lets shader override
            ..shader = gradient!.createShader(Rect.fromLTRB(
              0,
              axisPixelY - maxDiff,
              coordSpace.xAxis.canvasSize,
              axisPixelY,
            )));
    }
  }

  @override
  BoundingBox boundingBox(int i) {
    return BoundingBox.fromPoint(valueMapper(i, data[i]));
  }

  @override
  double? hoverValue(int i) => _renderedPoints.elementAtOrNull(i)?.value.dy;

  @override
  Widget? hoverBuilder(
    BuildContext context,
    int i,
    DiscreteCartesianGraphPainter mainGraph, {
    bool labelOnly = false,
  }) {
    if (i < 0 || i >= _renderedPoints.length) return null;

    final point = _renderedPoints[i];
    if (point.value.dy == 0) return null;
    if (name.isEmpty) {
      return Text(
        mainGraph.yAxis.valToString(point.value.dy),
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10.0,
          height: min(strokeWidth * 2, 10.0),
          color: linePainter.color,
        ),
        const SizedBox(width: 5),
        Text(
          "$name: ${mainGraph.yAxis.valToString(point.value.dy)}",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

final testSeries = LineSeries(
  name: 'test',
  data: [10000.0, 20000.0, 15000.0, -8000.0, -9000.0, 7000.0],
  valueMapper: (i, it) => Offset(i.toDouble(), it),
);
