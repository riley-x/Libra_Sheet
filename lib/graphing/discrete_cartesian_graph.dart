import 'dart:math';

import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/cartesian_axes.dart';
import 'package:libra_sheet/graphing/series.dart';

class _DiscreteCartesianGraphPainter<T> extends CustomPainter {
  final CartesianAxes axes;
  final ThemeData theme;
  final List<Series<T>> data;

  final Paint defaultAxisPainter = Paint();

  final TextStyle? defaultLabelStyle;
  late final double labelLineHeight;

  /// Variables of a given paint
  Size _paintSize = Size.zero;
  late CartesianAxesInternal ax;

  _DiscreteCartesianGraphPainter({
    super.repaint,
    required this.data,
    required this.axes,
    required this.theme,
  }) : defaultLabelStyle = theme.textTheme.bodySmall {
    final textPainter = TextPainter(
      text: TextSpan(text: 'Tg!`', style: axes.xAxis.labelStyle ?? defaultLabelStyle),
    );
    labelLineHeight = textPainter.preferredLineHeight;

    defaultAxisPainter..color = theme.colorScheme.onBackground;
  }

  /// Lays out the axis with default labels and padding.
  void layoutAxes(Size size) {
    ax = CartesianAxesInternal(axes: axes, size: size);
    ax.xAxis.defaultAxisPainter
      ..color = theme.colorScheme.onBackground
      ..style = PaintingStyle.stroke
      ..isAntiAlias = false; // this is necessary to get the hairline
    ax.yAxis.defaultAxisPainter
      ..style = PaintingStyle.stroke
      ..color = theme.colorScheme.onBackground;
    ax.xAxis.defaultGridLinePainter
      ..color = theme.colorScheme.outlineVariant
      ..style = PaintingStyle.stroke
      ..isAntiAlias = false;
    ax.yAxis.defaultGridLinePainter
      ..color = theme.colorScheme.outlineVariant
      ..style = PaintingStyle.stroke
      ..isAntiAlias = false;

    ax.xAxis.defaultLabelStyle = defaultLabelStyle;
    ax.yAxis.defaultLabelStyle = defaultLabelStyle;

    ax.autoRange(data);

    /// Axis labels. Do y labels first because these will affect the width available for the x labels,
    /// whereas the x labels generally are just a single line.
    /// TODO this only works for bottom and left aligned labels
    ax.yAxis.autoPadStart = labelLineHeight + ax.xAxis.labelOffset;
    if (axes.yAxis.labels == null) {
      final labels = [(100.0, 'testest'), (200.0, '200'), (-60.0, 'asdfasdf')];
      ax.yAxis.setLabels(labels);
    }

    ax.xAxis.autoPadStart = axes.xAxis.padStart ?? ax.yAxis.maxLabelWidth + axes.xAxis.labelOffset;
    if (axes.xAxis.labels == null) {
      final labels = [(0.0, '0'), (1.0, 'testest'), (2.0, '200'), (3.0, 'asdfasdf')];
      ax.xAxis.setLabels(labels);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintSize = size;
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
