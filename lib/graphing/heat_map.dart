import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/int_dollar.dart';

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
/// if they are precalculated.
List<Rect> layoutHeatMapGrid<T>({
  required Size size,
  required List<T> data,
  required double Function(T) valueMapper,
  double minSameAxisRatio = 0.6,
  List<double>? reverseCumValues,
}) {
  final cumValues = reverseCumValues ?? reverseCumSum(data, valueMapper);
  final output = <Rect>[];

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
        output.add(rect);
        x += thisWidth;
      }
      return Offset(x, topLeft.dy);
    } else {
      /// y axis is longest
      var y = topLeft.dy;
      for (var i = start; i < end; i++) {
        final thisHeight = height * valueMapper(data[i]) / total;
        final rect = Rect.fromLTWH(topLeft.dx, y, width, thisHeight);
        output.add(rect);
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
        output.add(rect);
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
        output.add(rect);
        y += thisHeight;
      }
      return Offset(topLeft.dx + groupWidth, topLeft.dy);
    }
  }

  /// Lays out a single group with the element at [start] as the seed, then recurses.
  void layoutGroup(int start, Offset topLeft) {
    if (start >= data.length) return;
    final end = getGroupEnd(start);
    if (end == start) return;

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

/// This painter class draw a heat map of values. Each entry is shown as a filled rectangle, where
/// the size of the rectangle is proportional to its value in the series.
///

class HeatMapPainter<T> extends CustomPainter {
  final List<T> data;
  final Color? Function(T)? colorMapper;
  final double Function(T) valueMapper;
  final String Function(T)? labelMapper;

  /// _reverseCumValues[i] = sum(data.values[i:]), with 0 appended at end
  late List<double> _reverseCumValues;

  /// Common brush used to paint all the rectangles
  final Paint _brush;

  /// List of the positions of each entry, in parallel order to [data]. This is replaced every call
  /// to [paint]. Used for hit testing.
  List<Rect> positions = [];

  final TextStyle? textStyle;

  /// The minimum ratio between an entry value and the max value in the current
  /// row/column to align it with the row.
  final double minSameAxisRatio;

  HeatMapPainter(
    this.data, {
    required this.valueMapper,
    this.colorMapper,
    this.labelMapper,
    this.minSameAxisRatio = 0.6,
    bool dataAlreadySorted = false,
    this.textStyle,
  }) : _brush = Paint() {
    /// Sort largest to smallest.
    if (!dataAlreadySorted) {
      this.data.sort((a, b) {
        final diff = valueMapper(b) - valueMapper(a);
        if (diff < 0) {
          return -1;
        } else if (diff == 0) {
          return 0;
        } else {
          return 1;
        }
      });
    }

    /// Calculate cumulative values
    _reverseCumValues = reverseCumSum(data, valueMapper);
  }

  /// Chooses the label text color based on the background color
  /// https://stackoverflow.com/questions/3942878/how-to-decide-font-color-in-white-or-black-depending-on-background-color
  Color _textColor(Color bkg) {
    if (bkg.red * 0.299 + bkg.green * 0.587 + bkg.blue * 0.114 > 186) return Colors.black;
    return Colors.white;
  }

  /// Paints a single entry (rectangle). MAKE SURE this is called in index order, since we simply
  /// append to the [positions] list.
  void _paintEntry(Canvas canvas, int index, Rect rect) {
    _brush.color = colorMapper?.call(data[index]) ?? Colors.teal;
    canvas.drawRect(rect, _brush);
    positions.add(rect);

    /// Draw label
    if (labelMapper != null) {
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: labelMapper!.call(data[index]),
          style: textStyle?.copyWith(color: _textColor(_brush.color)),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final textSize = Offset(textPainter.width, textPainter.height);
      if (textSize.dx < rect.width && textSize.dy < rect.height) {
        textPainter.paint(canvas, rect.center - textSize / 2);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    positions = layoutHeatMapGrid(
      size: size,
      data: data,
      valueMapper: valueMapper,
      minSameAxisRatio: minSameAxisRatio,
      reverseCumValues: _reverseCumValues,
    );
    for (int i = 0; i < data.length; i++) {
      _paintEntry(canvas, i, positions[i]);
    }
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

class HeatMap extends StatefulWidget {
  final Function(Category)? onSelect;

  const HeatMap({super.key, this.onSelect});

  @override
  State<HeatMap> createState() => _HeatMapState();
}

class _HeatMapState extends State<HeatMap> {
  void _onTapUp(HeatMapPainter<MapEntry<Category, int>> painter, TapUpDetails details) {
    if (widget.onSelect == null) return;
    for (int i = 0; i < painter.positions.length; i++) {
      if (painter.positions[i].contains(details.localPosition)) {
        if (i >= painter.data.length) return; // shouldn't happen
        widget.onSelect!(painter.data[i].key);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final painter = HeatMapPainter<MapEntry<Category, int>>(
      testCategoryValues.entries.toList(),
      valueMapper: (it) => it.value.asDollarDouble(),
      colorMapper: (it) => it.key.color,
      labelMapper: (it) => "${it.key.name}\n${it.value.dollarString()}",
      textStyle: Theme.of(context).textTheme.labelLarge,
    );
    return GestureDetector(
      onTapUp: (it) => _onTapUp(painter, it),
      child: CustomPaint(
        painter: painter,
        // foregroundPainter: ,
        size: Size.infinite,
      ),
    );
  }
}

final testCategoryValues = {
  Category(name: 'cat 1', color: Colors.amber): 357000,
  Category(name: 'cat 2', color: Colors.blue): 23000,
  Category(name: 'cat 3', color: Colors.green): 1012200,
  Category(name: 'cat 4', color: Colors.red): 223000,
  Category(name: 'cat 5', color: Colors.purple): 43000,
};
