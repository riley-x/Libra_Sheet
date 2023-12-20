import 'dart:math';

import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/cartesian_axes.dart';
import 'package:libra_sheet/graphing/series.dart';

class _DiscreteCartesianGraphPainter<T> extends CustomPainter {
  final CartesianAxis xAxis;
  final CartesianAxis yAxis;
  final ThemeData theme;
  final List<Series<T>> data;

  /// Variables of a given paint
  Size currentSize = Size.zero;
  CartesianCoordinateSpace? coordSpace;
  List<(double, TextPainter)>? xLabels;
  List<(double, TextPainter)>? yLabels;

  _DiscreteCartesianGraphPainter({
    super.repaint,
    required this.data,
    required this.xAxis,
    required this.yAxis,
    required this.theme,
  });

  /// Lays out the axis with default labels and padding.
  void layoutAxes(Size size) {
    if (size == currentSize) return;

    currentSize = size;
    coordSpace = CartesianCoordinateSpace.autoRange(
      canvasSize: size,
      xAxis: xAxis,
      yAxis: yAxis,
      data: data,
    );

    /// Auto labels and axis padding; TODO this is hard coded for bottom and left aligned labels
    yLabels = yAxis.autoYLabels(coordSpace!);
    if (coordSpace!.xAxis.padStart == null) {
      var maxLabelWidth = 0.0;
      for (final (_, x) in yLabels) {
        maxLabelWidth = max(maxLabelWidth, x.width);
      }
      coordSpace!.xAxis.padStart = maxLabelWidth + yAxis.labelOffset;
    }
    xLabels = xAxis.autoXLabels(coordSpace!);
    if (coordSpace!.yAxis.padStart == null) {
      coordSpace!.yAxis.padStart = coordSpace!.xAxis.labelLineHeight + xAxis.labelOffset;
    }
  }

  // TODO this is hard coded for bottom and left aligned labels
  void paintLabels(Canvas canvas) {
    if (coordSpace == null) return;

    /// x labels
    for (final (pos, painter) in xLabels) {
      final loc = Offset(
        coordSpace!.xAxis.userToPixel(pos) - painter.width / 2,
        coordSpace!.yAxis.pixelMin + yAxis.labelOffset,
      );
      painter.paint(canvas, loc);
    }

    /// y labels
    for (final (pos, painter) in yLabels) {
      final loc = Offset(
        coordSpace!.xAxis.pixelMin - yAxis.labelOffset - painter.width,
        coordSpace!.yAxis.userToPixel(pos) - painter.height / 2,
      );
      painter.paint(canvas, loc);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    layoutAxes(size);
    paintLabels(canvas);
  }

  @override
  bool shouldRepaint(_DiscreteCartesianGraphPainter<T> oldDelegate) {
    return xAxis != oldDelegate.xAxis || yAxis != oldDelegate.yAxis || data != oldDelegate.data;
  }
}

class DiscreteCartesianGraph extends StatelessWidget {
  final CartesianAxis xAxis;
  final CartesianAxis yAxis;

  const DiscreteCartesianGraph({
    super.key,
    required this.xAxis,
    required this.yAxis,
  });

  @override
  Widget build(BuildContext context) {
    // print(MediaQuery.of(context).devicePixelRatio);
    return RepaintBoundary(
      child: CustomPaint(
        painter: _DiscreteCartesianGraphPainter(
          theme: Theme.of(context),
          xAxis: xAxis,
          yAxis: yAxis,
          data: [testSeries],
        ),
        size: Size.infinite,
      ),
    );
  }
}
