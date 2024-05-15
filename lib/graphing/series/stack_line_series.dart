import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_coordinate_space.dart';
import 'package:libra_sheet/graphing/cartesian/discrete_cartesian_graph.dart';
import 'package:libra_sheet/graphing/extensions.dart';
import 'package:libra_sheet/graphing/series/line_series.dart';
import 'package:libra_sheet/graphing/series/series.dart';

final _debugGradient = ui.Gradient.linear(
  const Offset(0, 0),
  const Offset(0, 1),
  [
    Colors.white,
    Colors.green,
    Colors.green,
    Colors.white,
    Colors.blue,
    Colors.blue,
    Colors.white,
  ],
  [
    0,
    0.1,
    0.45,
    0.5,
    0.55,
    0.9,
    1,
  ],
  // TileMode.decal,
);

class StackLineSeries<T> extends LineSeries<T> {
  /// This represents the cumulative base value for other StackColumnSeries supplied to a graph.
  /// It is set post-construction by [SeriesCollection].
  List<Offset> stackBase = [];

  StackLineSeries({
    required super.name,
    required super.data,
    required super.valueMapper,
    super.color,
  });

  LineSeriesPoint<T> _addPoint(CartesianCoordinateSpace coordSpace, int i) {
    final item = data[i];
    final value = valueMapper(i, item);
    final baseValue = stackBase.elementAtOrNull(i)?.dy ?? 0;
    final pixelPos = coordSpace.userToPixel(Offset(value.dx, value.dy + baseValue));
    final out = LineSeriesPoint(index: i, item: item, value: value, pixelPos: pixelPos);
    return out;
  }

  /// Finds the minimum and maximum y extend of the filled stack area in user coordinates.
  (double, double) _getMinMaxUser() {
    if (data.isEmpty || stackBase.isEmpty) return (0, 1);

    double minY = stackBase[0].dy;
    double maxY = stackBase[0].dy;
    for (int i = 0; i < data.length; i++) {
      final val1 = stackBase.elementAtOrNull(i)?.dy ?? 0;
      final val2 = valueMapper(i, data[i]).dy + val1;
      minY = min(minY, min(val1, val2));
      maxY = max(maxY, max(val1, val2));
    }
    return (minY, maxY);
  }

