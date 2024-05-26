import 'dart:math';
import 'dart:ui' as ui;
// import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_coordinate_space.dart';
import 'package:libra_sheet/graphing/cartesian/discrete_cartesian_graph.dart';
import 'package:libra_sheet/graphing/extensions.dart';
import 'package:libra_sheet/graphing/series/line_series.dart';
import 'package:libra_sheet/graphing/series/series.dart';
// import 'package:vector_math/vector_math_64.dart' as vector;

final _debugGradientColors = [
  Colors.white,
  Colors.green,
  Colors.green,
  Colors.white,
  Colors.blue,
  Colors.blue,
  Colors.white,
];
final _debugGradientStops = [
  0.0,
  0.1,
  0.45,
  0.5,
  0.55,
  0.9,
  1.0,
];

class StackLineSeries<T> extends LineSeries<T> {
  /// This represents the cumulative base value for other StackColumnSeries supplied to a graph.
  /// It is set post-construction by [SeriesCollection].
  List<Offset> stackBase = [];

  List<double> gradientStops = [];
  List<Color> gradientColors = [];

  StackLineSeries({
    required super.name,
    required super.data,
    required super.valueMapper,
    super.color,
    super.strokeWidth,
    List<double>? gradientStops,
    List<Color>? gradientColors,
  }) {
    assert((gradientStops != null) == (gradientColors != null));
    this.gradientStops = gradientStops ?? const [0, 0.4, 1];
    this.gradientColors = gradientColors ??
        [
          color.withAlpha(120),
          color.withAlpha(180),
          color.withAlpha(255),
        ];
  }

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

  bool _sameSign(double v1, double v2) {
    if (v1 > 0) return v2 >= 0;
    if (v1 == 0) return true;
    return v2 <= 0;
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
  /// We have special cases when one side of the 4-gon is 0. Here the solution sends the
  /// parameters to 0 or infinity, so we approximate with a very small or large value. This
  /// approximation sometimes causes rounding errors on the edges though, and adding too many
  /// decimals causes things to break. It seems like the canvas transform uses some really low
  /// precision float or something. Probably the same issue:
  ///       https://github.com/flutter/flutter/issues/126026
  /// However, if we transform only the gradient and not the canvas itself, the rounding issue
  /// is basically not noticeable.
  void _paintSegment(Canvas canvas, CartesianCoordinateSpace coordSpace, int i) {
    final val1 = valueMapper(i, data[i]);
    final val2 = valueMapper(i + 1, data[i + 1]);
    if (val1.dy == 0 && val2.dy == 0) return;
    // if (!_sameSign(val1.dy, stackBase[i].dy)) return;
    // if (!_sameSign(val2.dy, stackBase[i + 1].dy)) return;
    // if (!_sameSign(val1.dy, val2.dy)) return;

    final bottomLeft = coordSpace.userToPixel(stackBase[i]);
    final topLeft = coordSpace.userToPixel(val1 + Offset(0, stackBase[i].dy)) - bottomLeft;
    final topRight = coordSpace.userToPixel(val2 + Offset(0, stackBase[i + 1].dy)) - bottomLeft;
    final bottomRight = coordSpace.userToPixel(stackBase[i + 1]) - bottomLeft;

    double g;
    double e = topLeft.dy;
    double xRight = bottomRight.dx;
    if (topRight.dy == bottomRight.dy) {
      g = 9999999;
    } else if (topLeft.dy.abs() < 1e-6) {
      g = -0.995;
      e = (topRight.dy - bottomRight.dy) * (g + 1);
      // e = -0.001;
      // g = e / (topRight.dy - bottomRight.dy) - 1;
    } else {
      g = topLeft.dy / (topRight.dy - bottomRight.dy) - 1;
    }
    final d = bottomRight.dy * (g + 1);
    final a = (g + 1);

    Matrix4 transform = Matrix4.fromList([
      ...[a, 0, 0, 0],
      ...[d, e, 0, 0],
      ...[0, 0, 1, 0],
      ...[g, 0, 0, 1],
    ])
      ..transpose(); // transpose because the constructor expects column-major entries
    transform = (Matrix4.identity()..setEntry(0, 0, xRight)) * transform;
    transform = Matrix4.translationValues(bottomLeft.dx, bottomLeft.dy, 0) * transform;
    // for some reason the .scale() and .transform() methods don't work?

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2
      ..isAntiAlias = false // prevents boundary effects, will snap to nearest pixel.
      ..shader = ui.Gradient.linear(
        // these coordinates are the pixel coordiantes that correspond to the
        // 0/1 stop positions (note since we're plotting a unit square, the pixel coordinates are
        // also 0..1). The x position doesn't matter since it's a vertical gradient.
        const Offset(0, 0),
        const Offset(0, 1),
        gradientColors,
        gradientStops,
        TileMode.clamp,
        transform.storage,
      );

    /// Don't transform the canvas and draw unit square, just transform the gradient instead. Avoids
    /// boundary effects and rounding errors.
    // canvas.save();
    // canvas.transform(transform.storage);
    // canvas.drawRect(const Rect.fromLTRB(0, 0, 1, 1), paint);
    // canvas.restore();

    canvas.drawPath(
      Path()
        ..moveToOffset(bottomLeft)
        ..lineToOffset(topLeft + bottomLeft)
        ..lineToOffset(topRight + bottomLeft)
        ..lineToOffset(bottomRight + bottomLeft)
        ..close(),
      paint,
    );
  }

  @override
  void paint(CustomPainter painter, Canvas canvas, CartesianCoordinateSpace coordSpace) {
    if (data.length <= 1) return;

    canvas.save();
    canvas.clipRect(coordSpace.dataRect);

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
      path.lineToOffset(curr.pixelPos);
    }

    canvas.drawPath(path, linePainter);
    canvas.restore();

    /// Close along y=0. The [DiscreteCartesianGraph] will paint stacked items in reverse order.
    /// Tracing the bottom edge via a path leads to janky pixels, so overlapping is better.
    // path.lineToOffset(coordSpace.userToPixel(Offset((data.length - 1).toDouble(), 0)));
    // path.lineToOffset(coordSpace.userToPixel(const Offset(0, 0)));
    // path.close();
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

    bool isPositiveBase(int i) {
      final val = valueMapper(i, data[i]);
      if (val.dy > 0) return true;
      if (val.dy < 0) return false;

      /// Special case for y == 0, match the base used by the previous/next point. This will still
      /// not work for entries that cross the y=0 axis, but those should be avoided anyways.
      for (int j = stackBase.length - 1; j >= 0; j--) {
        if (stackBase[j].dy > 0) return true;
        if (stackBase[j].dy < 0) return false;
      }
      for (int j = i + 1; j < data.length; j++) {
        final val2 = valueMapper(j, data[j]);
        if (val2.dy > 0) return true;
        if (val2.dy < 0) return false;
      }
      return true;
    }

    for (int i = 0; i < data.length; i++) {
      final val = valueMapper(i, data[i]);
      final agg = (isPositiveBase(i)) ? posVals : negVals;
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
