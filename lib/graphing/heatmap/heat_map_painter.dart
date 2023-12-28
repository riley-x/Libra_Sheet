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

class _HeatMapGroup {
  final bool wantsHorizontal;
  final int indexStart;
  int indexEnd;

  _HeatMapGroup({
    required this.wantsHorizontal,
    required this.indexStart,
    required this.indexEnd,
  });
}

class _HeatMapHelper<T> {
  final Rect totalRect;
  final List<T> data;
  final double Function(T) valueMapper;
  final double minSameAxisRatio;
  final double padding;
  double paddingX;
  double paddingY;

  List<double> cumValues = [];
  List<Rect> output = [];

  _HeatMapHelper({
    required this.totalRect,
    required this.data,
    required this.valueMapper,
    required this.minSameAxisRatio,
    required this.padding,
    required this.paddingX,
    required this.paddingY,
  }) {
    if (padding != 0) {
      paddingX = padding;
      paddingY = padding;
    }
    cumValues = reverseCumSum(data, valueMapper);
  }

  bool aprEq(double x, double y) {
    return (x - y).abs() < 1;
  }

  /// The min/max here make sure the padding doesn't cause the Rect to have negative size
  void add(Rect rect) {
    output.add(Rect.fromLTRB(
      (rect.left == totalRect.left) ? rect.left : min(rect.left + paddingX, rect.center.dx),
      (rect.top == totalRect.top) ? rect.top : min(rect.top + paddingY, rect.center.dy),
      (aprEq(rect.right, totalRect.right))
          ? rect.right
          : max(rect.right - paddingX, rect.center.dx),
      (aprEq(rect.bottom, totalRect.bottom))
          ? rect.bottom
          : max(rect.bottom - paddingY, rect.center.dy),
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

  /// Lays out the elements from [start, end) inside [rect] along the larger axis of [rect]. Each
  /// element uses the full cross-axis width. [rect] is fully covered.
  void layoutSideBySide(int start, int end, Rect rect) {
    final total = cumValues[start] - cumValues[end];
    if (rect.width >= rect.height) {
      /// x axis is longest
      var x = rect.topLeft.dx;
      for (var i = start; i < end; i++) {
        final thisWidth = rect.width * valueMapper(data[i]) / total;
        final itemRect = Rect.fromLTWH(x, rect.topLeft.dy, thisWidth, rect.height);
        add(itemRect);
        x += thisWidth;
      }
    } else {
      /// y axis is longest
      var y = rect.topLeft.dy;
      for (var i = start; i < end; i++) {
        final thisHeight = rect.height * valueMapper(data[i]) / total;
        final itemRect = Rect.fromLTWH(rect.topLeft.dx, y, rect.width, thisHeight);
        add(itemRect);
        y += thisHeight;
      }
    }
  }

  /// We want to layout the group given by [start, end) such that each element is as close to square
  /// as possible. We assume that each group entry is approximately the same size.
  void layoutGroupInRect(int start, int end, Rect rect) {
    /// Base cases
    final n = end - start;
    if (n == 1) {
      add(rect);
      return;
    } else if (n == 2) {
      layoutSideBySide(start, end, rect);
      return;
    }

    /// Recursive. Here the variable names assume the longest side is the x axis.
    final affinity = (rect.longestSide / rect.shortestSide).round();
    final nRows = 2;
    print("$start ${data[start]} $n $affinity $nRows");
    if (nRows == 1) {
      /// The rectangle is super long, so just add the elements side by side
      layoutSideBySide(start, end, rect);
    } else if (n % nRows != 0) {
      /// Take leftover from the start (largest elements)
      final leftovers = n % nRows;
      final newRect = layoutGroupAlongLargeAxis(start, start + leftovers, rect);
      layoutGroupInRect(start + leftovers, end, newRect);
    } else {
      final nCols = n ~/ nRows;
      final groupTotal = cumValues[start] - cumValues[end];
      var pos = rect.width > rect.height ? rect.top : rect.left;
      for (int i = start; i < end; i += nCols) {
        final rowTotal = cumValues[i] - cumValues[i + nCols];
        final extent = min(rect.height, rect.width);
        final newPos = pos + extent * rowTotal / groupTotal;
        final rowRect = rect.width > rect.height
            ? Rect.fromLTRB(rect.left, pos, rect.right, newPos)
            : Rect.fromLTRB(pos, rect.top, newPos, rect.bottom);
        layoutSideBySide(i, i + nCols, rowRect);
        pos = newPos;
      }
    }
  }

  /// Lays out a group indexed by [start, end) along the larger axis. The group will use the full
  /// width of the cross axis.
  Rect layoutGroupAlongLargeAxis(int start, int end, Rect rect) {
    final total = cumValues[start];
    final totalGroup = total - cumValues[end];
    if (rect.width >= rect.height) {
      /// x axis is longest
      final newX = rect.left + rect.width * totalGroup / total;
      final groupRect = Rect.fromPoints(rect.topLeft, Offset(newX, rect.bottom));
      layoutGroupInRect(start, end, groupRect);
      return Rect.fromPoints(groupRect.topRight, rect.bottomRight);
    } else {
      /// y axis is longest
      final newY = rect.top + rect.height * totalGroup / total;
      final groupRect = Rect.fromPoints(rect.topLeft, Offset(rect.right, newY));
      layoutGroupInRect(start, end, groupRect);
      return Rect.fromPoints(groupRect.bottomLeft, rect.bottomRight);
    }
  }

  void layout() {
    var start = 0;
    var rect = totalRect;
    while (start < data.length) {
      final end = getGroupEnd(start);
      rect = layoutGroupAlongLargeAxis(start, end, rect);
      start = end;

      // final remainingTotal = cumValues[end];
      // final groupTotal = cumValues[start] - remainingTotal;

      // Offset newTopLeft;
      // if (groupTotal > remainingTotal) {
      //   newTopLeft = layoutGroupAlongLargeAxis(start, end, topLeft);
      // } else {
      //   newTopLeft = layoutGroupAlongSmallAxis(start, end, topLeft);
      // }
    }
  }
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
/// [data] should be sorted by decreasing value already. Values should all be positive.
///
/// [padding] is the amount of pixel padding to space between the boxes. It is a dumb padding that
/// simply removes space from the interior sides of each rectangle. As such for large values of
/// padding, the visible areas of the rectangles won't exactly be proportional to each side.
List<Rect> layoutHeatMapGrid<T>({
  required Rect rect,
  required List<T> data,
  required double Function(T) valueMapper,
  double minSameAxisRatio = 0.6,
  double padding = 0,
  double paddingX = 0,
  double paddingY = 0,
}) {
  if (data.isEmpty) return [];
  final helper = _HeatMapHelper(
    totalRect: rect,
    data: data,
    valueMapper: valueMapper,
    minSameAxisRatio: minSameAxisRatio,
    padding: padding,
    paddingX: paddingX,
    paddingY: paddingY,
  );
  helper.layout();
  assert(helper.output.length == data.length);
  return helper.output;
}

class HeatMapPoint<T> {
  final T item;
  final Rect rect;
  final bool labelDrawn;

  HeatMapPoint({
    required this.item,
    required this.rect,
    required this.labelDrawn,
  });
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

  //-----------------------------------
  // Variables per paint
  //-----------------------------------
  Size currentSize = Size.zero;

  /// Position of each entry, used for hit testing. This is replaced every call to [paint].
  List<HeatMapPoint<T>> positions = [];

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
    this.minSameAxisRatio = 0.8,
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

    /// Draw label
    bool hasLabel = false;
    if (labelMapper != null && rect.width > 50) {
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
      if (textSize.dy < rect.height) {
        textPainter.paint(canvas, rect.center - textSize / 2);
        hasLabel = true;
      }
    }

    positions.add(HeatMapPoint(item: entry, rect: rect, labelDrawn: hasLabel));
  }

  /// Paints a single series in the given [rect].
  void _paintSeries(List<T> seriesData, int seriesDepth, Canvas canvas, Rect rect) {
    final padding = paddingMapper(seriesDepth);
    final positions = layoutHeatMapGrid(
      rect: rect,
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
    currentSize = size;
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

  (int, HeatMapPoint<T>)? hitTestUser(Offset position) {
    for (int i = 0; i < positions.length; i++) {
      if (positions[i].rect.contains(position)) {
        return (i, positions[i]);
      }
    }
    return null;
  }
}
