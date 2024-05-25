import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:libra_sheet/graphing/cartesian/discrete_cartesian_graph.dart';

import 'pooled_tooltip.dart';

/// This widget controls the hover for a discrete x-axis graph. A solid vertical line is drawn at
/// the hover position given by [hoverLoc], and the [tooltip] is drawn next to it and placed to not
/// fall off the graph.
///
/// If [tooltip] is null, will use a [PooledTooltip] by default. [reverse] is exposed and passed to
/// the [PooledTooltip] for convenience, but is unused by this class.
///
/// This widget should be used in a [Stack] with a [DiscreteCartesianGraphPainter] such that they
/// have the same size.
class SnapLineHover extends SingleChildRenderObjectWidget {
  final DiscreteCartesianGraphPainter mainGraph;
  final int? hoverLoc;

  SnapLineHover({
    super.key,
    required this.mainGraph,
    this.hoverLoc,
    Widget? tooltip,
    bool reverse = false,
  }) : super(child: tooltip ?? PooledTooltip(mainGraph, hoverLoc, reverse: reverse));

  @override
  RenderSnapLineHover createRenderObject(BuildContext context) {
    return RenderSnapLineHover(mainGraph, hoverLoc);
  }

  @override
  void updateRenderObject(BuildContext context, RenderSnapLineHover renderObject) {
    if (renderObject.painter != mainGraph) {
      renderObject.painter = mainGraph;
      renderObject.markNeedsPaint();
    }
    if (renderObject.hoverLoc != hoverLoc) {
      renderObject.hoverLoc = hoverLoc;
      renderObject.markNeedsPaint();
    }
  }
}

/// The actual RenderObject for the [SnapLineHover]. This handles painting the line and placing
/// the tooltip.
class RenderSnapLineHover extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  DiscreteCartesianGraphPainter? painter;
  int? hoverLoc;
  static const _xOffset = 20.0;

  RenderSnapLineHover(this.painter, this.hoverLoc);

  @override
  void performLayout() {
    size = constraints.biggest;
    child?.layout(constraints.loosen());
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (painter == null) return;
    if (child == null) return;
    if (size != painter!.currentSize) return;
    if (painter!.coordSpace == null) return;
    if (hoverLoc == null) return;

    final userLoc = hoverLoc!.toDouble();
    final pixelLoc = painter!.coordSpace!.xAxis.userToPixel(userLoc);
    context.canvas.drawLine(
      Offset(pixelLoc, painter!.coordSpace!.yAxis.pixelMin),
      Offset(pixelLoc, painter!.coordSpace!.yAxis.pixelMax),
      Paint()
        ..color = painter!.theme.colorScheme.onSurface
        ..isAntiAlias = false,
    );

    var left = pixelLoc + _xOffset;
    if (child!.size.width + left > size.width) {
      left = pixelLoc - _xOffset - child!.size.width;
    }
    context.paintChild(child!, offset + Offset(left, 30));
  }
}
