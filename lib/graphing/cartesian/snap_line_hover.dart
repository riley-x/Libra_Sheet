import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:libra_sheet/graphing/cartesian/discrete_cartesian_graph.dart';
import 'package:libra_sheet/graphing/series/series.dart';

/// This widget controls the hover for a discrete x-axis graph. A solid vertical line is drawn at
/// the hover position given by [hoverLoc], and the [tooltip] is drawn next to it and placed to not
/// fall off the graph.
///
/// If [tooltip] is null, will use a [PooledTooltip] by default.
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
  }) : super(child: tooltip ?? PooledTooltip(mainGraph, hoverLoc));

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
        ..color = painter!.theme.colorScheme.onBackground
        ..isAntiAlias = false,
    );

    var left = pixelLoc + _xOffset;
    if (child!.size.width + left > size.width) {
      left = pixelLoc - _xOffset - child!.size.width;
    }
    context.paintChild(child!, offset + Offset(left, 30));
  }
}

/// This is a hover tooltip that pools together all the data at a single point in a discrete x-value
/// graph. It displays a title followed by entries from each series in a column.
class PooledTooltip extends StatelessWidget {
  const PooledTooltip(this.mainGraph, this.hoverLoc, {super.key});
  final DiscreteCartesianGraphPainter mainGraph;
  final int? hoverLoc;

  Widget? _getSeriesLabel(BuildContext context, Series series) {
    if (hoverLoc == null) return null;
    if (hoverLoc! >= series.data.length) return null;

    final widget = series.hoverBuilder(context, hoverLoc!, mainGraph);
    if (widget != null) return widget;

    final val = series.hoverValue(hoverLoc!);
    if (val == null || val == 0) return null;

    return Text(
      "${series.name}: ${mainGraph.yAxis.valToString(val)}",
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (hoverLoc == null) return const SizedBox();

    String getTotal() {
      var total = 0.0;
      for (final series in mainGraph.data.data) {
        total += series.hoverValue(hoverLoc!) ?? 0;
      }
      return mainGraph.yAxis.valToString(total);
    }

    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 3, bottom: 4),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onInverseSurface.withAlpha(210),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Title
            Text(
              mainGraph.xAxis.valToString(hoverLoc!.toDouble()),
              style: Theme.of(context).textTheme.labelLarge,
            ),

            /// Divider
            const SizedBox(height: 2),
            Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.onBackground),

            /// Series items
            for (final series in mainGraph.data.data)
              Align(
                alignment: Alignment.centerLeft,
                child: _getSeriesLabel(context, series),
              ),

            /// Total
            if (mainGraph.data.data.length > 1) ...[
              Divider(height: 5, thickness: 0.5, color: Theme.of(context).colorScheme.onBackground),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Total: ${getTotal()}",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
