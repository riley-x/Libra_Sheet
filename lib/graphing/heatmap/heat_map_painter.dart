import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/heatmap/heat_map_layout.dart';
import 'package:libra_sheet/theme/colorscheme.dart';

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

  /// Indexes into [data] of where the group boundaries are. Calculated in the constructor.
  /// TODO expand to nestedData too?
  List<int> groupEdges = [];

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
    groupEdges = groupValues([for (final x in this.data) valueMapper(x, 0)], minSameAxisRatio);
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
      groups: (seriesDepth == 0) ? groupEdges : null,
      rect: rect,
      data: [for (final x in seriesData) valueMapper(x, seriesDepth)],
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
