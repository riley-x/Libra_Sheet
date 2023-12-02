import 'dart:math';

import 'package:flutter/material.dart';
import 'package:libra_sheet/theme/colorscheme.dart';

/// Finds the reverse cumulative sum of [data].
/// `out[i] = sum(data.values[i:])` with 0 appended at the end.
List<double> reverseCumSum<T>(List<T> data, double Function(T) valueMapper) {
  final out = <double>[0];
  for (var i = data.length - 1; i >= 0; i--) {
    final val = valueMapper(data[i]);
    out.insert(0, val + out.first);
  }
  return out;
}

/// Returns a list of [Rect] positions for a heatmap. Each entry in [data] is given a rectangular
/// region proportional to its value from [valueMapper].
///
/// The algorithm first collects entries into groups. The first group is created by selecting the
/// largest element, then adding every element with value / seedValue > [minSameAxisRatio]. Then the
/// next group is created by using the next largest element as the seed.
///
/// Each group is laid out along the same axis. When the remaining sum of the other groups is smaller
/// than the sum of the current group, the group is laid out along the larger axis, and uses the
/// full width of the cross axis. In the opposite case, the group is laid out along the full length
/// of the smaller axis.
///
/// [data] should be sorted by decreasing value already. You can optionally pass in [reverseCumValues]
/// if they are precalculated. Values should all be positive.
///
/// [padding] is the amount of pixel padding to space between the boxes. It is a dumb padding that
/// simply removes space from the interior sides of each rectangle. As such for large values of
/// padding, the visible areas of the rectangles won't exactly be proportional to each side.
List<Rect> layoutHeatMapGrid<T>({
  Offset offset = Offset.zero,
  required Size size,
  required List<T> data,
  required double Function(T) valueMapper,
  double minSameAxisRatio = 0.6,
  double padding = 0,
  double paddingX = 0,
  double paddingY = 0,
  List<double>? reverseCumValues,
}) {
  if (data.isEmpty) return [];
  if (padding != 0) {
    paddingX = padding;
    paddingY = padding;
  }
  final output = <Rect>[];
  final cumValues = reverseCumValues ?? reverseCumSum(data, valueMapper);

  bool aprEq(double x, double y) {
    return (x - y).abs() < 1;
  }

  /// The min/max here make sure the padding doesn't cause the Rect to have negative size
  void add(Rect rect) {
    output.add(Rect.fromLTRB(
      offset.dx + ((rect.left == 0) ? 0 : min(rect.left + paddingX, rect.center.dx)),
      offset.dy + ((rect.top == 0) ? 0 : min(rect.top + paddingY, rect.center.dy)),
      offset.dx +
          ((aprEq(rect.right, size.width))
              ? rect.right
              : max(rect.right - paddingX, rect.center.dx)),
      offset.dy +
          ((aprEq(rect.bottom, size.height))
              ? rect.bottom
              : max(rect.bottom - paddingY, rect.center.dy)),
    ));
  }

  /// Returns the end index (exclusive) of the entry last large enough to be in the same as
  /// [start]. Assumes [data] is sorted by decreasing value.
  int getGroupEnd(int start) {
    final valStart = valueMapper(data[start]);
    var end = start + 1;
    while (end < data.length) {
      final val = valueMapper(data[end]);
      if (val < minSameAxisRatio * valStart) return end;
      end++;
    }
    return end;
  }

  /// Lays out a group indexed by [start, end) along the larger axis. The boxes will use the full
  /// width of the cross axis.
  Offset layoutGroupAlongLargeAxis(int start, int end, Offset topLeft) {
    final total = cumValues[start];
    final width = size.width - topLeft.dx;
    final height = size.height - topLeft.dy;

    if (width >= height) {
      /// x axis is longest
      var x = topLeft.dx;
      for (var i = start; i < end; i++) {
        final thisWidth = width * valueMapper(data[i]) / total;
        final rect = Rect.fromLTWH(x, topLeft.dy, thisWidth, height);
        add(rect);
        x += thisWidth;
      }
      return Offset(x, topLeft.dy);
    } else {
      /// y axis is longest
      var y = topLeft.dy;
      for (var i = start; i < end; i++) {
        final thisHeight = height * valueMapper(data[i]) / total;
        final rect = Rect.fromLTWH(topLeft.dx, y, width, thisHeight);
        add(rect);
        y += thisHeight;
      }
      return Offset(topLeft.dx, y);
    }
  }

  /// Lays out a group indexed by [start, end) along the smaller axis. The boxes will use the full
  /// length of the small axis.
  Offset layoutGroupAlongSmallAxis(int start, int end, Offset topLeft) {
    final total = cumValues[start];
    final groupTotal = total - cumValues[end];
    final width = size.width - topLeft.dx;
    final height = size.height - topLeft.dy;

    if (width <= height) {
      /// x axis is shorter
      final groupHeight = height * groupTotal / total;
      var x = topLeft.dx;
      for (var i = start; i < end; i++) {
        final thisWidth = width * valueMapper(data[i]) / groupTotal;
        final rect = Rect.fromLTWH(x, topLeft.dy, thisWidth, groupHeight);
        add(rect);
        x += thisWidth;
      }
      return Offset(topLeft.dx, topLeft.dy + groupHeight);
    } else {
      /// y axis is shorter
      final groupWidth = width * groupTotal / total;
      var y = topLeft.dy;
      for (var i = start; i < end; i++) {
        final thisHeight = height * valueMapper(data[i]) / groupTotal;
        final rect = Rect.fromLTWH(topLeft.dx, y, groupWidth, thisHeight);
        add(rect);
        y += thisHeight;
      }
      return Offset(topLeft.dx + groupWidth, topLeft.dy);
    }
  }

  /// Lays out a single group with the element at [start] as the seed, then recurses.
  void layoutGroup(int start, Offset topLeft) {
    if (start >= data.length) return;
    final end = getGroupEnd(start);

    final remainingTotal = cumValues[end];
    final groupTotal = cumValues[start] - remainingTotal;
    late Offset newTopLeft;
    if (groupTotal > remainingTotal) {
      newTopLeft = layoutGroupAlongLargeAxis(start, end, topLeft);
    } else {
      newTopLeft = layoutGroupAlongSmallAxis(start, end, topLeft);
    }
    layoutGroup(end, newTopLeft);
  }

  layoutGroup(0, Offset.zero);
  assert(output.length == data.length);
  return output;
}

