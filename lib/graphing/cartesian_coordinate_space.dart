import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/cartesian_axes.dart';
import 'package:libra_sheet/graphing/series/series.dart';

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

  Offset userToPixel(Offset offset) {
    return Offset(
      xAxis.userToPixel(offset.dx),
      yAxis.userToPixel(offset.dy),
    );
  }

  void autoRange({
    required CartesianAxis xAxis,
    required CartesianAxis yAxis,
    required List<Series> data,
    double defaultXDataPadFrac = 0,
    double defaultYDataPadFrac = 0.05,
  }) {
    if (!data.hasData()) return;
    if (!(xAxis.min == null || xAxis.max == null || yAxis.min == null || yAxis.max == null)) {
      return;
    }

    /// Get min/max
    var autoXMin = double.infinity;
    var autoYMin = double.infinity;
    var autoXMax = double.negativeInfinity;
    var autoYMax = double.negativeInfinity;
    for (final series in data) {
      final ext = series.totalBoundingBox();
      autoXMin = math.min(autoXMin, ext.xMin);
      autoXMax = math.max(autoXMax, ext.xMax);
      autoYMin = math.min(autoYMin, ext.yMin);
      autoYMax = math.max(autoYMax, ext.yMax);
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
    this.xAxis.userMin = autoXMin;
    this.xAxis.userMax = autoXMax;
    this.yAxis.userMin = autoYMin;
    this.yAxis.userMax = autoYMax;
  }
}
