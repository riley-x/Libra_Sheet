import 'dart:math';

import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_coordinate_space.dart';
import 'package:libra_sheet/graphing/cartesian/discrete_cartesian_graph.dart';
import 'package:libra_sheet/graphing/extensions.dart';
import 'package:libra_sheet/graphing/series/series.dart';
import 'package:libra_sheet/theme/colorscheme.dart';

/// Flutter refuses to support dashed lines !?!?, so have to manually calculate.
/// https://github.com/flutter/flutter/issues/4858.
///
/// Could use this package...but it only takes SVG string paths.
/// https://pub.dev/packages/path_drawing
///
/// Or see this SO answer
/// https://stackoverflow.com/a/71099304/10988347
class DashedHorizontalLine extends Series<double?> {
  final Color color;

  /// Vertical position in user coordinates
  final double y;

  /// The stroke width of the line
  final double lineWidth;

  /// The length of each dash in pixels
  final double dashLength;

  /// The space between each dash in pixels
  final double dashSpace;

  /// An offset from the left in pixels for where to start the first dash (default: 0).
  final double dashStart;

  /// Draws a flag label on the y-axis displaying the average value.
  final bool drawLabel;

  /// Data should contain only two values, representing the start and end x-values of the line in
  /// user coordinates. They can also be null, meaning the start/end of the axis.
  /// Default: [null, null].
  const DashedHorizontalLine({
    super.name = '',
    List<double?>? data,
    required this.color,
    required this.y,
    this.lineWidth = 0,
    this.dashLength = 9,
    this.dashSpace = 5,
    this.dashStart = 0,
    this.drawLabel = true,
  }) : super(data: data ?? const [null, null]);

  @override
  BoundingBox? boundingBox(int i) {
    return null;
  }

  @override
  void paint(CustomPainter painter, Canvas canvas, CartesianCoordinateSpace coordSpace) {
    assert(data.length == 2);
    if (this.y == 0) return;
    if (painter is DiscreteCartesianGraphPainter) {
      if (this.y == painter.xAxis.axisLoc) return;
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = lineWidth
      ..isAntiAlias = false;

    /// Get pixel positions
    final y = coordSpace.yAxis.userToPixel(this.y);
    final startPos =
        data[0] == null ? coordSpace.xAxis.pixelMin : coordSpace.xAxis.userToPixel(data[0]!);
    final endPos =
        data[1] == null ? coordSpace.xAxis.pixelMax : coordSpace.xAxis.userToPixel(data[1]!);

    /// Draw dashes
    var currPos = startPos + dashStart;
    while (currPos < endPos) {
      final end = min(endPos, currPos + dashLength);
      canvas.drawLine(Offset(currPos, y), Offset(end, y), paint);
      currPos += dashLength + dashSpace;
    }

    /// Draw label
    if (drawLabel) {
      if (painter is DiscreteCartesianGraphPainter) {
        final text = TextPainter(
          text: TextSpan(
            text: painter.yAxis.valToString(this.y, painter.yLabelOrder),
            style: painter.yAxis.labelStyle?.copyWith(color: adaptiveTextColor(color)),
          ),
          textDirection: TextDirection.ltr,
        );
        text.layout();

        final loc = Offset(
          coordSpace.xAxis.pixelMin - painter.yAxis.labelOffset - text.width,
          y - text.height / 2,
        );
        final flagPath = createFlag(loc & text.size, coordSpace.xAxis.pixelMin + 1);
        canvas.drawPath(flagPath, paint);
        text.paint(canvas, loc);
      }
    }
  }

  Path createFlag(Rect content, double xMax) {
    final backgroundRect = content.inflate(1);
    return Path()
      ..moveToOffset(backgroundRect.topLeft)
      ..lineToOffset(backgroundRect.topRight)
      ..lineTo(xMax, backgroundRect.center.dy)
      ..lineToOffset(backgroundRect.bottomRight)
      ..lineToOffset(backgroundRect.bottomLeft)
      ..close();
  }
}
