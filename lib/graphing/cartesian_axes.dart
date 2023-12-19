import 'dart:ui';

import 'package:flutter/material.dart';

class CartesianAxes {
  /// These are the user coordiantes that define the axis limits. If null, will be auto set.
  final double? xMin;
  final double? xMax;
  final double? yMin;
  final double? yMax;

  /// Axis crossing locations; xAxisLoc is user y coordinate. Use double.infinity for bottom/top/left/right.
  final double xAxisLoc;
  final double yAxisLoc;

  /// Padding to add around the data in pixels. If null, default padding will be used.
  final double? padLeft;
  final double? padRight;
  final double? padTop;
  final double? padBottom;

  /// Label position and text. If null, will be auto created.
  final Iterable<(double, String)>? xLabels;
  final Iterable<(double, String)>? yLabels;

  /// Style of the actual axis lines.
  final Paint? xAxisPainter;
  final Paint? yAxisPainter;

  const CartesianAxes({
    this.xMin,
    this.xMax,
    this.yMin,
    this.yMax,
    this.xAxisLoc = double.negativeInfinity,
    this.yAxisLoc = double.negativeInfinity,
    this.padLeft,
    this.padRight,
    this.padTop,
    this.padBottom,
    this.xLabels,
    this.yLabels,
    this.xAxisPainter,
    this.yAxisPainter,
  });
}

/// Same fields as above but non-null
class CartesianAxesInternal {
  /// These are the user coordiantes that define the axis limits. If null, will be auto set.
  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;

  /// Axis crossing locations; xAxisLoc is user y coordinate. Use double.infinity for bottom/top/left/right.
  late final double xAxisLoc;
  late final double yAxisLoc;

  /// Padding to add around the data in pixels. If null, default padding will be used.
  final double padLeft;
  final double padRight;
  final double padTop;
  final double padBottom;

  /// Label position and text. If null, will be auto created.
  final Iterable<(double, String)> xLabels;
  final Iterable<(double, String)> yLabels;

  /// Style of the actual axis lines.
  late final Paint xAxisPainter;
  late final Paint yAxisPainter;

  /// Will copy fields from [axes] but with optional overrides.
  CartesianAxesInternal(
    BuildContext context,
    CartesianAxes axes, {
    double? xMin,
    double? xMax,
    double? yMin,
    double? yMax,
    double? xAxisLoc,
    double? yAxisLoc,
    double? padLeft,
    double? padRight,
    double? padTop,
    double? padBottom,
    Iterable<(double, String)>? xLabels,
    Iterable<(double, String)>? yLabels,
    Paint? xAxisPainter,
    Paint? yAxisPainter,
  })  : xMin = xMin ?? axes.xMin ?? 0,
        xMax = xMax ?? axes.xMax ?? 1,
        yMin = yMin ?? axes.yMin ?? 0,
        yMax = yMax ?? axes.yMax ?? 1,
        padLeft = padLeft ?? axes.padLeft ?? 0,
        padRight = padRight ?? axes.padRight ?? 0,
        padTop = padTop ?? axes.padTop ?? 0,
        padBottom = padBottom ?? axes.padBottom ?? 0,
        xLabels = xLabels ?? axes.xLabels ?? [],
        yLabels = yLabels ?? axes.yLabels ?? [] {
    final xLoc = xAxisLoc ?? axes.xAxisLoc;
    if (xLoc == double.infinity) {
      this.xAxisLoc = this.yMax;
    } else if (xLoc == double.negativeInfinity) {
      this.xAxisLoc = this.yMin;
    } else {
      this.xAxisLoc = xLoc;
    }

    final yLoc = yAxisLoc ?? axes.yAxisLoc;
    if (yLoc == double.infinity) {
      this.yAxisLoc = this.xMax;
    } else if (yLoc == double.negativeInfinity) {
      this.yAxisLoc = this.xMin;
    } else {
      this.yAxisLoc = yLoc;
    }

    final xPainter = xAxisPainter ?? axes.xAxisPainter;
    if (xPainter != null) {
      this.xAxisPainter = xPainter;
    } else {
      this.xAxisPainter = Paint()..color = Theme.of(context).colorScheme.onSurface;
    }

    final yPainter = yAxisPainter ?? axes.yAxisPainter;
    if (yPainter != null) {
      this.yAxisPainter = yPainter;
    } else {
      this.yAxisPainter = Paint()..color = Theme.of(context).colorScheme.onSurface;
    }
  }

  double userToPixelX(double x, Size size) {
    final pixelStart = padLeft;
    final pixelEnd = size.width - padRight;
    final pixelWidth = pixelEnd - pixelStart;

    final userStart = xMin;
    final userEnd = xMax;
    final userWidth = userEnd - userStart;
    return pixelStart + pixelWidth * (x - userStart) / userWidth;
  }

  double userToPixelY(double y, Size size) {
    /// Remember pixel y = 0 is the top. So [pixelHeight] is negative.
    final pixelStart = size.height - padBottom;
    final pixelEnd = padTop;
    final pixelHeight = pixelEnd - pixelStart;

    final userStart = yMin;
    final userEnd = yMax;
    final userHeight = userEnd - userStart;
    return pixelStart + pixelHeight * (y - userStart) / userHeight;
  }
}
