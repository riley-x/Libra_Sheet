import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_axes.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_coordinate_space.dart';
import 'package:libra_sheet/graphing/cartesian/month_axis.dart';
import 'package:libra_sheet/graphing/cartesian/snap_line_hover.dart';
import 'package:libra_sheet/graphing/series/series.dart';

class DiscreteCartesianGraphPainter<T> extends CustomPainter {
  final CartesianAxis xAxis;
  final CartesianAxis yAxis;
  final ThemeData theme;
  final SeriesCollection data;

  /// Variables of a given paint
  Size currentSize = Size.zero;
  CartesianCoordinateSpace? coordSpace;
  List<(double, TextPainter)>? xLabels;
  List<(double, TextPainter)>? yLabels;

  DiscreteCartesianGraphPainter({
    super.repaint,
    required this.data,
    required this.xAxis,
    required this.yAxis,
    required this.theme,
  });

  /// Lays out the axis with default labels and padding.
  void layoutAxes(Size size) {
    if (size == currentSize) return;

    currentSize = size;
    coordSpace = CartesianCoordinateSpace.fromAxes(
      canvasSize: size,
      xAxis: xAxis,
      yAxis: yAxis,
    );
    coordSpace!.autoRange(xAxis: xAxis, yAxis: yAxis, data: data);

    /// Auto labels and axis padding; TODO this is hard coded for bottom and left aligned labels
    yLabels = yAxis.autoYLabels(coordSpace!);
    if (coordSpace!.xAxis.padStart == null) {
      var maxLabelWidth = 0.0;
      for (final (_, x) in yLabels!) {
        maxLabelWidth = max(maxLabelWidth, x.width);
      }
      coordSpace!.xAxis.padStart = maxLabelWidth + yAxis.labelOffset;
    }
    xLabels = xAxis.autoXLabels(coordSpace!);
    if (coordSpace!.yAxis.padStart == null) {
      coordSpace!.yAxis.padStart = coordSpace!.xAxis.labelLineHeight + xAxis.labelOffset;
    }
  }

  // TODO this is hard coded for bottom and left aligned labels
  void paintLabels(Canvas canvas) {
    if (coordSpace == null) return;

    /// x labels
    if (xLabels != null) {
      for (final (pos, painter) in xLabels!) {
        final loc = Offset(
          coordSpace!.xAxis.userToPixel(pos) - painter.width / 2,
          coordSpace!.yAxis.pixelMin + yAxis.labelOffset,
        );
        painter.paint(canvas, loc);
      }
    }

    /// y labels
    if (yLabels != null) {
      for (final (pos, painter) in yLabels!) {
        final loc = Offset(
          coordSpace!.xAxis.pixelMin - yAxis.labelOffset - painter.width,
          coordSpace!.yAxis.userToPixel(pos) - painter.height / 2,
        );
        painter.paint(canvas, loc);
      }
    }
  }

  List<double> _defaultXGridlines() {
    List<double> out = [];
    if (xLabels != null) {
      for (final (pos, _) in xLabels!) {
        out.add(pos);
      }
    }
    return out;
  }

  List<double> _defaultYGridlines() {
    List<double> out = [];
    if (yLabels != null) {
      for (final (pos, _) in yLabels!) {
        out.add(pos);
      }
    }
    return out;
  }

  void paintGridLines(Canvas canvas) {
    if (coordSpace == null) return;

    /// Horizontal grid lines
    final horizontalGridLines = yAxis.gridLines ?? _defaultYGridlines();
    for (final pos in horizontalGridLines) {
      double y = coordSpace!.yAxis.userToPixel(pos);
      double x1 = coordSpace!.xAxis.pixelMin;
      double x2 = coordSpace!.xAxis.pixelMax;
      canvas.drawLine(Offset(x1, y), Offset(x2, y), yAxis.gridLinePainter);
    }

    /// Vertical grid lines
    final verticalGridLines = xAxis.gridLines ?? _defaultXGridlines();
    for (final pos in verticalGridLines) {
      double x = coordSpace!.xAxis.userToPixel(pos);
      double y1 = coordSpace!.yAxis.pixelMin;
      double y2 = coordSpace!.yAxis.pixelMax;
      canvas.drawLine(Offset(x, y1), Offset(x, y2), xAxis.gridLinePainter);
    }
  }

  void paintAxisLines(Canvas canvas) {
    if (coordSpace == null) return;
    if (xAxis.axisLoc != null) {
      double x1 = coordSpace!.xAxis.pixelMin;
      double x2 = coordSpace!.xAxis.pixelMax;
      double y = coordSpace!.yAxis.userToPixel(xAxis.axisLoc!);
      canvas.drawLine(Offset(x1, y), Offset(x2, y), xAxis.axisPainter);
    }

    if (yAxis.axisLoc != null) {
      double y1 = coordSpace!.yAxis.pixelMin;
      double y2 = coordSpace!.yAxis.pixelMax;
      double x = coordSpace!.xAxis.userToPixel(yAxis.axisLoc!);
      canvas.drawLine(Offset(x, y1), Offset(x, y2), yAxis.axisPainter);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    layoutAxes(size);
    if (coordSpace == null) return;
    paintGridLines(canvas);
    for (final series in data.data) {
      series.paint(canvas, coordSpace!);
    }
    paintLabels(canvas);
    paintAxisLines(canvas);
  }

  @override
  bool shouldRepaint(DiscreteCartesianGraphPainter<T> oldDelegate) {
    return xAxis != oldDelegate.xAxis || yAxis != oldDelegate.yAxis || data != oldDelegate.data;
  }
}

class DiscreteCartesianGraph extends StatefulWidget {
  final MonthAxis xAxis;
  final CartesianAxis yAxis;
  final SeriesCollection data;

  const DiscreteCartesianGraph({
    super.key,
    required this.xAxis,
    required this.yAxis,
    required this.data,
  });

  @override
  State<DiscreteCartesianGraph> createState() => _DiscreteCartesianGraphState();
}

class _DiscreteCartesianGraphState extends State<DiscreteCartesianGraph> {
  int? hoverLocX;
  DiscreteCartesianGraphPainter? painter;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    painter = DiscreteCartesianGraphPainter(
      theme: Theme.of(context),
      xAxis: widget.xAxis,
      yAxis: widget.yAxis,
      data: widget.data,
    );
  }

  @override
  void didUpdateWidget(DiscreteCartesianGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.xAxis != widget.xAxis ||
        oldWidget.yAxis != widget.yAxis ||
        oldWidget.data != widget.data) {
      painter = DiscreteCartesianGraphPainter(
        theme: Theme.of(context),
        xAxis: widget.xAxis,
        yAxis: widget.yAxis,
        data: widget.data,
      );
    }
  }

  void onHover(PointerHoverEvent event) {
    if (painter == null || painter!.currentSize == Size.zero || painter!.coordSpace == null) return;
    final userX = painter!.coordSpace!.xAxis.pixelToUser(event.localPosition.dx).round();
    setState(() {
      if (userX < 0 || userX >= widget.xAxis.dates.length) {
        hoverLocX = null;
      } else {
        hoverLocX = userX;
      }
    });
  }

  void onExit(PointerExitEvent event) {
    setState(() {
      hoverLocX = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // print(MediaQuery.of(context).devicePixelRatio);
    return MouseRegion(
      onHover: onHover,
      onExit: onExit,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              painter: painter,
              size: Size.infinite,
            ),
          ),
          if (painter != null)
            RepaintBoundary(
              child: SnapLineHover(
                mainGraph: painter!,
                hoverLoc: hoverLocX,
              ),
            ),
        ],
      ),
    );
  }
}
