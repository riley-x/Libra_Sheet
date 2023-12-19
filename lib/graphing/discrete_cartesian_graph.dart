import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/cartesian_axes.dart';

class _DiscreteCartesianGraphPainter<T> extends CustomPainter {
  final CartesianAxesInternal axes;

  /// Cache
  Size _paintSize = Size.zero;

  _DiscreteCartesianGraphPainter({
    super.repaint,
    required this.axes,
  });

  void paintXaxis(Canvas canvas, Size size) {
    double x1 = axes.userToPixelX(axes.xMin, size);
    double x2 = axes.userToPixelX(axes.xMax, size);
    double y = axes.userToPixelY(axes.xAxisLoc, size);
    canvas.drawLine(Offset(x1, y), Offset(x2, y), axes.xAxisPainter);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintSize = size;
    paintXaxis(canvas, size);
  }

  @override
  bool shouldRepaint(_DiscreteCartesianGraphPainter<T> oldDelegate) {
    return axes != oldDelegate.axes;
  }
}

class DiscreteCartesianGraph extends StatelessWidget {
  final CartesianAxes axes;

  const DiscreteCartesianGraph({
    super.key,
    required this.axes,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _DiscreteCartesianGraphPainter(
          axes: CartesianAxesInternal(context, axes),
        ),
        size: Size.infinite,
      ),
    );
  }
}
