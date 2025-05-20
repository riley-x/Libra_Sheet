import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/graphing/mouse_hover.dart';
import 'package:libra_sheet/graphing/sankey/sankey_node.dart';
import 'package:libra_sheet/graphing/sankey/sankey_painter.dart';

class TieredSankeyPlot extends StatefulWidget {
  final List<List<SankeyNode>> nodes;
  final String? Function(double value)? valueToString;
  final Function(SankeyNode node)? onTap;
  final SankeyLayout? layout;

  const TieredSankeyPlot(
      {super.key, required this.nodes, this.valueToString, this.onTap, this.layout});

  @override
  State<TieredSankeyPlot> createState() => _TieredSankeyPlotState();
}

class _TieredSankeyPlotState extends State<TieredSankeyPlot> {
  SankeyPainter? painter;

  /// Hover positions in pixel coordinates
  Offset? hoverPixLoc;
  SankeyNode? hoverNode;

  void _calculateNodes() {}

  void _initPainter() {
    painter = SankeyPainter(
      theme: Theme.of(context),
      data: widget.nodes,
      valueToString: widget.valueToString,
      layout: widget.layout,
    );
  }

  @override
  void initState() {
    super.initState();
    _calculateNodes();
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
  void didUpdateWidget(TieredSankeyPlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _calculateNodes();
    _initPainter();
  }

  void onTapUp(TapUpDetails details) {
    if (widget.onTap == null) return;
    final node = painter?.nodeHitTest(details.localPosition);
    if (node != null) {
      widget.onTap!(node);
    }
  }

  void onHover(PointerHoverEvent event) {
    if (painter == null || painter!.currentSize == Size.zero) return;
    final node = painter?.nodeHitTest(event.localPosition);
    setState(() {
      hoverNode = node;
      hoverPixLoc = event.localPosition;
    });
  }

  void onExit(PointerExitEvent event) {
    setState(() {
      hoverNode = null;
      hoverPixLoc = null;
    });
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
            if (painter != null &&
                painter!.currentSize != Size.zero &&
                hoverPixLoc != null &&
                hoverNode != null)
              RepaintBoundary(
                child: MouseHover(
                  loc: hoverPixLoc!,
                  child: Container(
                    padding: const EdgeInsets.only(left: 10, right: 10, top: 3, bottom: 4),
                    constraints: const BoxConstraints(maxWidth: 300),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onInverseSurface.withAlpha(210),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "${hoverNode!.label}\n${widget.valueToString?.call(hoverNode!.value) ?? hoverNode!.value.formatDollar()}",
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
