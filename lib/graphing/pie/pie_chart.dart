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
  });

  // void paintLabels(Canvas canvas) {
  //   /// y labels
  //   if (yLabels != null) {
  //     for (final (pos, painter) in yLabels!) {
  //       final loc = Offset(
  //         coordSpace!.xAxis.pixelMin - yAxis.labelOffset - painter.width,
  //         coordSpace!.yAxis.userToPixel(pos) - painter.height / 2,
  //       );
  //       painter.paint(canvas, loc);
  //     }
  //   }
  // }

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

    if (hoverLoc != null && hoverLoc! < labels.length) {
      final painter = labels[hoverLoc!];
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

  const PieChart({
    super.key,
    required this.data,
    required this.valueMapper,
    this.colorMapper,
    this.labelMapper,
  });

  @override
  State<PieChart<T>> createState() => _PieChartState<T>();
}

class _PieChartState<T> extends State<PieChart<T>> {
  /// Calculated variables
  /// p.s. it's better to have a single data list because 1. the user doesn't have to manually create
  /// the below lists and 2. prevents alignment errors.
  double total = 0.0;
  List<double> values = [];
  List<Color> colors = [];
  List<TextPainter> labels = [];

  List<double> startAngles = []; // radians
  List<double> sweepAngles = []; // radians

  /// Painter
  PieChartPainter<T>? painter;

  /// Hover
  int? hoverLoc;

  void _initValues() {
    final theme = Theme.of(context);
    total = 0.0;

    values = [];
    colors = [];
    labels = [];
    startAngles = [];
    sweepAngles = [];

    final filteredItems = <T>[];
    for (final x in widget.data) {
      final val = widget.valueMapper(x);
      if (val <= 0) continue;

      total += val;
      values.add(val);
      filteredItems.add(x);
    }
    if (total == 0) {
      painter = null;
      values.clear();
      return;
    }

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

  void onTapUp(TapUpDetails details) {}

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
