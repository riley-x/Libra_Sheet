import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/auto_y_ticks.dart';
import 'package:libra_sheet/graphing/series.dart';

String _defaultValToString(double val, int order) {
  return "$val";
}

TextPainter layoutText(String text, TextStyle? style) {
  final TextPainter textPainter = TextPainter(
    text: TextSpan(text: text, style: style),
    textAlign: TextAlign.start,
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();
  return textPainter;
}

class CartesianAxis {
  /// Theme used to style the axis. Styles can be fine tuned with some of the below variables.
  final ThemeData theme;

  /// These are the user coordiantes that define the axis limits. If null, will be auto set to contain
  /// all data. See also [dataPadFrac].
  final double? min;
  final double? max;

  /// Optional padding to the auto-determined [min]/[max] values when they are null above. This should
  /// be a fraction of the total width/height. I.e. a value of 0.05 will reserve 5% of the graph
  /// space on each side for empty space.
  final double? dataPadFrac;

  /// Axis crossing locations; for an x-axis this is the user y coordinate. Use double.infinity for
  /// bottom/top/left/right, or null to not draw the axis.
  final double? axisLoc;

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
  final TextStyle? _labelStyle;
  TextStyle? get labelStyle => _labelStyle;

  /// For hover, default axis labels, etc.
  final String Function(double val, int order) valToString;

  /// Grid line positions. If null, will be where the [labels] are.
  final List<double>? gridLines;

  /// Style of the main axis line.
  final Paint? _axisPainter;
  Paint get axisPainter => _axisPainter ?? Paint()
    ..color = theme.colorScheme.onBackground
    ..style = PaintingStyle.stroke
    ..isAntiAlias = false;

  /// Style of the grid lines.
  final Paint? _gridLinePainter;
  Paint get gridLinePainter => _gridLinePainter ?? Paint()
    ..color = theme.colorScheme.outlineVariant
    ..style = PaintingStyle.stroke
    ..isAntiAlias = false;

  const CartesianAxis({
    required this.theme,
    this.min,
    this.max,
    this.dataPadFrac,
    this.axisLoc = double.negativeInfinity,
    this.padStart,
    this.padEnd,
    this.labels,
    this.labelOffset = 6,
    TextStyle? labelStyle,
    this.valToString = _defaultValToString,
    this.gridLines,
    Paint? axisPainter,
    Paint? gridLinePainter,
  })  : _labelStyle = labelStyle,
        _axisPainter = axisPainter,
        _gridLinePainter = gridLinePainter;

  TextPainter layoutLabel(String text) => layoutText(text, labelStyle);

  List<(double, TextPainter)> layoutLabels(List<(double, String)> labels) {
    return [
      for (final (pos, text) in labels) (pos, layoutLabel(text)),
    ];
  }

  /// Creates equally space human-readable labels assuming this is the y-axis. The labels are not
  /// constrained by width, but will fit the given height constraints in [coordSpace].
  List<(double, TextPainter)> autoYLabels(CartesianCoordinateSpace coordSpace) {
    if (labels != null) return layoutLabels(labels!);

    final idealTickSeparation = coordSpace.yAxis.labelLineHeight + 30;
    var idealNTicks = coordSpace.yAxis.pixelWidth.abs() / idealTickSeparation;
    if (idealNTicks < 2) idealNTicks = 2;
    final idealStepSize = coordSpace.yAxis.userWidth / idealNTicks;

    /// Start from the nearest integer multiple of a human readable step size.
    final humanReadableStep = roundToHumanReadable(idealStepSize);
    final stepSize = humanReadableStep.step;
    var currPos = (coordSpace.yAxis.userMin / stepSize).roundToDouble() * stepSize;

    /// Create the labels
    final out = <(double, TextPainter)>[];
    while (currPos <= coordSpace.yAxis.userMax) {
      if (currPos >= coordSpace.yAxis.userMin) {
        out.add((currPos, layoutLabel(valToString(currPos, humanReadableStep.order))));
      }
      currPos += stepSize;
    }
    return out;
  }

  /// Helper function that tries to use [humanReadableStep] to layout the x labels, or recurses to
  /// the next larger step if they overlap.
  List<(double, TextPainter)> _autoXLabels(
    CartesianCoordinateSpace coordSpace,
    HumanReadableDoubleStep humanReadableStep,
  ) {
    final stepSize = humanReadableStep.step;
    var currPos = (coordSpace.xAxis.userMin / stepSize).roundToDouble() * stepSize;
    var lastLabelRightPixel = double.negativeInfinity;

    /// Create the labels
    final out = <(double, TextPainter)>[];
    while (currPos <= coordSpace.xAxis.userMax) {
      if (currPos >= coordSpace.xAxis.userMin) {
        final layout = layoutLabel(valToString(currPos, humanReadableStep.order));
        final pixelPos = coordSpace.xAxis.userToPixel(currPos);
        if (lastLabelRightPixel > pixelPos - layout.width / 2) {
          return _autoXLabels(coordSpace, humanReadableStep.nextLargerStep());
        }
        out.add((currPos, layout));
        lastLabelRightPixel = pixelPos + layout.width / 2;
      }
      currPos += stepSize;
    }
    return out;
  }

  /// Creates equally space human-readable labels assuming this is the x-axis. The labels are assumed
  /// to be single line, and that the horizontal positioning in [coordSpace] is finalized.
  ///
  /// Since the amount of labels is constrained by the width of each label, this
  /// function will iterate until it knows the labels won't overlap. To speed operation, supply an
  /// estimate of the typical width of a label in [labelWidthEstimate]. If null, the function will
  /// use [coordSpace.xAxis.userMin] and [coordSpace.xAxis.userMax] as estimates.
  List<(double, TextPainter)> autoXLabels(
    CartesianCoordinateSpace coordSpace, [
    double? labelWidthEstimate,
  ]) {
    if (labels != null) return layoutLabels(labels!);

    /// Get estimate of label widths if not supplied
    if (labelWidthEstimate == null) {
      final minPainter = layoutLabel(valToString(coordSpace.xAxis.userMin, 0));
      final maxPainter = layoutLabel(valToString(coordSpace.xAxis.userMax, 0));
      labelWidthEstimate = math.max(minPainter.width, maxPainter.width);
    }

    /// Get ideal step size
    final idealTickSeparation = labelWidthEstimate + 30;
    var idealNTicks = coordSpace.xAxis.pixelWidth.abs() / idealTickSeparation;
    if (idealNTicks < 2) idealNTicks = 2;
    final idealStepSize = coordSpace.xAxis.userWidth / idealNTicks;

    /// Start from the nearest human readable step size and iterate up.
    final humanReadableStep = roundToHumanReadable(idealStepSize);
    return _autoXLabels(coordSpace, humanReadableStep);
  }
}

class CartesianCoordinateAxis {
  /// These are the user coordiantes that define the axis limits.
  double userMin;
  double userMax;
  double get userWidth => userMax - userMin;

  /// Pixel extent of the canvas in this axis
  double canvasSize;

  /// Invert the direction of the data. For y axes, this should be true by default because y = 0
  /// represents the top of the screen.
  bool invert;

  /// Padding to add around the axis in pixels. start/end are always the left/right or bottom/top.
  double? padStart;
  double? padEnd;

  /// Pixel coordinates corresponding to user min/max above. Note that when [invert], [pixelMax] is
  /// smaller than [pixelMin].
  double get pixelMin => invert ? canvasSize - (padStart ?? 0) : (padStart ?? 0);
  double get pixelMax => invert ? (padEnd ?? 0) : canvasSize - (padEnd ?? 0);

  /// Note this can be negative for inverted axes. Always add this to [pixelMin], or take abs().
  double get pixelWidth => pixelMax - pixelMin;

  /// Height of one line of label text. Useful for auto determining label positions.
  double labelLineHeight;

  CartesianCoordinateAxis({
    required this.userMin,
    required this.userMax,
    required this.canvasSize,
    required this.invert,
    this.padStart,
    this.padEnd,
    TextStyle? labelStyle,
  }) : labelLineHeight = layoutText('asdf', labelStyle).preferredLineHeight;

  double userToPixel(double val) {
    if (val == double.infinity) return pixelMax;
    if (val == double.negativeInfinity) return pixelMin;
    final userWidth = userMax - userMin;
    final pixelWidth = pixelMax - pixelMin;
    if (userWidth == 0) return pixelMin + pixelWidth / 2;
    return pixelMin + pixelWidth * ((val - userMin) / userWidth);
  }
}

class CartesianCoordinateSpace {
  CartesianCoordinateAxis xAxis;
  CartesianCoordinateAxis yAxis;

  CartesianCoordinateSpace({
    required this.xAxis,
    required this.yAxis,
  });

  factory CartesianCoordinateSpace.fromAxes({
    required Size canvasSize,
    required CartesianAxis xAxis,
    required CartesianAxis yAxis,
  }) {
    final coordXAxis = CartesianCoordinateAxis(
      invert: false,
      userMin: xAxis.min ?? 0,
      userMax: xAxis.max ?? 1,
      canvasSize: canvasSize.width,
      padStart: xAxis.padStart,
      padEnd: xAxis.padEnd,
      labelStyle: xAxis.labelStyle,
    );
    final coordYAxis = CartesianCoordinateAxis(
      invert: true,
      userMin: yAxis.min ?? 0,
      userMax: yAxis.max ?? 1,
      canvasSize: canvasSize.height,
      padStart: yAxis.padStart,
      padEnd: yAxis.padEnd,
      labelStyle: yAxis.labelStyle,
    );
    return CartesianCoordinateSpace(xAxis: coordXAxis, yAxis: coordYAxis);
  }

  factory CartesianCoordinateSpace.autoRange({
    required Size canvasSize,
    required CartesianAxis xAxis,
    required CartesianAxis yAxis,
    required List<Series> data,
    double defaultXDataPadFrac = 0,
    double defaultYDataPadFrac = 0.05,
  }) {
    final coordSpace =
        CartesianCoordinateSpace.fromAxes(canvasSize: canvasSize, xAxis: xAxis, yAxis: yAxis);
    if (!data.hasData()) return coordSpace;
    if (!(xAxis.min == null || xAxis.max == null || yAxis.min == null || yAxis.max == null)) {
      return coordSpace;
    }

    /// Get min/max
    var autoXMin = double.infinity;
    var autoYMin = double.infinity;
    var autoXMax = double.negativeInfinity;
    var autoYMax = double.negativeInfinity;
    for (final series in data) {
      for (int i = 0; i < series.data.length; i++) {
        final ext = series.extentMapper(i, series.data[i]);
        autoXMin = math.min(autoXMin, ext.xMin);
        autoXMax = math.max(autoXMax, ext.xMax);
        autoYMin = math.min(autoYMin, ext.yMin);
        autoYMax = math.max(autoYMax, ext.yMax);
      }
    }

    /// Override auto with user
    autoXMin = xAxis.min ?? autoXMin;
    autoXMax = xAxis.max ?? autoXMax;
    autoYMin = yAxis.min ?? autoYMin;
    autoYMax = yAxis.max ?? autoYMax;

    /// Add range padding
    final xPad = (autoXMax - autoXMin) * (xAxis.dataPadFrac ?? defaultXDataPadFrac);
    final yPad = (autoYMax - autoYMin) * (yAxis.dataPadFrac ?? defaultYDataPadFrac);
    autoXMin = xAxis.min ?? autoXMin - xPad;
    autoXMax = xAxis.max ?? autoXMax + xPad;
    autoYMin = yAxis.min ?? (autoYMin == 0 ? 0 : autoYMin - yPad);
    autoYMax = yAxis.max ?? (autoYMax == 0 ? 0 : autoYMax + yPad);

    /// Set the values
    coordSpace.xAxis.userMin = autoXMin;
    coordSpace.xAxis.userMax = autoXMax;
    coordSpace.yAxis.userMin = autoYMin;
    coordSpace.yAxis.userMax = autoYMax;
    return coordSpace;
  }
}

// class CartesianAxisInternal {
//   /// The original axis. External methods should avoid touching this member and use the below ones
//   /// instead.
//   final CartesianAxis axis;

//   /// This is the total pixel size of the canvas in this axis direction
//   final double size;

//   /// Invert the direction of the data. For y axes, this should be true by default because y = 0
//   /// represents the top of the screen.
//   final bool invert;

//   CartesianAxisInternal({
//     required this.axis,
//     required this.size,
//     required this.invert,
//   }) {
//     setLabels(axis.labels ?? []);
//   }

//   /// Auto-determined values when the user supplied ones are null. TODO can these be privated?
//   double autoMin = 0;
//   double autoMax = 1;
//   double autoPadStart = 0;
//   double autoPadEnd = 0;

//   Paint defaultAxisPainter = Paint();
//   Paint defaultGridLinePainter = Paint();
//   TextStyle? defaultLabelStyle;

//   /// These are the user coordiantes that define the axis limits.
//   double get userMin => axis.min ?? autoMin;
//   double get userMax => axis.max ?? autoMax;

//   /// Axis crossing locations; for an x-axis this is the user y coordinate. Is double.infinity for
//   /// bottom/top/left/right, or null to not draw the axis.
//   double? get axisUserLoc => axis.axisLoc;

//   /// Labels after being laid out. Position is still in user coordinates.
//   List<(double, TextPainter)> labels = [];
//   double maxLabelWidth = 0;

//   /// Gridline positions in user coordinates.
//   List<double> get gridLines {
//     if (axis.gridLines != null) return axis.gridLines!;
//     return [for (final (pos, _) in labels) pos];
//   }

//   /// Padding to add around the axis in pixels. start/end are always the left/right or bottom/top.
//   double get padStart => axis.padStart ?? autoPadStart;
//   double get padEnd => axis.padEnd ?? autoPadEnd;

//   /// Pixel coordinates corresponding to user min/max above. Note that when [invert], [pixelMax] is
//   /// smaller than [pixelMin].
//   double get pixelMin => invert ? size - padStart : padStart;
//   double get pixelMax => invert ? padEnd : size - padEnd;

//   /// Label offset in pixels from the start of the plot area.
//   double get labelOffset => axis.labelOffset;

//   /// Text style for the labels.
//   TextStyle? get labelStyle => axis.labelStyle ?? defaultLabelStyle;

//   /// Style of the main axis line.
//   Paint get axisPainter => axis.axisPainter ?? defaultAxisPainter;

//   /// Style of the grid lines.
//   Paint get gridLinePainter => axis.gridLinePainter ?? defaultGridLinePainter;

//   double userToPixel(double val) {
//     if (val == double.infinity) return pixelMax;
//     if (val == double.negativeInfinity) return pixelMin;
//     final userWidth = userMax - userMin;
//     final pixelWidth = pixelMax - pixelMin;
//     if (userWidth == 0) return pixelMin + pixelWidth / 2;
//     return pixelMin + pixelWidth * (val - userMin) / userWidth;
//   }

//   void setLabels(List<(double, String)> labels) {
//     maxLabelWidth = 0.0;
//     this.labels = [];

//     for (final (pos, text) in labels) {
//       final TextPainter textPainter = TextPainter(
//         text: TextSpan(
//           text: text,
//           style: labelStyle,
//         ),
//         textAlign: TextAlign.center,
//         textDirection: TextDirection.ltr,
//       );
//       textPainter.layout();
//       maxLabelWidth = math.max(maxLabelWidth, textPainter.width);
//       this.labels.add((pos, textPainter));
//     }
//   }
// }

// class CartesianAxesInternal {
//   //---------------------------------------------------------------------------
//   // Painters
//   //---------------------------------------------------------------------------
//   void paintGridLines(Canvas canvas) {
//     /// Horizontal grid lines
//     for (final pos in yAxis.gridLines) {
//       if (pos == xAxis.axisUserLoc) continue;
//       double y = yAxis.userToPixel(pos);
//       double x1 = xAxis.pixelMin;
//       double x2 = xAxis.pixelMax;
//       canvas.drawLine(Offset(x1, y), Offset(x2, y), yAxis.gridLinePainter);
//     }

//     /// Vertical grid lines
//     for (final pos in xAxis.gridLines) {
//       if (pos == yAxis.axisUserLoc) continue;
//       double x = xAxis.userToPixel(pos);
//       double y1 = yAxis.pixelMin;
//       double y2 = yAxis.pixelMax;
//       canvas.drawLine(Offset(x, y1), Offset(x, y2), xAxis.gridLinePainter);
//     }
//   }

//   void paintXAxis(Canvas canvas) {
//     if (xAxis.axisUserLoc != null) {
//       double x1 = xAxis.pixelMin;
//       double x2 = xAxis.pixelMax;
//       double y = yAxis.userToPixel(xAxis.axisUserLoc!);
//       canvas.drawLine(Offset(x1, y), Offset(x2, y), xAxis.axisPainter);
//     }
//   }

//   void paintYAxis(Canvas canvas) {
//     if (yAxis.axisUserLoc != null) {
//       double y1 = yAxis.pixelMin;
//       double y2 = yAxis.pixelMax;
//       double x = xAxis.userToPixel(yAxis.axisUserLoc!);
//       canvas.drawLine(Offset(x, y1), Offset(x, y2), yAxis.axisPainter);
//     }
//   }
// }
