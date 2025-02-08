import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_coordinate_space.dart';
import 'package:libra_sheet/graphing/cartesian/discrete_cartesian_graph.dart';
import 'package:libra_sheet/graphing/series/series.dart';

class ViolinSeriesPoint<T> {
  final int index;
  final T item;
  final double value;
  final Rect pixelPos;

  ViolinSeriesPoint({
    required this.index,
    required this.item,
    required this.value,
    required this.pixelPos,
  });
}

/// A (horizontal) violin series that draws the values as a double sided filled band
/// at a given y offset and maximum height. All values should be positive.
class ViolinSeries<T> extends Series<T> {
  final Color color;

  final double Function(int i, T item) _valueMapper;
  double valueMapper(int i) => _valueMapper(i, data[i]);

  final String Function(int i, T item)? labelMapper;

  /// A user y value to center the series around
  final double height;

  /// Cache the points to enable easy hit testing
  final List<ViolinSeriesPoint<T>> _renderedPoints = [];

  /// If false, will align bars to bottom instead of center
  final bool alignCenter;

  ViolinSeries({
    required super.name,
    required super.data,
    required double Function(int i, T item) valueMapper,
    required this.color,
    required this.height,
    this.labelMapper,
    this.alignCenter = true,
  }) : _valueMapper = valueMapper;

  ViolinSeriesPoint<T> _addPoint(CartesianCoordinateSpace coordSpace, int i) {
    final rect = coordSpace.userToPixelRect(boundingBox(i));
    final out = ViolinSeriesPoint(
      index: i,
      item: data[i],
      value: valueMapper(i),
      pixelPos: Rect.fromLTRB(rect.left + 1, rect.top, rect.right - 1, rect.bottom),
    );
    assert(_renderedPoints.length == i);
    _renderedPoints.add(out);
    return out;
  }

  @override
  void paint(CustomPainter painter, Canvas canvas, CartesianCoordinateSpace coordSpace) {
    /// Points
    _renderedPoints.clear();
    for (int i = 0; i < data.length; i++) {
      _addPoint(coordSpace, i);
    }

    if (_renderedPoints.length < 2) return;

    // /// Top
    // final path = Path();
    // path.moveTo(_renderedPoints.first.pixelPos.center.dx, _renderedPoints.first.pixelPos.top);
    // for (int i = 1; i < _renderedPoints.length; i++) {
    //   final point = _renderedPoints[i];
    //   path.lineTo(point.pixelPos.center.dx, point.pixelPos.top);
    // }

    // /// Bottom
    // for (final point in _renderedPoints.reversed) {
    //   path.lineTo(point.pixelPos.center.dx, point.pixelPos.bottom);
    // }
    // path.close();

    // /// Draw
    // canvas.drawPath(
    //   path,
    //   Paint()
    //     ..style = PaintingStyle.fill
    //     ..color = color,
    // );

    for (final point in _renderedPoints) {
      canvas.drawRect(
          point.pixelPos,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill);
    }
  }

  @override
  BoundingBox boundingBox(int i) {
    final y = valueMapper(i);
    final x = i.toDouble();
    const width = 1.0;
    if (alignCenter) {
      return BoundingBox(
          xMin: x - width / 2, xMax: x + width / 2, yMin: height - y / 2, yMax: height + y / 2);
    } else {
      return BoundingBox(xMin: x - width / 2, xMax: x + width / 2, yMin: height, yMax: height + y);
    }
  }

  @override
  double? hoverValue(int i) {
    final val = valueMapper(i);
    if (val == 0) return null;
    return val;
  }

  @override
  Widget? hoverBuilder(
    BuildContext context,
    int i,
    DiscreteCartesianGraphPainter mainGraph, {
    bool labelOnly = false,
  }) {
    if (i < 0 || i >= _renderedPoints.length) return null;
    final point = _renderedPoints[i];
    if (point.value == 0) return null;

    String label;
    if (labelMapper != null) {
      label = labelMapper!.call(i, data[i]);
    } else {
      label = mainGraph.yAxis.valToString(point.value);
    }

    if (name.isEmpty) {
      return Text(
        mainGraph.yAxis.valToString(point.value),
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10.0,
          height: 10.0,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          "$name: $label",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  @override
  int? hitTest(Offset offset, CartesianCoordinateSpace coordSpace) {
    for (int i = 0; i < _renderedPoints.length; i++) {
      if (_renderedPoints[i].pixelPos.contains(offset)) return i;
    }
    return null;
  }
}
