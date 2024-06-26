import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_axes.dart';
import 'package:libra_sheet/graphing/series/series.dart';

/// This class handles the user-to-pixel conversions. It is recreated by painter classes on each
/// sizing change. See [CartesianAxis] instead for the user-level interface class.
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
    if (userWidth == 0) return pixelMin + pixelWidth / 2;
    return pixelMin + pixelWidth * ((val - userMin) / userWidth);
  }

  double pixelToUser(double val) {
    if (pixelWidth == 0) return userMin;
    return userMin + userWidth * ((val - pixelMin) / pixelWidth);
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
      userMax: yAxis.max ?? 100,
      canvasSize: canvasSize.height,
      padStart: yAxis.padStart,
      padEnd: yAxis.padEnd,
      labelStyle: yAxis.labelStyle,
    );
    return CartesianCoordinateSpace(xAxis: coordXAxis, yAxis: coordYAxis);
  }

  Rect get canvasSize => Rect.fromLTWH(0, 0, xAxis.canvasSize, yAxis.canvasSize);

  /// Bounding Rect of the data elements (i.e. excluding space for labels), useful for clipping
  /// graphs.
  Rect get dataRect => Rect.fromPoints(
        Offset(xAxis.pixelMin, yAxis.pixelMin),
        Offset(xAxis.pixelMax, yAxis.pixelMax),
      );

  Offset userToPixel(Offset offset) {
    return Offset(
      xAxis.userToPixel(offset.dx),
      yAxis.userToPixel(offset.dy),
    );
  }

  Rect userToPixelRect(BoundingBox pixelPos) {
    // Remember that pixelMax might be > pixelMin for inverted axes.
    final xMin = xAxis.userToPixel(pixelPos.xMin);
    final xMax = xAxis.userToPixel(pixelPos.xMax);
    final yMin = yAxis.userToPixel(pixelPos.yMin);
    final yMax = yAxis.userToPixel(pixelPos.yMax);
    return Rect.fromLTRB(
      math.min(xMin, xMax),
      math.min(yMin, yMax),
      math.max(xMin, xMax),
      math.max(yMin, yMax),
    );
  }

  void autoRange({
    required CartesianAxis xAxis,
    required CartesianAxis yAxis,
    required SeriesCollection data,
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
    for (final series in data.data) {
      final ext = series.totalBoundingBox();
      if (ext == null) continue;
      autoXMin = math.min(autoXMin, ext.xMin);
      autoXMax = math.max(autoXMax, ext.xMax);
      autoYMin = math.min(autoYMin, ext.yMin);
      autoYMax = math.max(autoYMax, ext.yMax);
    }
    if (autoXMin == double.infinity) return;

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

    /// Ensure not empty
    if (autoYMin == autoYMax) {
      if (autoYMax == 0) {
        autoYMax = 100;
      } else {
        autoYMin -= autoYMin.abs() * 0.1;
        autoYMax += autoYMax.abs() * 0.1;
      }
    }
    if (autoXMin == autoXMax) {
      if (autoXMax == 0) {
        autoXMax = 100;
      } else {
        autoXMin -= autoXMin.abs() * 0.1;
        autoXMax += autoXMax.abs() * 0.1;
      }
    }

    /// Set the values
    this.xAxis.userMin = autoXMin;
    this.xAxis.userMax = autoXMax;
    this.yAxis.userMin = autoYMin;
    this.yAxis.userMax = autoYMax;
  }
}