  /// This function paints a single segment of the series, which is the 4-gon between two points.
  /// [i] is the index of the left edge's data points.
  ///
  /// These are painted by first painting a unit square, (0,0) to (1,1), and then transforming it.
  /// The transform is derived by identifying the matrix that solves (ignoring the z components)
  ///
  ///   | a   b   c |     | x |     | x' |
  ///   | d   e   f |  *  | y |  =  | y' |
  ///   | g   h   1 |     | 1 |     | 1  |
  ///
  /// Where x,y = 0,1 and the new vector matches the desired position. For simplicity, we factor out
  /// a common translation to the bottom-left corner so (0, 0) -> (0, 0). This results in the 4
  /// non-zero components below.
  ///
  /// See https://en.wikipedia.org/wiki/Transformation_matrix#Perspective_projection
  ///
  /// We have special cases when one side of the 4-gon is 0, so it's really a triangle. Here we can
  /// set g = h = 0 for simplicity, and draw instead a unit right triangle.
  void _paintSegment(Canvas canvas, CartesianCoordinateSpace coordSpace, int i) {
    final val1 = valueMapper(i, data[i]);
    final val2 = valueMapper(i + 1, data[i + 1]);

    final bottomLeft = coordSpace.userToPixel(stackBase[i]);
    final topLeft = coordSpace.userToPixel(val1 + Offset(0, stackBase[i].dy)) - bottomLeft;
    final topRight = coordSpace.userToPixel(val2 + Offset(0, stackBase[i + 1].dy)) - bottomLeft;
    final bottomRight = coordSpace.userToPixel(stackBase[i + 1]) - bottomLeft;

    if (val1.dy == 0 && val2.dy == 0) return;
    if (val1.dy == 0.0) {
      final a = topRight.dx;
      final d = bottomRight.dy;
      final e = topRight.dy - bottomRight.dy;

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..strokeWidth = 2
        ..shader = ui.Gradient.sweep(
          // these coordinates are the pixel coordiantes of the sweep center. But since we're
          // plotting a unit triangle, the pixel coordinates are also 0..1.
          const Offset(0, 0),
          [
            color.withAlpha(200),
            color.withAlpha(220),
            color.withAlpha(255),
          ],
          [
            0,
            0.4,
            1,
          ],
          TileMode.clamp,
          0.0,
          math.pi / 4,
        );

      final transform = Matrix4.translationValues(bottomLeft.dx, bottomLeft.dy, 0) *
          (Matrix4.fromList([
            ...[a, 0, 0, 0],
            ...[d, e, 0, 0],
            ...[0, 0, 1, 0],
            ...[0, 0, 0, 1],
          ])
            ..transpose()); // transpose because the constructor expects column-major entries

      canvas.save();
      canvas.transform(transform.storage);
      // inflate the x values to avoid boundaries
      canvas.drawPath(
          Path()
            ..moveTo(0, 0)
            ..lineTo(1, 0)
            ..lineTo(1, 1)
            ..close(),
          paint);
      canvas.restore();
    } else if (val2.dy == 0) {
      final a = bottomRight.dx;
      final d = bottomRight.dy;
      final e = topLeft.dy;

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..strokeWidth = 2
        ..shader = ui.Gradient.sweep(
          // these coordinates are the pixel coordiantes of the sweep center. But since we're
          // plotting a unit triangle, the pixel coordinates are also 0..1.
          const Offset(1, 0),
          [
            color.withAlpha(255),
            color.withAlpha(220),
            color.withAlpha(200),
          ],
          [
            0,
            0.6,
            1,
          ],
          TileMode.clamp,
          3 * math.pi / 4,
          math.pi,
        );

      final transform = Matrix4.translationValues(bottomLeft.dx, bottomLeft.dy, 0) *
          (Matrix4.fromList([
            ...[a, 0, 0, 0],
            ...[d, e, 0, 0],
            ...[0, 0, 1, 0],
            ...[0, 0, 0, 1],
          ])
            ..transpose()); // transpose because the constructor expects column-major entries

      canvas.save();
      canvas.transform(transform.storage);
      // inflate the x values to avoid boundaries
      canvas.drawPath(
          Path()
            ..moveTo(-0.006, 0)
            ..lineTo(1, 0)
            ..lineTo(-0.006, 1)
            ..close(),
          paint);
      canvas.restore();
    } else {
      final g = topLeft.dy / (topRight.dy - bottomRight.dy) - 1;
      final e = topLeft.dy;
      final d = bottomRight.dy * (g + 1);
      final a = topRight.dx * (g + 1);

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..strokeWidth = 2
        ..shader = ui.Gradient.linear(
          // these coordinates are the pixel coordiantes that correspond to the
          // 0/1 stop positions (note since we're plotting a unit square, the pixel coordinates are
          // also 0..1). The x position doesn't matter since it's a vertical gradient.
          const Offset(0, 0),
          const Offset(0, 1),
          [
            color.withAlpha(200),
            color.withAlpha(220),
            color.withAlpha(255),
          ],
          [
            0,
            0.4,
            1,
          ],
          // TileMode.decal,
        );

      final transform = Matrix4.translationValues(bottomLeft.dx, bottomLeft.dy, 0) *
          (Matrix4.fromList([
            ...[a, 0, 0, 0],
            ...[d, e, 0, 0],
            ...[0, 0, 1, 0],
            ...[g, 0, 0, 1],
          ])
            ..transpose()); // transpose because the constructor expects column-major entries

      canvas.save();
      canvas.transform(transform.storage);
      // inflate the x values to avoid boundaries
      canvas.drawRect(const Rect.fromLTRB(-0.006, 0, 1.006, 1), paint);
      canvas.restore();
    }
  }

  @override
  void paint(CustomPainter painter, Canvas canvas, CartesianCoordinateSpace coordSpace) {
    if (data.length <= 1) return;

    /// Paint segments
    for (int i = 0; i < data.length - 1; i++) {
      _paintSegment(canvas, coordSpace, i);
    }

    /// Paint path to hide boundary effects
    final path = Path();
    var curr = _addPoint(coordSpace, 0);
    path.moveTo(curr.pixelPos.dx, curr.pixelPos.dy);
    for (int i = 1; i < data.length; i++) {
      curr = _addPoint(coordSpace, i);
      path.lineTo(curr.pixelPos.dx, curr.pixelPos.dy);
    }

    /// Close along y=0. The [DiscreteCartesianGraph] will paint stacked items in reverse order.
    /// Tracing the bottom edge via a path leads to janky pixels, so overlapping is better.
    // path.lineToOffset(coordSpace.userToPixel(Offset((data.length - 1).toDouble(), 0)));
    // path.lineToOffset(coordSpace.userToPixel(const Offset(0, 0)));
    // path.close();

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    canvas.drawPath(path, paint);
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

  @override
  double? hoverValue(int i) {
    final val = valueMapper(i, data[i]).dy;
    if (val == 0) return null;
    return val;
  }

  @override
  Widget? hoverBuilder(BuildContext context, int i, DiscreteCartesianGraphPainter mainGraph) {
    final val = valueMapper(i, data[i]).dy;
    if (val == 0) return null;
    if (name.isEmpty) {
      return Text(
        mainGraph.yAxis.valToString(val),
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
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          "$name: ${mainGraph.yAxis.valToString(val)}",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
