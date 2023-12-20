import 'package:flutter/material.dart';

class BoundingBox {
  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;

  BoundingBox({
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
  });
}

class Series<T> {
  final String name;
  final List<T> data;
  final (double, double) Function(int, T) valueMapper;
  final BoundingBox Function(int i, T x)? _extentMapper;

  /// This returns the bounding rectangle of all drawing objects associated with data[i] = x.
  /// The returned BoundingBox is in user coordinates.
  BoundingBox extentMapper(int i, T item) {
    if (_extentMapper != null) return _extentMapper!(i, item);
    final (x, y) = valueMapper(i, item);
    return BoundingBox(xMin: x, xMax: x, yMin: y, yMax: y);
  }

  Series({
    required this.name,
    required this.data,
    required this.valueMapper,
    BoundingBox Function(int, T)? extentMapper,
  }) : _extentMapper = extentMapper;
}

final testSeries = Series(
  name: 'test',
  data: [100, 200, 150, -80, -90, 70],
  valueMapper: (i, it) => (i.toDouble(), it.toDouble()),
);

extension SeriesExtension<T> on List<Series<T>> {
  bool hasData() {
    for (final series in this) {
      if (series.data.isNotEmpty) return true;
    }
    return false;
  }
}
