import 'dart:math';

import 'package:flutter/material.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/graphing/extensions.dart';
import 'package:libra_sheet/graphing/sankey/sankey_node.dart';
import 'package:libra_sheet/graphing/sankey/sankey_tree.dart';

String _defaultToString(double value) {
  return value.formatDollar();
}

enum SankeyLayout { tree, justify }

class SankeyPainter extends CustomPainter {
  final ThemeData theme;
  final List<List<SankeyNode>> data;
  late final SankeyTree? dataAsTree;
  final String? Function(double value) valueToString;
  final SankeyLayout layout;

  final double nodeWidth = 20;
  final double nodeVertDesiredMinPad = 5;
  final double labelXOffset = 5;

  Size currentSize = Size.zero;
  double levelHoriPad = 10;
  Map<SankeyNode, SankeyLayoutNode> layouts = {};
  List<SankeyLayoutNode> drawNodes = [];
  List<SankeyLayoutFlow> drawFlows = [];
  List<SankeyLayoutLabel> drawLabels = [];

  SankeyPainter({
    super.repaint,
    required this.theme,
    required this.data,
    SankeyLayout? layout,
    String? Function(double value)? valueToString,
  })  : valueToString = valueToString ?? _defaultToString,
        layout = layout ?? SankeyLayout.tree {
    try {
      final flattenedData = data.expand((level) => level).toList();
      dataAsTree = createTree(flattenedData, paddingFn: (layer) => 15);
    } on SankeyTreeLayoutException catch (e) {
      debugPrint('SankeyTreeLayoutException: $e');
      dataAsTree = null;
    }
    // print(dataAsTree);
  }

  void _layout(Size size) {
    if (currentSize == size) {
      return;
    }
    currentSize = size;
    drawNodes = [];
    drawFlows = [];
    drawLabels = [];

    final nLevels = data.length;
    if (nLevels <= 1) return;

    levelHoriPad = (size.width - nodeWidth * nLevels) / (nLevels - 1);
    if (levelHoriPad <= 0) return;

    double scale = switch (layout) {
      SankeyLayout.tree => dataAsTree != null ? _layoutTree(size) : _layoutJustified(size),
      SankeyLayout.justify => _layoutJustified(size),
    };
    _layoutFlow(scale);
  }

  /// Assumes a double-sided tree structure on the nodes, starting from a central root node, and
  /// starts by positioning the leaf nodes equally spaced. Parent nodes are then placed centered
  /// to their children.
  double _layoutTree(Size size) {
    SankeyTree tree = dataAsTree!;

    final (valueScale, paddingScale) = tree.getScale(size.height, size.height * 0.5);

    double incomingX(int treeLayer) {
      final absoluteLayer = tree.incomingBranch.maxDescendantLayer - treeLayer;
      return absoluteLayer * (nodeWidth + levelHoriPad);
    }

    double outgoingX(int treeLayer) {
      final absoluteLayer = treeLayer + tree.incomingBranch.maxDescendantLayer;
      return absoluteLayer * (nodeWidth + levelHoriPad);
    }

    _layoutTreeNode(tree.incomingBranch, valueScale, paddingScale, incomingX, 0, size.height);
    _layoutTreeNode(tree.outgoingBranch, valueScale, paddingScale, outgoingX, 0, size.height, true);
    return valueScale;
  }

  void _layoutTreeNode(
    SankeyTreeNode node,
    double valueScale,
    double paddingScale,
    double Function(int treeLayer) xFn,
    double yMin,
    double yMax, [
    bool skip = false,
  ]) {
    final totalHeight = yMax - yMin;
    final nodeHeight = node.node.value * valueScale;
    if (node.layer == 0)
      print("${node.node.label} $yMin $yMax $totalHeight $nodeHeight ${node.totalPadding}");
    if (!skip) {
      final x = xFn.call(node.layer);
      final offset = (totalHeight - nodeHeight) / 2 + node.offset * paddingScale;
      final layoutNode = SankeyLayoutNode(
        node: node.node,
        loc: Rect.fromLTWH(x, yMin + offset, nodeWidth, nodeHeight),
      );
      drawNodes.add(layoutNode);
      _layoutLabel(layoutNode, verticalSpace: totalHeight);
      layouts[node.node] = layoutNode;
    }

    var descendentHeight = nodeHeight + node.totalPadding * paddingScale;
    double yStart = yMin + (totalHeight - descendentHeight) / 2;
    for (final child in node.children) {
      final yEnd = yStart + child.node.value * valueScale + child.totalPadding * paddingScale;

      // Include inter-child padding into full y-extent
      final paddedStart = yStart - node.childPadding * paddingScale / 2;
      final paddedEnd = yEnd + node.childPadding * paddingScale / 2;
      _layoutTreeNode(child, valueScale, paddingScale, xFn, paddedStart, paddedEnd);

      yStart = yEnd + node.childPadding * paddingScale;
    }
  }

