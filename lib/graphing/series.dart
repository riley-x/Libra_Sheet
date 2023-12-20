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

abstract class Series<T> {
  final String name;
  final List<T> data;
  final (double, double) Function(int, T) valueMapper;

  const Series({
    required this.name,
    required this.data,
    required this.valueMapper,
  });

  /// This returns the bounding rectangle of all drawing objects associated with data[i] = x.
  /// The returned BoundingBox is in user coordinates.
  BoundingBox extentMapper(int i, T item) {
    final (x, y) = valueMapper(i, item);
    return BoundingBox(xMin: x, xMax: x, yMin: y, yMax: y);
  }

  void paint(Canvas canvas);
}

final testSeries = LineSeries(
  name: 'test',
  data: [10000.0, 20000.0, 15000.0, -8000.0, -9000.0, 7000.0],
  valueMapper: (i, it) => (i.toDouble(), it),
);

extension SeriesExtension<T> on List<Series<T>> {
  bool hasData() {
    for (final series in this) {
      if (series.data.isNotEmpty) return true;
    }
    return false;
  }
}

class LineSeries<T> extends Series<T> {
  const LineSeries({
    required super.name,
    required super.data,
    required super.valueMapper,
  });

  @override
  void paint(Canvas canvas) {
    // TODO: implement paint
  }
}
