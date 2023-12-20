import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/series.dart';

class CartesianAxis {
  /// These are the user coordiantes that define the axis limits. If null, will be auto set to contain
  /// all data. See also [dataPadFrac].
  final double? min;
  final double? max;

  /// Optional padding to the auto-determined [min]/[max] values when they are null above. This should
  /// be a fraction of the total width/height. I.e. a value of 0.05 will reserve 5% of the graph
  /// space on each side for empty space.
  final double dataPadFrac;

  /// Axis crossing locations; for an x-axis this is the user y coordinate. Use double.infinity for
  /// bottom/top/left/right.
  final double axisLoc;

  /// Padding to add around the axes in pixels. start/end are always the left/right or bottom/top.
  /// If null, default padding will be used. These should generally be used for reserving space for
  /// the axis labels / titles.
  final double? padStart;
  final double? padEnd;

  /// Label position and text. If null, will be auto created.
  final List<(double, String)>? labels;

  /// Label offset in pixels from the start of the plot area.
  final double labelOffset;

  /// Text style for the labels.
  final TextStyle? labelStyle;

  /// Grid line positions. If null, will be where the [labels] are.
  final List<double>? gridLines;

  /// Style of the main axis line.
  final Paint? axisPainter;

  /// Style of the grid lines.
  final Paint? gridLinePainter;

  const CartesianAxis({
    this.min,
    this.max,
    this.dataPadFrac = 0,
    this.axisLoc = double.negativeInfinity,
    this.padStart,
    this.padEnd,
    this.labels,
    this.labelOffset = 6,
    this.labelStyle,
    this.gridLines,
    this.axisPainter,
    this.gridLinePainter,
  });
}

class CartesianAxes {
  final CartesianAxis xAxis;
  final CartesianAxis yAxis;

  CartesianAxes({
    this.xAxis = const CartesianAxis(),
    this.yAxis = const CartesianAxis(),
  });
}

class CartesianAxisInternal {
  /// The original axis. External methods should avoid touching this member and use the below ones
  /// instead.
  final CartesianAxis axis;

  /// This is the total pixel size of the canvas in this axis direction
  final double size;

  /// Invert the direction of the data. For y axes, this should be true by default because y = 0
  /// represents the top of the screen.
  final bool invert;

  CartesianAxisInternal({
    required this.axis,
    required this.size,
    required this.invert,
  }) {
    setLabels(axis.labels ?? []);
  }

  /// Auto-determined values when the user supplied ones are null. TODO can these be privated?
  double autoMin = 0;
  double autoMax = 1;
  double autoPadStart = 0;
  double autoPadEnd = 0;

  Paint defaultAxisPainter = Paint();
  Paint defaultGridLinePainter = Paint();
  TextStyle? defaultLabelStyle;

  /// These are the user coordiantes that define the axis limits.
  double get userMin => axis.min ?? autoMin;
  double get userMax => axis.max ?? autoMax;

  /// Axis crossing locations; for an x-axis this is the user y coordinate. Is double.infinity for
  /// bottom/top/left/right.
  double get axisUserLoc => axis.axisLoc;

  /// Labels after being laid out. Position is still in user coordinates.
  List<(double, TextPainter)> labels = [];
  double maxLabelWidth = 0;

  /// Gridline positions in user coordinates.
  List<double> get gridLines {
    if (axis.gridLines != null) return axis.gridLines!;
    return [for (final (pos, _) in labels) pos];
  }

  /// Padding to add around the axis in pixels. start/end are always the left/right or bottom/top.
  double get padStart => axis.padStart ?? autoPadStart;
  double get padEnd => axis.padEnd ?? autoPadEnd;

  /// Pixel coordinates corresponding to user min/max above
  double get pixelMin => invert ? size - padStart : padStart;
  double get pixelMax => invert ? padEnd : size - padEnd;

  /// Label offset in pixels from the start of the plot area.
  double get labelOffset => axis.labelOffset;

  /// Text style for the labels.
  TextStyle? get labelStyle => axis.labelStyle ?? defaultLabelStyle;

  /// Style of the main axis line.
  Paint get axisPainter => axis.axisPainter ?? defaultAxisPainter;

  /// Style of the grid lines.
  Paint get gridLinePainter => axis.gridLinePainter ?? defaultGridLinePainter;

  double userToPixel(double val) {
    if (val == double.infinity) return pixelMax;
    if (val == double.negativeInfinity) return pixelMin;
    final userWidth = userMax - userMin;
    final pixelWidth = pixelMax - pixelMin;
    return pixelMin + pixelWidth * (val - userMin) / userWidth;
  }

