import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/human_readable_double_step.dart';

import 'cartesian_coordinate_space.dart';

String _defaultValToString(double val, [int? order]) {
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

/// This class represents the user configuration of a cartesian axis (i.e. x or y axis). See
/// [CartesianCoordinateAxis] for the graphing class that contains i.e. user-to-pixel conversions.
/// This class is used at Widget-level interfaces, while the latter is recreated by painter classes
/// on each sizing change.
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
  TextStyle? get labelStyle => _labelStyle ?? theme.textTheme.bodySmall;

  /// For hover, default axis labels, etc. Order is a utility value that when not null, indicates
  /// to possibly return a more concise version of the string. For example, the [autoXLabels] and
  /// [autoYLabels] functions set the order to the common exponent (power of ten) that separates
  /// each tick.
  final String Function(double val, [int? order]) valToString;

  /// Grid line positions. If null, will be where the [labels] are.
  final List<double>? gridLines;

  /// Style of the main axis line.
  final Paint? _axisPainter;
  Paint get axisPainter =>
      _axisPainter ??
      (Paint()
        ..color = theme.colorScheme.onSurface
        ..style = PaintingStyle.stroke
        ..isAntiAlias = false);

  /// Style of the grid lines.
  final Paint? _gridLinePainter;
  Paint get gridLinePainter =>
      _gridLinePainter ??
      (Paint()
        ..color = theme.colorScheme.outlineVariant.withAlpha(128)
        ..style = PaintingStyle.stroke
        ..isAntiAlias = false);

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
  /// constrained by width, but will fit the given height constraints in [coordSpace]. Returns a
  /// list of label painters and positions (in user y coordinates), and the step order used.
  (List<(double, TextPainter)>, int?) autoYLabels(CartesianCoordinateSpace coordSpace) {
    if (labels != null) return (layoutLabels(labels!), null);

    /// Get the ideal step size
    final idealTickSeparation = coordSpace.yAxis.labelLineHeight + 30;
    var idealNTicks = coordSpace.yAxis.pixelWidth.abs() / idealTickSeparation;
    if (idealNTicks < 2) idealNTicks = 2;
    final idealStepSize = coordSpace.yAxis.userWidth / idealNTicks;
    if (idealStepSize <= 0) return ([], null);

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
    return (out, humanReadableStep.order);
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
        lastLabelRightPixel = pixelPos + layout.width / 2;
        if (lastLabelRightPixel <= coordSpace.xAxis.canvasSize) {
          out.add((currPos, layout));
        }
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
    final idealTickSeparation = labelWidthEstimate + 40;
    var idealNTicks = coordSpace.xAxis.pixelWidth.abs() / idealTickSeparation;
    if (idealNTicks < 2) idealNTicks = 2;
    final idealStepSize = coordSpace.xAxis.userWidth / idealNTicks;

    /// Start from the nearest human readable step size and iterate up.
    final humanReadableStep = roundToHumanReadable(idealStepSize);
    return _autoXLabels(coordSpace, humanReadableStep);
  }
}
