import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_axes.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_coordinate_space.dart';
import 'package:libra_sheet/graphing/cartesian/month_axis.dart';
import 'package:libra_sheet/graphing/cartesian/snap_line_hover.dart';
import 'package:libra_sheet/graphing/cartesian/x_range_selection_overlay.dart';
import 'package:libra_sheet/graphing/series/series.dart';

/// This is the painter class for cartesian graphs. It contains the axes which define the mapping
/// between pixel and user coordinates, and manages the painting of the axes, labels, and data.
///
/// TODO I think this class is general enough for non-discrete x axes too.
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
  int? yLabelOrder;

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

    // TODO these are hard coded for bottom and left aligned labels

    /// Auto y labels
    final labels = yAxis.autoYLabels(coordSpace!);
    yLabels = labels.$1;
    yLabelOrder = labels.$2;

    /// Auto x axis pad start based on max width of y labels.
    if (coordSpace!.xAxis.padStart == null) {
      var maxLabelWidth = 0.0;
      for (final (_, x) in yLabels!) {
        maxLabelWidth = max(maxLabelWidth, x.width);
      }
      coordSpace!.xAxis.padStart = maxLabelWidth + yAxis.labelOffset;
    }

    /// Auto x labels (make sure this is after the start padding is set).
    xLabels = xAxis.autoXLabels(coordSpace!);

    /// Auto y axis pad start assuming single line x axis labels.
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
    paintLabels(canvas);
    for (final series in data.paintOrder) {
      series.paint(this, canvas, coordSpace!);
    }
    paintAxisLines(canvas);
  }

  @override
  bool shouldRepaint(DiscreteCartesianGraphPainter<T> oldDelegate) {
    return xAxis != oldDelegate.xAxis || yAxis != oldDelegate.yAxis || data != oldDelegate.data;
  }

  //---------------------------------------------------------------------------------
  // Callbacks
  //---------------------------------------------------------------------------------

  (int, Series, int)? onTap(Offset offset) {
    if (coordSpace == null) return null;
    for (int i = 0; i < data.data.length; i++) {
      final loc = data.data[i].hitTest(offset, coordSpace!);
      if (loc != null) {
        return (i, data.data[i], loc);
      }
    }
    return null;
  }
}

/// This widget paints a cartesian graph with a discrete (month-based) x-axis. It also handles
/// gestures and hovering behavior, with ownership of the corresponding overlay widgets.
class DiscreteCartesianGraph extends StatefulWidget {
  final MonthAxis xAxis;
  final CartesianAxis yAxis;

  /// Because this class uses a [MonthAxis] on the xAxis, which has x values as just the index, [0,
  /// nMonths-1], every series should have the same number of elements in the respective order.
  final SeriesCollection data;
  final Function(int iSeries, Series series, int iData)? onTap;
  final Function(int xStart, int xEnd)? onRange;
  final Widget? Function(DiscreteCartesianGraphPainter, int?)? hoverTooltip;

  const DiscreteCartesianGraph({
    super.key,
    required this.xAxis,
    required this.yAxis,
    required this.data,
    this.onTap,
    this.onRange,
    this.hoverTooltip,
  });

  @override
  State<DiscreteCartesianGraph> createState() => _DiscreteCartesianGraphState();
}

class _DiscreteCartesianGraphState extends State<DiscreteCartesianGraph> {
  /// Hover positions in user coordinates
  int? hoverLocX;
  double? hoverLocY;

  /// Hover positions in pixel coordinates
  Offset? hoverPixLoc;

  int? lastTapDown;
  int? panStart;
  int? panEnd;
  DiscreteCartesianGraphPainter? painter;

  void _initPainter() {
    painter = DiscreteCartesianGraphPainter(
      theme: Theme.of(context),
      xAxis: widget.xAxis,
      yAxis: widget.yAxis,
      data: widget.data,
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
    _initPainter();
  }

  // This is necessary to update the state when the parent rebuilds.
  // https://stackoverflow.com/questions/54759920/flutter-why-is-child-widgets-initstate-is-not-called-on-every-rebuild-of-pa
  @override
  void didUpdateWidget(DiscreteCartesianGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.xAxis != widget.xAxis ||
        oldWidget.yAxis != widget.yAxis ||
        oldWidget.data != widget.data) {
      _initPainter();
    }
  }

