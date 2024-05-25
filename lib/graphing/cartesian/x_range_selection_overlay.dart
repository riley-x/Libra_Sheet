import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_coordinate_space.dart';

/// This widget draws a transparent overlay when selecting a range of x values. The overlay extends
/// the range of the y-axis.
class XRangeSelectionOverlay extends StatelessWidget {
  const XRangeSelectionOverlay({
    super.key,
    required this.xStart,
    required this.xEnd,
    required this.coords,
    this.color,
  });

  final double xStart;
  final double xEnd;
  final CartesianCoordinateSpace coords;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _XRangeSelectionOverlayPainter(
        xStart: xStart,
        xEnd: xEnd,
        coords: coords,
        color: color ?? Theme.of(context).colorScheme.onSurface.withAlpha(60),
      ),
      size: Size.infinite,
    );
  }
}

class _XRangeSelectionOverlayPainter extends CustomPainter {
  const _XRangeSelectionOverlayPainter({
    required this.xStart,
    required this.xEnd,
    required this.coords,
    required this.color,
  });

  final double xStart;
  final double xEnd;
  final CartesianCoordinateSpace coords;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final x1 = coords.xAxis.userToPixel(xStart);
    final x2 = coords.xAxis.userToPixel(xEnd);

    if (xStart != xEnd) {
      canvas.drawRect(
        Rect.fromPoints(
          Offset(x1, coords.yAxis.pixelMin),
          Offset(x2, coords.yAxis.pixelMax),
        ),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_XRangeSelectionOverlayPainter oldDelegate) {
    return xStart != oldDelegate.xStart || xEnd != oldDelegate.xEnd || coords != oldDelegate.coords;
  }
}
