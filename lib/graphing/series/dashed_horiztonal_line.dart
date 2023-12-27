import 'dart:math';

import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_coordinate_space.dart';
import 'package:libra_sheet/graphing/series/series.dart';

/// Flutter refuses to support dashed lines !?!?, so have to manually calculate.
/// https://github.com/flutter/flutter/issues/4858.
///
/// Could use this package...but it only takes SVG string paths.
/// https://pub.dev/packages/path_drawing
///
/// Or see this SO answer
/// https://stackoverflow.com/a/71099304/10988347
class DashedHorizontalLine extends Series<double> {
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

  /// Data should contain only two values, representing the start and end x-values of the line in
  /// user coordinates.
  const DashedHorizontalLine({
    super.name = '',
    required super.data,
    required this.color,
    required this.y,
    this.lineWidth = 0,
    this.dashLength = 9,
    this.dashSpace = 5,
    this.dashStart = 0,
  });

  @override
  BoundingBox? boundingBox(int i) {
    return null;
  }

  @override
  void paint(Canvas canvas, CartesianCoordinateSpace coordSpace) {
    assert(data.length == 2);
    final paint = Paint()
      ..color = color
      ..strokeWidth = lineWidth
      ..isAntiAlias = false;

    var y = coordSpace.yAxis.userToPixel(this.y);
    var currPos = coordSpace.xAxis.userToPixel(data[0]);
    currPos += dashStart;
    while (currPos < coordSpace.xAxis.canvasSize) {
      final end = min(coordSpace.xAxis.canvasSize, currPos + dashLength);
      canvas.drawLine(Offset(currPos, y), Offset(end, y), paint);
      currPos += dashLength + dashSpace;
    }
  }
}