  /// Returns the nearest index into [widget.xAxis] of the event at [localPosition], or null if
  /// out-of-bounds.
  ///
  /// If [clamp], instead of returning null for out-of-bounds events, will return either 0 or N-1.
  int? _getXLoc(Offset localPosition, [bool clamp = false]) {
    if (painter == null || painter!.currentSize == Size.zero || painter!.coordSpace == null) {
      return null;
    }
    final userX = painter!.coordSpace!.xAxis.pixelToUser(localPosition.dx).round();
    if (userX < 0) {
      return (clamp) ? 0 : null;
    } else if (userX >= widget.xAxis.dates.length) {
      return (clamp) ? widget.xAxis.dates.length - 1 : null;
    }
    return userX;
  }

  void onHover(PointerHoverEvent event) {
    if (painter == null || painter!.currentSize == Size.zero || painter!.coordSpace == null) return;
    final userX = _getXLoc(event.localPosition);
    setState(() {
      hoverLocX = userX;
      hoverLocY = (event.localPosition.dy > painter!.coordSpace!.yAxis.pixelMin ||
              event.localPosition.dy < painter!.coordSpace!.yAxis.pixelMax)
          ? null
          : painter!.coordSpace!.yAxis.pixelToUser(event.localPosition.dy);
      hoverPixLoc = event.localPosition;
    });
  }

  void onExit(PointerExitEvent event) {
    setState(() {
      hoverLocX = null;
      hoverLocY = null;
      hoverPixLoc = null;
    });
  }

  /// The pan start position is not the tap down position, and on fast enough pans,
  /// can be a different xLoc than the tap down position. So we need to store all tap down
  /// positions and use that as the panStart.
  void onPointerDown(PointerDownEvent details) {
    final userX = _getXLoc(details.localPosition, true);
    lastTapDown = userX;
  }

  void onTapUp(TapUpDetails details) {
    if (widget.onTap == null) return;
    final result = painter?.onTap(details.localPosition);
    if (result != null) {
      widget.onTap!(result.$1, result.$2, result.$3);
    }
  }

  void onPanStart(DragStartDetails details) {
    /// A two-finger drag also triggers the pan, but this is a little unintuitive, since it is
    /// usually related to scrolling. The localPosition is the position of your fingers on the
    /// trackpad, not the mouse.
    if (details.kind == PointerDeviceKind.trackpad) return;

    final userX = _getXLoc(details.localPosition, true);
    setState(() {
      hoverLocX = null;
      hoverLocY = null;
      hoverPixLoc = null;
      panStart = lastTapDown;
      panEnd = userX;
    });
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (panStart == null) return;
    final userX = _getXLoc(details.localPosition, true);
    setState(() {
      panEnd = userX;
    });
  }

  void onPanEnd(DragEndDetails details) {
    if (panStart == null) return;
    final start = panStart;
    final end = _getXLoc(details.localPosition, true);
    setState(() {
      panStart = null;
      panEnd = null;
    });
    if (start != null && end != null) {
      widget.onRange?.call(min(start, end), max(start, end));
    }
  }

  void onPanCancel() {
    setState(() {
      panStart = null;
      panEnd = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // print(MediaQuery.of(context).devicePixelRatio);
    return MouseRegion(
      onHover: onHover,
      onExit: onExit,
      child: Listener(
        onPointerDown: onPointerDown,
        child: GestureDetector(
          onTapUp: onTapUp,
          onPanStart: onPanStart,
          onPanUpdate: onPanUpdate,
          onPanEnd: onPanEnd,
          onPanCancel: onPanCancel,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  painter: painter,
                  size: Size.infinite,
                ),
              ),
              if (painter != null && painter!.coordSpace != null) ...[
                RepaintBoundary(
                  child: SnapLineHover(
                    mainGraph: painter!,
                    hoverLoc: hoverLocX,
                    reverse: widget.data.hasStack,
                    tooltip: (widget.hoverTooltip == null)
                        ? null
                        : widget.hoverTooltip!(painter!, hoverLocX),
                  ),
                ),
                if (panStart != null && panEnd != null)
                  RepaintBoundary(
                    child: XRangeSelectionOverlay(
                      xStart: min(panStart!, panEnd!).toDouble() - 0.5,
                      xEnd: max(panStart!, panEnd!).toDouble() + 0.5,
                      coords: painter!.coordSpace!,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