  /// Spreads all nodes equally, as much as possible, filling the full height
  /// @returns the scale needed; so that pixel height = scale * value.
  double _layoutJustified(Size size) {
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

    return scale;
  }

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
    final fontSize = style?.fontSize ?? 16;
    final lineHeight = (style?.height ?? 1) * (style?.fontSize ?? 16);
    verticalSpace ??= node.loc.height;

    /// Note comparing to [fontSize] and not [lineHeight] here to allow squeezing single line labels
    /// beneath the specified style.height (line spacing) down to actual height of characters
    /// (fontSize).
    if (verticalSpace < fontSize) {
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

  void _layoutFlow(double valueScale) {
    Map<SankeyLayoutNode, double> destTops = {};
    for (final source in drawNodes) {
      double sourceTop = 0;
      for (final flow in source.node.outgoingFlows) {
        final flowWidth = flow.value * valueScale;

        final dest = layouts[flow.destination]!;
        final destTop = destTops[dest] ?? 0;
        final destCenter = destTop + flowWidth / 2;
        final sourceCenter = sourceTop + flowWidth / 2;
        final destBottom = destTop + flowWidth;
        final sourceBottom = sourceTop + flowWidth;

        final Path path;
        if (flowWidth < 0.8 * levelHoriPad) {
          /// Use a closed path instead of just a simple bezier and drawing with a wide stroke width
          /// to enable easy hit testing.
          path = _generateOffsetPath(
            source.loc.topRight.translate(-1, sourceCenter),
            source.loc.topRight.translate(levelHoriPad / 2, sourceCenter),
            dest.loc.topLeft.translate(-levelHoriPad / 2, destCenter),
            dest.loc.topLeft.translate(1, destCenter),
            width: flowWidth,
          );
        } else {
          /// The above works well generally, but has some weird artifacts if it's too wide (same
          /// with both the filled path and normal stroked drawing). Fallback in this case to a
          /// filled path with double bezier boundaries. In general this is wrong though as it makes
          /// the line look too narrow. Lookup bezier offseting.
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
        }
        drawFlows.add(SankeyLayoutFlow(
          flow: flow,
          source: source,
          destination: dest,
          path: path,
          paint: Paint()
            ..color = flow.color.withAlpha(100)
            ..style = PaintingStyle.fill,
        ));
        sourceTop += flowWidth;
        destTops[dest] = destTop + flowWidth;
      }
    }
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
        oldDelegate.valueToString != valueToString ||
        oldDelegate.layout != layout;
  }

  SankeyNode? nodeHitTest(Offset loc) {
    for (final node in drawNodes) {
      if (node.loc.contains(loc)) return node.node;
    }
    for (final flow in drawFlows) {
      if (flow.path.contains(loc)) return flow.flow.focusNode;
    }
    return null;
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

/// ChatGPT generated
Path _generateOffsetPath(
  Offset p0,
  Offset p1,
  Offset p2,
  Offset p3, {
  required double width,
  int segments = 30,
}) {
  List<Offset> leftOffsets = [];
  List<Offset> rightOffsets = [];

  for (int i = 0; i <= segments; i++) {
    double t = i / segments;

    Offset pt = _cubicBezierPoint(p0, p1, p2, p3, t);
    Offset tangent = _cubicBezierTangent(p0, p1, p2, p3, t);
    Offset normal = _normalize(Offset(-tangent.dy, tangent.dx));

    leftOffsets.add(pt + normal * (width / 2));
    rightOffsets.add(pt - normal * (width / 2));
  }

  // Build the path for the filled outline
  Path outlinePath = Path()..moveTo(leftOffsets.first.dx, leftOffsets.first.dy);
  for (final pt in leftOffsets) {
    outlinePath.lineTo(pt.dx, pt.dy);
  }
  for (final pt in rightOffsets.reversed) {
    outlinePath.lineTo(pt.dx, pt.dy);
  }
  outlinePath.close();
  return outlinePath;
}

Offset _cubicBezierPoint(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
  double mt = 1 - t;
  return p0 * mt * mt * mt + p1 * 3 * mt * mt * t + p2 * 3 * mt * t * t + p3 * t * t * t;
}

Offset _cubicBezierTangent(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
  double mt = 1 - t;
  return (p1 - p0) * (3 * mt * mt) + (p2 - p1) * (6 * mt * t) + (p3 - p2) * (3 * t * t);
}

Offset _normalize(Offset v) {
  final length = v.distance;
  return length == 0 ? Offset.zero : v / length;
}
