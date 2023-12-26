import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:libra_sheet/graphing/heatmap/heat_map_painter.dart';

/// This widget controls the hover for the heat map. The [child] is drawn next to the target hover
/// position and placed to not fall off the graph boundaries.
///
/// This widget should be used in a [Stack] with a [CustomPaint] using a [HeatMapPainter] such that
/// they have the same size.
class HeatMapHover extends SingleChildRenderObjectWidget {
  final HeatMapPainter mainGraph;

  /// This should be an index into the [painter.positions] list as returned by [painter.hitTestUser].
  final int? hoverLoc;

  const HeatMapHover({
    super.key,
    super.child,
    required this.mainGraph,
    this.hoverLoc,
  });

  @override
  RenderHeatMapHover createRenderObject(BuildContext context) {
    return RenderHeatMapHover(mainGraph, hoverLoc);
  }

  @override
  void updateRenderObject(BuildContext context, RenderHeatMapHover renderObject) {
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

/// The actual RenderObject for the [HeatMapHover]. This handles placing the tooltip child.
class RenderHeatMapHover extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  HeatMapPainter painter;
  int? hoverLoc;
  static const _offset = 10.0;

  RenderHeatMapHover(this.painter, this.hoverLoc);

  @override
  void performLayout() {
    size = constraints.biggest;
    child?.layout(constraints.loosen());
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;
    if (hoverLoc == null) return;
    if (hoverLoc! >= painter.positions.length) return;
    if (size != painter.currentSize) return;

    final target = painter.positions[hoverLoc!].rect;
    Offset topPos() =>
        target.topCenter - const Offset(0, _offset) - child!.size.bottomCenter(Offset.zero);
    Offset leftPos() =>
        target.centerLeft - const Offset(_offset, 0) - child!.size.centerRight(Offset.zero);

    Offset childPos;
    if ((target.bottom - size.height).abs() < 1) {
      childPos = topPos();
    } else if ((target.right - size.width).abs() < 1) {
      childPos = leftPos();
    } else if (target.width > target.height) {
      childPos = topPos();
    } else {
      childPos = leftPos();
    }
    childPos = Offset(
      clampDouble(childPos.dx, 0, size.width - child!.size.width),
      clampDouble(childPos.dy, 0, size.height - child!.size.height),
    );
    context.paintChild(child!, childPos);
  }
}
