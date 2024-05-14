import 'dart:math';
import 'dart:ui';

import 'package:flutter/src/rendering/custom_paint.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_coordinate_space.dart';
import 'package:libra_sheet/graphing/extensions.dart';
import 'package:libra_sheet/graphing/series/line_series.dart';
import 'package:libra_sheet/graphing/series/series.dart';

class StackLineSeries<T> extends LineSeries<T> {
  /// This represents the cumulative base value for other StackColumnSeries supplied to a graph.
  /// It is set post-construction by [SeriesCollection].
  List<Offset> stackBase = [];

  final Paint _painter;

  StackLineSeries({
    required super.name,
    required super.data,
    required super.valueMapper,
    super.color,
  }) : _painter = Paint()
          ..color = color
          ..style = PaintingStyle.fill
          ..strokeWidth = 2;

  LineSeriesPoint<T> _addPoint(CartesianCoordinateSpace coordSpace, int i) {
    final item = data[i];
    final value = valueMapper(i, item);
    final baseValue = stackBase.elementAtOrNull(i)?.dy ?? 0;
    final pixelPos = coordSpace.userToPixel(Offset(value.dx, value.dy + baseValue));
    final out = LineSeriesPoint(index: i, item: item, value: value, pixelPos: pixelPos);
    // _renderedPoints.add(out);
    return out;
  }

  @override
  void paint(CustomPainter painter, Canvas canvas, CartesianCoordinateSpace coordSpace) {
    // _renderedPoints.clear();
    if (data.length <= 1) return;

    final path = Path();
    final start = _addPoint(coordSpace, 0);
    path.moveTo(start.pixelPos.dx, start.pixelPos.dy);
    for (int i = 1; i < data.length; i++) {
      final curr = _addPoint(coordSpace, i);
      path.lineTo(curr.pixelPos.dx, curr.pixelPos.dy);
    }

    // for (final offset in stackBase.reversed) {
    //   final pixelPos = coordSpace.userToPixel(offset);
    //   path.lineTo(pixelPos.dx, pixelPos.dy);
    // }
    path.lineToOffset(coordSpace.userToPixel(Offset((data.length - 1).toDouble(), 0)));
    path.lineToOffset(coordSpace.userToPixel(const Offset(0, 0)));
    path.close();

    canvas.drawPath(path, _painter);
  }

  @override
  BoundingBox boundingBox(int i) {
    final val = valueMapper(i, data[i]).dy;
    final base = stackBase.elementAtOrNull(i)?.dy ?? 0;
    final x = i.toDouble();
    return BoundingBox(
      xMin: x,
      xMax: x,
      yMin: min(base, base + val),
      yMax: max(base, base + val),
    );
  }

  @override
  bool accumulateStack(Map<int, double> posVals, Map<int, double> negVals) {
    stackBase = [];
    for (int i = 0; i < data.length; i++) {
      final val = valueMapper(i, data[i]);
      final agg = (val.dy >= 0) ? posVals : negVals;
      final currBase = agg.putIfAbsent(i, () => 0);
      stackBase.add(Offset(i.toDouble(), currBase));
      agg[i] = agg[i]! + val.dy;
    }
    return true;
  }
}
