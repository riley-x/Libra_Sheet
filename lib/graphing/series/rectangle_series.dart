import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_coordinate_space.dart';
import 'package:libra_sheet/graphing/series/series.dart';

class RectangleSeries extends Series<Rect> {
  final Color color;

  RectangleSeries({
    super.name = "",
    required super.data,
    this.color = Colors.blue,
  });

  @override
  void paint(CustomPainter painter, Canvas canvas, CartesianCoordinateSpace coordSpace) {
    for (final userRect in data) {
      final pixelRect = Rect.fromLTRB(
        userRect.left.isInfinite
            ? coordSpace.xAxis.pixelMin
            : coordSpace.xAxis.userToPixel(userRect.left),
        userRect.top.isInfinite
            ? coordSpace.yAxis.pixelMin
            : coordSpace.yAxis.userToPixel(userRect.top),
        userRect.right.isInfinite
            ? coordSpace.xAxis.pixelMax
            : coordSpace.xAxis.userToPixel(userRect.right),
        userRect.bottom.isInfinite
            ? coordSpace.yAxis.pixelMax
            : coordSpace.yAxis.userToPixel(userRect.bottom),
      );
      canvas.drawRect(
        pixelRect,
        Paint()
          ..style = PaintingStyle.fill
          ..color = color,
      );
    }
  }

  @override
  BoundingBox? boundingBox(int i) => null;
}
