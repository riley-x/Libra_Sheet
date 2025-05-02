import 'package:flutter/material.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/graphing/extensions.dart';
import 'package:libra_sheet/graphing/sankey/sankey_node.dart';

String _defaultToString(double value) {
  return value.formatDollar();
}

class SankeyPainter extends CustomPainter {
  final ThemeData theme;
  final List<List<SankeyNode>> data;
  final String? Function(double value) valueToString;

  final double nodeWidth = 20;
  final double nodeVertDesiredMinPad = 5;
  final double labelXOffset = 5;

  Size previousSize = Size.zero;
  double levelHoriPad = 10;
  Map<SankeyNode, SankeyLayoutNode> layouts = {};
  List<SankeyLayoutNode> drawNodes = [];
  List<SankeyLayoutFlow> drawFlows = [];
  List<SankeyLayoutLabel> drawLabels = [];

  SankeyPainter({
    super.repaint,
    required this.theme,
    required this.data,
    String? Function(double value)? valueToString,
  }) : valueToString = valueToString ?? _defaultToString;

  void _layout(Size size) {
    if (previousSize == size) {
      return;
    }
    previousSize = size;
    drawNodes = [];
    drawFlows = [];
    drawLabels = [];

    final nLevels = data.length;
    if (nLevels <= 1) return;

    levelHoriPad = (size.width - nodeWidth * nLevels) / (nLevels - 1);
    if (levelHoriPad <= 0) return;

    /// Scale
    var scale = double.maxFinite;
    var vertPad = nodeVertDesiredMinPad;
    for (final level in data) {
      final (levelScale, levelVertPad) = _getMaxValueScaleAndVertPad(level, size.height);
      if (levelVertPad < vertPad) {
        vertPad = levelVertPad;
      }
      if (levelScale < scale) {
        scale = levelScale;
      }
    }

    /// Nodes
    for (final (i, level) in data.indexed) {
      final x = i * (nodeWidth + levelHoriPad);
      _layoutLayerJustified(level, x, size.height, scale);
    }

    /// Flows
    Map<SankeyLayoutNode, double> destTops = {};
    for (final source in drawNodes) {
      double sourceTop = 0;
      for (final flow in source.node.outgoingFlows) {
        final flowWidth = flow.value * scale;

        final dest = layouts[flow.destination]!;
        final destTop = destTops[dest] ?? 0;
        final destCenter = destTop + flowWidth / 2;
        final sourceCenter = sourceTop + flowWidth / 2;
        final destBottom = destTop + flowWidth;
        final sourceBottom = sourceTop + flowWidth;

        /// A single bezier with the right width works well generally, but has some weird artifacts
        /// if it's too wide and stubby. Fallback in this case to a filled path...the double bezier
        /// boundaries are wrong though and make the line look too narrow. Lookup bezier offseting.
        /// Odd that flutter stroking makes these weird artifacts though, maybe not simple fix.
        final Path path;
        final Paint paint;
        if (flowWidth < 0.8 * levelHoriPad) {
          path = Path()
            ..moveToOffset(source.loc.topRight.translate(-1, sourceCenter))
            ..cubicToOffset(
              dest.loc.topLeft.translate(1, destCenter),
              source.loc.topRight.translate(levelHoriPad / 2, sourceCenter),
              dest.loc.topLeft.translate(-levelHoriPad / 2, destCenter),
            );
          paint = Paint()
            ..color = flow.color.withAlpha(100)
            ..strokeWidth = flowWidth
            ..style = PaintingStyle.stroke;
        } else {
          path = Path()
            ..moveToOffset(source.loc.topRight.translate(-1, sourceTop))
            ..cubicToOffset(
              dest.loc.topLeft.translate(1, destTop),
              source.loc.topRight.translate(levelHoriPad / 2, sourceTop),
              dest.loc.topLeft.translate(-levelHoriPad / 2, destTop),
            )
            ..lineToOffset(dest.loc.topLeft.translate(1, destBottom))
            ..cubicToOffset(
              source.loc.topRight.translate(-1, sourceBottom),
              dest.loc.topLeft.translate(-levelHoriPad / 2, destBottom),
              source.loc.topRight.translate(levelHoriPad / 2, sourceBottom),
            )
            ..close();
          paint = Paint()
            ..color = flow.color.withAlpha(100)
            ..style = PaintingStyle.fill;
        }
        drawFlows.add(SankeyLayoutFlow(
          flow: flow,
          source: source,
          destination: dest,
          path: path,
          paint: paint,
        ));
        sourceTop += flowWidth;
        destTops[dest] = destTop + flowWidth;
      }
    }
  }