  void setLabels(List<(double, String)> labels) {
    maxLabelWidth = 0.0;
    this.labels = [];

    for (final (pos, text) in labels) {
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: labelStyle,
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      maxLabelWidth = max(maxLabelWidth, textPainter.width);
      this.labels.add((pos, textPainter));
    }
  }
}

class CartesianAxesInternal {
  CartesianAxisInternal xAxis;
  CartesianAxisInternal yAxis;

  CartesianAxesInternal({
    required CartesianAxes axes,
    required Size size,
  })  : xAxis = CartesianAxisInternal(axis: axes.xAxis, size: size.width, invert: false),
        yAxis = CartesianAxisInternal(axis: axes.yAxis, size: size.height, invert: true);

  void autoRange<T>(List<Series<T>> data) {
    if (!data.hasData()) return;
    if (!(xAxis.axis.min == null ||
        xAxis.axis.max == null ||
        yAxis.axis.min == null ||
        yAxis.axis.max == null)) return;

    xAxis.autoMin = double.infinity;
    yAxis.autoMin = double.infinity;
    xAxis.autoMax = double.negativeInfinity;
    yAxis.autoMax = double.negativeInfinity;
    for (final series in data) {
      for (int i = 0; i < series.data.length; i++) {
        final ext = series.extentMapper(i, series.data[i]);
        xAxis.autoMin = min(xAxis.autoMin, ext.xMin);
        xAxis.autoMax = max(xAxis.autoMax, ext.xMax);
        yAxis.autoMin = min(yAxis.autoMin, ext.yMin);
        yAxis.autoMax = max(yAxis.autoMax, ext.yMax);
      }
    }

    /// Add padding
    final xPad = (xAxis.userMax - xAxis.userMin) * xAxis.axis.dataPadFrac;
    final yPad = (yAxis.userMax - yAxis.userMin) * yAxis.axis.dataPadFrac;
    xAxis.autoMin -= xPad;
    xAxis.autoMax += xPad;
    yAxis.autoMin -= yPad;
    yAxis.autoMax += yPad;
  }

  //---------------------------------------------------------------------------
  // Painters
  //---------------------------------------------------------------------------
  void paintGridLines(Canvas canvas) {
    /// Horizontal grid lines
    for (final pos in yAxis.gridLines) {
      if (pos == xAxis.axisUserLoc) continue;
      double y = yAxis.userToPixel(pos);
      double x1 = xAxis.pixelMin;
      double x2 = xAxis.pixelMax;
      canvas.drawLine(Offset(x1, y), Offset(x2, y), yAxis.gridLinePainter);
    }

    /// Vertical grid lines
    for (final pos in xAxis.gridLines) {
      if (pos == yAxis.axisUserLoc) continue;
      double x = xAxis.userToPixel(pos);
      double y1 = yAxis.pixelMin;
      double y2 = yAxis.pixelMax;
      canvas.drawLine(Offset(x, y1), Offset(x, y2), xAxis.gridLinePainter);
    }
  }

  void paintXAxis(Canvas canvas) {
    double x1 = xAxis.pixelMin;
    double x2 = xAxis.pixelMax;
    double y = yAxis.userToPixel(xAxis.axisUserLoc);
    canvas.drawLine(Offset(x1, y), Offset(x2, y), xAxis.axisPainter);

    final Path path = Path();
    path.moveTo(x1, y);
    path.lineTo(x2, y);
    canvas.drawPath(path, xAxis.axisPainter);

    for (final (pos, painter) in xAxis.labels) {
      /// TODO this only works for bottom aligned labels
      final loc = Offset(
        xAxis.userToPixel(pos) - painter.width / 2,
        yAxis.pixelMin + yAxis.labelOffset,
      );
      painter.paint(canvas, loc);
    }
  }

  void paintYAxis(Canvas canvas) {
    double y1 = yAxis.pixelMin;
    double y2 = yAxis.pixelMax;
    double x = xAxis.userToPixel(yAxis.axisUserLoc);
    canvas.drawLine(Offset(x, y1), Offset(x, y2), yAxis.axisPainter);

    for (final (pos, painter) in yAxis.labels) {
      /// TODO this only works for left aligned labels
      final loc = Offset(
        xAxis.pixelMin - yAxis.labelOffset - painter.width,
        yAxis.userToPixel(pos) - painter.height / 2,
      );
      painter.paint(canvas, loc);
    }
  }
}
