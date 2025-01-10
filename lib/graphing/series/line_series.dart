import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_coordinate_space.dart';
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

    var negative = false;

    /// Line
    final path = Path();

    final start = _addPoint(coordSpace, 0);
    path.moveTo(start.pixelPos.dx, start.pixelPos.dy);
    if (start.value.dy < 0) negative = true;

    for (int i = 1; i < data.length; i++) {
      final curr = _addPoint(coordSpace, i);
      path.lineTo(curr.pixelPos.dx, curr.pixelPos.dy);
      if (curr.value.dy < 0) negative = true;
    }
    if (dash != null) {
      dash!.paint(canvas, path, linePainter);
    } else {
      canvas.drawPath(path, linePainter);
    }

    /// Gradient; TODO this assumes all points are on same side of 0
    if (gradient != null) {
      path.lineToOffset(
          coordSpace.userToPixel(Offset(valueMapper(data.length - 1, data.last).dx, 0)));
      path.lineToOffset(coordSpace.userToPixel(Offset(valueMapper(0, data.first).dx, 0)));
      canvas.drawPath(
          path,
          Paint()
            ..shader = gradient!.createShader(Rect.fromLTRB(
              0,
              negative ? coordSpace.yAxis.userToPixel(0) : coordSpace.yAxis.pixelMax,
              coordSpace.xAxis.canvasSize,
              negative ? coordSpace.yAxis.pixelMin : coordSpace.yAxis.userToPixel(0),
            )));
    }
  }

  @override
  BoundingBox boundingBox(int i) {
    return BoundingBox.fromPoint(valueMapper(i, data[i]));
  }

  @override
  double? hoverValue(int i) => _renderedPoints.elementAtOrNull(i)?.value.dy;
}

final testSeries = LineSeries(
  name: 'test',
  data: [10000.0, 20000.0, 15000.0, -8000.0, -9000.0, 7000.0],
  valueMapper: (i, it) => Offset(i.toDouble(), it),
);