  /// Spreads all nodes equally, as much as possible, filling the full height
  void _layoutLayerJustified(List<SankeyNode> level, double x, double height, double scale) {
    if (level.length == 1) {
      final node = level[0];
      final nodeHeight = node.value * scale;
      final layoutNode = SankeyLayoutNode(
        node: node,
        loc: Rect.fromLTWH(x, (height - nodeHeight) / 2, nodeWidth, nodeHeight),
      );
      drawNodes.add(layoutNode);
      _layoutLabel(layoutNode, verticalSpace: height);
      layouts[node] = layoutNode;
      return;
    }

    double sum = 0;
    for (final node in level) {
      sum += node.value;
    }

    double y = 0;
    double vertPad = (height - sum * scale) / (level.length - 1);
    for (final node in level) {
      final nodeHeight = node.value * scale;
      final layoutNode = SankeyLayoutNode(
        node: node,
        loc: Rect.fromLTWH(x, y, nodeWidth, nodeHeight),
      );
      drawNodes.add(layoutNode);
      layouts[node] = layoutNode;
      _layoutLabel(layoutNode, verticalSpace: nodeHeight + vertPad);
      y += nodeHeight + vertPad;
    }
  }

  /// Finds the value scale (i.e., scale * value = pixel height) that, given the minimum padding
  /// between nodes, the entries in this level perfectly span the total canvas height.
  (double, double) _getMaxValueScaleAndVertPad(List<SankeyNode> level, double height) {
    double sum = 0;
    for (final node in level) {
      sum += node.value;
    }
    if (level.length == 1) {
      return (height / sum, nodeVertDesiredMinPad);
    }

    double padding = (level.length - 1) * nodeVertDesiredMinPad;
    double freeHeight = height - padding;
    if (freeHeight < padding) {
      padding = height * 0.5;
      freeHeight = height - padding;
    }
    return (freeHeight / sum, padding / (level.length - 1));
  }

  void _layoutLabel(SankeyLayoutNode node, {double? verticalSpace}) {
    if (levelHoriPad <= 20) {
      return;
    }

    final style = theme.textTheme.bodySmall;
    final lineHeight = (style?.height ?? 1.2) * (style?.fontSize ?? 16);
    verticalSpace ??= node.loc.height;
    if (verticalSpace < lineHeight) {
      return;
    }

    final isRightSide = node.node.labelAlignment.x > 0;

    /// Single line == only label
    /// Two lines == single line label + value
    /// Else == two line label + value
    final TextPainter labelPainter = TextPainter(
      text: TextSpan(text: node.node.label, style: theme.textTheme.bodySmall),
      textAlign: isRightSide ? TextAlign.left : TextAlign.right,
      textDirection: TextDirection.ltr,
      maxLines: verticalSpace < lineHeight * 3 ? 1 : 2,
      ellipsis: '...',
    );

    final TextPainter? valuePainter = verticalSpace < lineHeight * 2
        ? null
        : TextPainter(
            text: TextSpan(text: valueToString(node.node.value), style: theme.textTheme.bodySmall),
            textAlign: isRightSide ? TextAlign.left : TextAlign.right,
            textDirection: TextDirection.ltr,
            maxLines: 1,
            ellipsis: '...',
          );
    labelPainter.layout(maxWidth: levelHoriPad - 2 * labelXOffset);
    valuePainter?.layout(maxWidth: levelHoriPad - 2 * labelXOffset);
    final halfHeight = (labelPainter.height + (valuePainter?.height ?? 0)) / 2;
    drawLabels.add(SankeyLayoutLabel(
      node: node,
      labelPainter: labelPainter,
      valuePainter: valuePainter,
      labelLoc: node.node.labelAlignment.withinRect(node.loc).translate(
            isRightSide ? labelXOffset : -labelXOffset - labelPainter.width,
            -halfHeight,
          ),
      valueLoc: node.node.labelAlignment.withinRect(node.loc).translate(
            isRightSide ? labelXOffset : -labelXOffset - (valuePainter?.width ?? 0),
            -halfHeight + labelPainter.height,
          ),
    ));
  }

  @override
  void paint(Canvas canvas, Size size) {
    _layout(size);
    for (final flow in drawFlows) {
      canvas.drawPath(flow.path, flow.paint);
    }
    for (final node in drawNodes) {
      canvas.drawRect(
        node.loc,
        Paint()
          ..color = node.node.color
          ..style = PaintingStyle.fill,
      );
    }
    for (final label in drawLabels) {
      label.labelPainter.paint(canvas, label.labelLoc);
      label.valuePainter?.paint(canvas, label.valueLoc);
    }
  }

  @override
  bool shouldRepaint(SankeyPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.theme != theme ||
        oldDelegate.valueToString != valueToString;
  }
}

class SankeyLayoutNode {
  final SankeyNode node;

  // Drawing rect of the node in pixel coordinates.
  final Rect loc;

  SankeyLayoutNode({required this.node, required this.loc});
}

class SankeyLayoutFlow {
  final SankeyFlow flow;
  final SankeyLayoutNode source;
  final SankeyLayoutNode destination;
  final Path path;
  final Paint paint;

  SankeyLayoutFlow({
    required this.flow,
    required this.source,
    required this.destination,
    required this.path,
    required this.paint,
  });
}

class SankeyLayoutLabel {
  final SankeyLayoutNode node;
  final TextPainter labelPainter;
  final TextPainter? valuePainter;
  final Offset labelLoc;
  final Offset valueLoc;

  SankeyLayoutLabel({
    required this.node,
    required this.labelPainter,
    required this.valuePainter,
    required this.labelLoc,
    required this.valueLoc,
  });
}
