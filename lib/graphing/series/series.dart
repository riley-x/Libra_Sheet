import 'dart:math';

import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/cartesian_coordinate_space.dart';

class BoundingBox {
  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;

  const BoundingBox({
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
  });

  BoundingBox.fromPoint(Offset point)
      : xMin = point.dx,
        xMax = point.dx,
        yMin = point.dy,
        yMax = point.dy;

  static const infinite = BoundingBox(
    xMin: double.negativeInfinity,
    xMax: double.infinity,
    yMin: double.negativeInfinity,
    yMax: double.infinity,
  );

  bool isInfinite() =>
      xMin == double.negativeInfinity ||
      xMax == double.infinity ||
      yMin == double.negativeInfinity ||
      yMax == double.infinity;
}

/// An abstract class representing information for a data series in a graph.
abstract class Series<T> {
  final String name;
  final List<T> data;

  const Series({
    required this.name,
    required this.data,
  });

  void paint(Canvas canvas, CartesianCoordinateSpace coordSpace);

  /// This returns the bounding rectangle of all drawing objects associated with data[i] = x.
  /// The returned BoundingBox is in user coordinates.
  BoundingBox? boundingBox(int i);

  /// This returns the bounding rectangle of all drawing objects associated with this series.
  /// The returned BoundingBox is in user coordinates.
  BoundingBox? totalBoundingBox() {
    if (data.isEmpty) return null;

    var xMin = double.infinity;
    var yMin = double.infinity;
    var xMax = double.negativeInfinity;
    var yMax = double.negativeInfinity;
    for (int i = 0; i < data.length; i++) {
      final ext = boundingBox(i);
      if (ext == null) continue;
      xMin = min(xMin, ext.xMin);
      xMax = max(xMax, ext.xMax);
      yMin = min(yMin, ext.yMin);
      yMax = max(yMax, ext.yMax);
    }
    if (xMin == double.infinity) return null;
    return BoundingBox(xMin: xMin, xMax: xMax, yMin: yMin, yMax: yMax);
  }
}

extension SeriesExtension<T> on List<Series<T>> {
  bool hasData() {
    for (final series in this) {
      if (series.data.isNotEmpty) return true;
    }
    return false;
  }

  BoundingBox boundingBox() {
    var xMin = double.infinity;
    var yMin = double.infinity;
    var xMax = double.negativeInfinity;
    var yMax = double.negativeInfinity;
    for (final series in this) {
      final ext = series.totalBoundingBox();
      if (ext == null) continue;
      xMin = min(xMin, ext.xMin);
      xMax = max(xMax, ext.xMax);
      yMin = min(yMin, ext.yMin);
      yMax = max(yMax, ext.yMax);
    }
    return BoundingBox(xMin: xMin, xMax: xMax, yMin: yMin, yMax: yMax);
  }
}
