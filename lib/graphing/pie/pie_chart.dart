import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final _defaultColors = [
  Colors.blue,
  Colors.orange,
  Colors.green,
  Colors.red,
  Colors.brown,
  Colors.cyan,
  Colors.purple,
  Colors.lime,
  Colors.blueGrey,
  Colors.pink,
  Colors.teal,
  Colors.indigo,
];

class PieChartPainter<T> extends CustomPainter {
  final ThemeData theme;
  final int? hoverLoc;
  final List<Color> colors;
  final List<TextPainter> labels;
  final TextPainter? defaultLabel;
  final List<double> startAngles; // radians
  final List<double> sweepAngles; // radians

  /// Variables of a given paint
  Size currentSize = Size.zero;

  PieChartPainter({
    super.repaint,
    required this.theme,
    required this.hoverLoc,
    required this.colors,
    required this.labels,
    required this.startAngles,
    required this.sweepAngles,
    this.defaultLabel,
  });

  /// Returns the bounding rect and strokeWidth given radius specifications. These should be between
  /// 0 and 1.
  (Rect, double) getRect(Rect totalRect, double radiusStart, double radiusEnd) {
    var rectWidth = totalRect.shortestSide * radiusEnd;
    final strokeWidth = rectWidth / 2 * (1 - radiusStart);
    rectWidth -= strokeWidth; // half width from both sides
    final rect = Rect.fromCenter(center: totalRect.center, width: rectWidth, height: rectWidth);
    return (rect, strokeWidth);
  }

  @override
  void paint(Canvas canvas, Size size) {
    currentSize = size;

    final totalRect = Offset.zero & size;
    final (rect, strokeWidth) = getRect(totalRect, 0.6, 0.9);
    final (hoverRect, hoverStrokeWidth) = getRect(totalRect, 0.53, 0.95);

    for (int i = 0; i < startAngles.length; i++) {
      canvas.drawArc(
        (i == hoverLoc) ? hoverRect : rect,
        startAngles[i] - pi / 2,
        sweepAngles[i],
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = (i == hoverLoc) ? hoverStrokeWidth : strokeWidth,
      );
    }

    /// Center label
    TextPainter? painter;
    if (hoverLoc != null && hoverLoc! < labels.length) {
      painter = labels[hoverLoc!];
    } else {
      painter = defaultLabel;
    }
    if (painter != null) {
      painter.layout(maxWidth: 0.5 * rect.width);
      final pos = Offset(
        totalRect.center.dx - painter.width / 2,
        totalRect.center.dy - painter.height / 2,
      );
      painter.paint(canvas, pos);
    }
  }

  @override
  bool shouldRepaint(PieChartPainter<T> oldDelegate) {
    // Warning, make sure you create new lists not just clear them or else this will fail. Might
    // be easier just to return true always...
    return theme != oldDelegate.theme ||
        hoverLoc != oldDelegate.hoverLoc ||
        colors != oldDelegate.colors ||
        labels != oldDelegate.labels ||
        startAngles != oldDelegate.startAngles ||
        sweepAngles != oldDelegate.sweepAngles;
  }

  int? userHitTest(Offset offset) {
    if (!currentSize.contains(offset)) return null;
    final totalRect = Offset.zero & currentSize;
    offset = offset - totalRect.center;
    // Here we map y -> (Right = +x) and x -> (Up = -y)
    // since we start at the top and move clockwise
    var angle = atan2(offset.dx, -offset.dy);
    if (angle < 0) angle += 2 * pi;
    for (int i = 0; i < startAngles.length; i++) {
      if (angle >= startAngles[i] && angle < startAngles[i] + sweepAngles[i]) return i;
    }
    return null;
  }
}

class PieChart<T> extends StatefulWidget {
  final List<T> data;
  final double Function(T) valueMapper;
  final Color? Function(T)? colorMapper;
  final String? Function(T, double frac)? labelMapper;
  final Function(int i, T it)? onTap;
  final String? defaultLabel;

  const PieChart({
    super.key,
    required this.data,
    required this.valueMapper,
    this.colorMapper,
    this.labelMapper,
    this.onTap,
    this.defaultLabel,
  });

  @override
  State<PieChart<T>> createState() => _PieChartState<T>();
}

