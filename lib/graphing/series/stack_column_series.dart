import 'dart:math';

import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/series/column_series.dart';
import 'package:libra_sheet/graphing/series/series.dart';

class StackColumnSeries<T> extends ColumnSeries<T> {
  /// This represents the cumulative base value for other StackColumnSeries supplied to a graph.
  /// It is set post-construction by the grapher.
  List<double>? stackBase;

  StackColumnSeries({
    required super.name,
    required super.data,
    required super.valueMapper,
    super.offset,
    super.color,
    super.colorMapper,
  });

  // This is conveniently used to paint too, so no need to update that.
  @override
  BoundingBox boundingBox(int i) {
    final val = valueMapper(i);
    final base = stackBase?.elementAtOrNull(i) ?? 0;
    final x = i.toDouble() + (offset ?? ColumnSeries.defaultOffset);
    final width = this.width ?? ColumnSeries.defaultWidth;
    return BoundingBox(
      xMin: x - width / 2,
      xMax: x + width / 2,
      yMin: min(base, base + val),
      yMax: max(base, base + val),
    );
  }
}

final testStackColumnSeries = [
  StackColumnSeries(
    name: 'test',
    color: Colors.blue,
    data: [10000.0, 20000.0, 15000.0, -8000.0, -9000.001, 7123.45],
    valueMapper: (i, it) => it,
  ),
  StackColumnSeries(
    name: 'test',
    color: Colors.green,
    data: [10000.0, 20000.0, 15000.0, 8000.0, -9000.001, 7123.45],
    valueMapper: (i, it) => it,
  ),
];

void accumulateStackColumnSeries(List<Series> data) {
  Map<int, double> stackColumnPosVals = {};
  Map<int, double> stackColumnNegVals = {};
  for (final series in data) {
    if (series is StackColumnSeries) {
      series.stackBase = [];
      for (int i = 0; i < series.data.length; i++) {
        final val = series.valueMapper(i);
        final agg = (val >= 0) ? stackColumnPosVals : stackColumnNegVals;
        final currBase = agg.putIfAbsent(i, () => 0);
        series.stackBase!.add(currBase);
        agg[i] = agg[i]! + val;
      }
    }
  }
}
