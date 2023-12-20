import 'dart:math';

import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/cartesian_axes.dart';
import 'package:libra_sheet/graphing/series.dart';

class _DiscreteCartesianGraphPainter<T> extends CustomPainter {
  final CartesianAxes axes;
  final ThemeData theme;
  final List<Series<T>> data;

  /// Variables of a given paint
  Size currentSize = Size.zero;
  late CartesianAxesInternal ax;

  _DiscreteCartesianGraphPainter({
    super.repaint,
    required this.data,
    required this.axes,
    required this.theme,
  });

  /// Lays out the axis with default labels and padding.
  void layoutAxes(Size size) {
    if (size == currentSize) return;

    currentSize = size;
    ax = CartesianAxesInternal(axes: axes, size: size);
    ax.xAxis.defaultAxisPainter
      ..color = theme.colorScheme.onBackground
      ..style = PaintingStyle.stroke
      ..isAntiAlias = false; // this is necessary to get the hairline
    ax.yAxis.defaultAxisPainter
      ..color = theme.colorScheme.onBackground
      ..style = PaintingStyle.stroke
      ..isAntiAlias = false;
    ax.xAxis.defaultGridLinePainter
      ..color = theme.colorScheme.outlineVariant
      ..style = PaintingStyle.stroke
      ..isAntiAlias = false;
    ax.yAxis.defaultGridLinePainter
      ..color = theme.colorScheme.outlineVariant
      ..style = PaintingStyle.stroke
      ..isAntiAlias = false;

    ax.xAxis.defaultLabelStyle = theme.textTheme.bodySmall;
    ax.yAxis.defaultLabelStyle = theme.textTheme.bodySmall;

    ax.autoRange(data);
    ax.autoLabels();
  }

  @override
  void paint(Canvas canvas, Size size) {
    layoutAxes(size);
    ax.paintGridLines(canvas);
    ax.paintXAxis(canvas);
    ax.paintYAxis(canvas);
  }

  @override
  bool shouldRepaint(_DiscreteCartesianGraphPainter<T> oldDelegate) {
    return axes != oldDelegate.axes || data != oldDelegate.data;
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
    // print(MediaQuery.of(context).devicePixelRatio);
    return RepaintBoundary(
      child: CustomPaint(
        painter: _DiscreteCartesianGraphPainter(
          theme: Theme.of(context),
          axes: axes,
          data: [testSeries],
        ),
        size: Size.infinite,
      ),
    );
  }
}