class _PieChartState<T> extends State<PieChart<T>> {
  /// Calculated variables
  /// p.s. it's better to have a single data list because 1. the user doesn't have to manually create
  /// the below lists and 2. prevents alignment errors.
  double total = 0.0;
  List<int> dataIndex = [];
  List<T> filteredItems = [];
  List<double> values = [];
  List<Color> colors = [];
  List<TextPainter> labels = [];
  TextPainter? defaultLabel;

  List<double> startAngles = []; // radians
  List<double> sweepAngles = []; // radians

  /// Painter
  PieChartPainter<T>? painter;

  /// Hover
  int? hoverLoc;

  void _initValues() {
    final theme = Theme.of(context);

    /// Default label
    if (widget.defaultLabel != null) {
      defaultLabel = TextPainter(
        text: TextSpan(
          text: widget.defaultLabel,
          style: theme.textTheme.bodyLarge,
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
      );
    } else {
      defaultLabel = null;
    }

    /// Reset. Make sure to create new lists, not clear.
    total = 0.0;
    dataIndex = [];
    filteredItems = [];
    values = [];
    colors = [];
    labels = [];
    startAngles = [];
    sweepAngles = [];

    /// Filter items and get total in the meantime
    for (int i = 0; i < widget.data.length; i++) {
      final val = widget.valueMapper(widget.data[i]);
      if (val <= 0) continue;

      total += val;
      values.add(val);
      filteredItems.add(widget.data[i]);
      dataIndex.add(i);
    }
    if (total == 0) {
      painter = null;
      values.clear();
      filteredItems.clear();
      dataIndex.clear();
      return;
    }

    /// Get the other fields
    var currStart = 0.0;
    for (int i = 0; i < filteredItems.length; i++) {
      final x = filteredItems[i];
      final val = values[i];

      /// Angles
      final width = val / total * 2 * pi;
      startAngles.add(currStart);
      sweepAngles.add(width);
      currStart += width;

      /// Colors and labels
      colors.add(widget.colorMapper?.call(x) ?? _defaultColors[i % _defaultColors.length]);
      labels.add(TextPainter(
        text: TextSpan(
          text: widget.labelMapper?.call(x, val / total) ?? '',
          style: theme.textTheme.bodyLarge,
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      ));
    }
  }

  void _createPainter() {
    painter = PieChartPainter<T>(
      theme: Theme.of(context),
      hoverLoc: hoverLoc,
      colors: colors,
      labels: labels,
      startAngles: startAngles,
      sweepAngles: sweepAngles,
      defaultLabel: defaultLabel,
    );
  }

  @override
  void initState() {
    super.initState();
  }

  // Need to init here and not [initState] because we access Theme.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initValues();
    _createPainter();
  }

  // This is necessary to update the state when the parent rebuilds.
  // https://stackoverflow.com/questions/54759920/flutter-why-is-child-widgets-initstate-is-not-called-on-every-rebuild-of-pa
  @override
  void didUpdateWidget(PieChart<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valueMapper != widget.valueMapper ||
        oldWidget.labelMapper != widget.labelMapper ||
        oldWidget.colorMapper != widget.colorMapper ||
        oldWidget.defaultLabel != widget.defaultLabel ||
        oldWidget.data != widget.data) {
      _initValues();
      _createPainter();
    }
  }

  void onHover(PointerHoverEvent event) {
    if (painter == null || painter!.currentSize == Size.zero) return;
    final pos = painter!.userHitTest(event.localPosition);
    if (hoverLoc != pos) {
      setState(() {
        hoverLoc = pos;
        _createPainter();
      });
    }
  }

  void onExit(PointerExitEvent event) {
    if (hoverLoc != null) {
      setState(() {
        hoverLoc = null;
        _createPainter();
      });
    }
  }

  void onTapUp(TapUpDetails details) {
    if (painter == null || painter!.currentSize == Size.zero) return;
    final pos = painter!.userHitTest(details.localPosition);
    if (pos != null && pos < filteredItems.length) {
      widget.onTap?.call(dataIndex[pos], filteredItems[pos]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: onHover,
      onExit: onExit,
      child: GestureDetector(
        onTapUp: onTapUp,
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: CustomPaint(
                painter: painter,
                size: Size.infinite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