/// This painter class draw a heat map of values obtained from [valueMapper]. See [layoutHeatMapGrid].
/// This class will strip non-positive entries.
///
/// This class can recurse to an arbitrary depth: after laying out the first pass from [data], it
/// goes through each entry and checks [nestedData]. If the returned list is null or empty, it
/// simply paints that rectangle using [colorMapper] and [labelMapper]. But if the list is not empty,
/// the painter then repeats [layoutHeatMapGrid] in the entry's rectangle with the new list. The next
/// pass will have depth += 1. Note that the nested data's values do not have to sum to the parent,
/// and depth starts at 0.
class HeatMapPainter<T> extends CustomPainter {
  late final List<T> data;
  final Color? Function(T, int depth)? colorMapper;
  final double Function(T, int depth) valueMapper;
  final String Function(T, int depth)? labelMapper;
  final List<T>? Function(T, int depth)? nestedData;

  final TextStyle? textStyle;

  /// The minimum ratio between an entry value and the max value in the current
  /// row/column to align it with the row.
  final double minSameAxisRatio;

  /// The pixel (width, height) of the border around each rectangle, indexed by the series depth.
  late final (double, double) Function(int depth) paddingMapper;

  /// Position of each entry, used for hit testing. This is replaced every call to [paint].
  List<(Rect, T)> positions = [];

  HeatMapPainter(
    List<T> data, {
    required this.valueMapper,
    this.colorMapper,
    this.labelMapper,
    this.nestedData,
    double padding = 0,
    double paddingX = 0,
    double paddingY = 0,
    (double, double) Function(int depth)? paddingMapper,
    this.minSameAxisRatio = 0.6,
    this.textStyle,
  }) {
    if (paddingMapper != null) {
      this.paddingMapper = paddingMapper;
    } else if (padding != 0) {
      this.paddingMapper = (_) => (padding, padding);
    } else {
      this.paddingMapper = (_) => (paddingX, paddingY);
    }

    this.data = _sortAndFilterData(data, 0)!;
  }

  List<T>? _sortAndFilterData(List<T>? orig, int depth) {
    if (orig == null) return null;
    var out = orig.where((it) => valueMapper(it, depth) > 0).toList();
    out.sort((a, b) {
      final diff = valueMapper(b, depth) - valueMapper(a, depth);
      if (diff < 0) {
        return -1;
      } else if (diff == 0) {
        return 0;
      } else {
        return 1;
      }
    });
    return out;
  }

  /// Paints a single entry (rectangle).
  void _paintEntry(T entry, int seriesDepth, Canvas canvas, Rect rect) {
    Paint brush = Paint()..color = colorMapper?.call(entry, seriesDepth) ?? Colors.transparent;
    canvas.drawRect(rect, brush);
    positions.add((rect, entry));

    /// Draw label
    if (labelMapper != null) {
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: labelMapper!.call(entry, seriesDepth),
          style: textStyle?.copyWith(color: adaptiveTextColor(brush.color)),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: rect.width);
      final textSize = Offset(textPainter.width, textPainter.height);
      if (textSize.dx < rect.width && textSize.dy < rect.height) {
        textPainter.paint(canvas, rect.center - textSize / 2);
      }
    }
  }

  /// Paints a single series in the given [rect].
  void _paintSeries(List<T> seriesData, int seriesDepth, Canvas canvas, Rect rect) {
    final padding = paddingMapper(seriesDepth);
    final positions = layoutHeatMapGrid(
      offset: rect.topLeft,
      size: rect.size,
      data: seriesData,
      valueMapper: (it) => valueMapper(it, seriesDepth),
      minSameAxisRatio: minSameAxisRatio,
      paddingX: padding.$1,
      paddingY: padding.$2,
    );
    for (int i = 0; i < seriesData.length; i++) {
      var childData = nestedData?.call(seriesData[i], seriesDepth);
      childData = _sortAndFilterData(childData, seriesDepth + 1);
      // must filter before checking the next condition
      if (childData != null && childData.isNotEmpty) {
        _paintSeries(childData, seriesDepth + 1, canvas, positions[i]);
      } else {
        _paintEntry(seriesData[i], seriesDepth, canvas, positions[i]);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    positions.clear();
    _paintSeries(data, 0, canvas, Offset.zero & size);
  }

  @override
  bool shouldRepaint(HeatMapPainter<T> oldDelegate) {
    return data != oldDelegate.data ||
        colorMapper != oldDelegate.colorMapper ||
        valueMapper != oldDelegate.valueMapper ||
        labelMapper != oldDelegate.labelMapper;
  }

  @override
  bool hitTest(Offset position) {
    return true;
  }
}
