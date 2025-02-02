import 'dart:math';

import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_coordinate_space.dart';
import 'package:libra_sheet/graphing/cartesian/discrete_cartesian_graph.dart';

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
///
/// Mandatory overrides:
///     [paint]
///     [boundingBox]
///
/// Suggested overrides:
///     [hoverValue] or also [hoverBuilder]
///     [hitTest]
///     [accumulateStack]
abstract class Series<T> {
  final String name;
  final List<T> data;

  const Series({
    required this.name,
    required this.data,
  });

  void paint(CustomPainter painter, Canvas canvas, CartesianCoordinateSpace coordSpace);

  /// This is the value shown when hovering over a data point. The value is formatted by the
  /// corresponding axis. Note if [hoverBuilder] returns not null, it will take precedence, but this
  /// value may still be used, i.e. the [PooledTooltip] which sums entries together.
  ///
  /// TODO this is hardcoded for discrete axes.
  double? hoverValue(int i) => null;

  /// The widget to display when hovering. Make sure you still implement [hoverValue] if you
  /// implement [hoverBuilder].
  ///
  /// TODO this is hardcoded for discrete axes.
  Widget? hoverBuilder(
    BuildContext context,
    int i,
    DiscreteCartesianGraphPainter mainGraph, {
    bool labelOnly = false,
  }) =>
      null;

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

  /// Returns the index of the closest data point to a tap event. [offset] is in pixel coordinates.
  /// Returns null if no hit.
  int? hitTest(Offset offset, CartesianCoordinateSpace coordSpace) => null;

  /// Accumulates stack values into the supplied maps. This is also where relevant storage members
  /// should be set to draw the stack correctly. Returns true if this series added itself to the
  /// stacking logic.
  ///
  /// The key to the maps is the index of each data point, and the value is the current stack value.
  /// TODO to handle independent stacks, could key by tuple with a stack series index.
  /// TODO this assumes all stack series have the same number of data points, in order.
  bool accumulateStack(Map<int, double> posVals, Map<int, double> negVals) => false;
}

class SeriesCollection {
  final List<Series> data;

  /// We want to keep the original order as supplied by the user in [data], which enables callbacks
  /// by the series index. This aux list stores the series in the orer they are painted. Notably,
  /// stack entries are painted in reverse order.
  final List<Series> paintOrder = [];
  bool hasStack = false;

  SeriesCollection(this.data) {
    _accumulateStackSeries();
  }

  void _accumulateStackSeries() {
    Map<int, double> posVals = {};
    Map<int, double> negVals = {};

    final List<Series> stackEntries = [];
    int? firstStackIndex;
    for (final (i, series) in data.indexed) {
      final stack = series.accumulateStack(posVals, negVals);
      if (stack) {
        hasStack = true;
        stackEntries.add(series);
        firstStackIndex ??= i;
      } else {
        paintOrder.add(series);
      }
    }

    if (firstStackIndex != null) {
      paintOrder.insertAll(firstStackIndex, stackEntries.reversed);
    }
  }

  bool hasData() {
    for (final series in data) {
      if (series.data.isNotEmpty) return true;
    }
    return false;
  }

  BoundingBox boundingBox() {
    var xMin = double.infinity;
    var yMin = double.infinity;
    var xMax = double.negativeInfinity;
    var yMax = double.negativeInfinity;
    for (final series in data) {
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
