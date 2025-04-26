import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/sankey/sankey_node.dart';

class SankeyPainter extends CustomPainter {
  final ThemeData theme;
  final List<List<SankeyNode>> data;

  final double nodeWidth = 20;
  final double nodeVertDesiredMinPad = 5;

  List<SankeyLayoutNode> drawNodes = [];
  List<SankeyLayoutFlow> drawFlows = [];

  SankeyPainter({super.repaint, required this.theme, required this.data});

  void _layout(Size size) {
    drawNodes = [];
    drawFlows = [];

    final nLevels = data.length;
    if (nLevels <= 1) return;

    final levelHoriPad = (size.width - nodeWidth * nLevels) / (nLevels - 1);
    if (levelHoriPad <= 0) return;

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
    for (final (i, level) in data.indexed) {
      final x = i * (nodeWidth + levelHoriPad);
      _layoutLayerJustified(level, x, size.height, scale);
    }
  }

  /// Spreads all nodes equally, as much as possible, filling the full height
  void _layoutLayerJustified(List<SankeyNode> level, double x, double height, double scale) {
    if (level.length == 1) {
      final node = level[0];
      final nodeHeight = node.value * scale;
      drawNodes.add(SankeyLayoutNode(
        node: node,
        loc: Rect.fromLTWH(x, (height - nodeHeight) / 2, nodeWidth, nodeHeight),
      ));
      return;
    }

    double sum = 0;
    for (final node in level) {
      sum += node.value;
    }

    double y = 0;
    double vertPad = level.length > 1 ? (height - sum * scale) / (level.length - 1) : 0;
    for (final node in level) {
      drawNodes.add(SankeyLayoutNode(
        node: node,
        loc: Rect.fromLTWH(x, y, nodeWidth, node.value * scale),
      ));
      y += node.value * scale + vertPad;
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

  @override
  void paint(Canvas canvas, Size size) {
    _layout(size);
    for (final node in drawNodes) {
      canvas.drawRect(
        node.loc,
        Paint()
          ..color = node.node.color
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(SankeyPainter oldDelegate) {
    return oldDelegate.data != data;
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

  SankeyLayoutFlow({required this.flow, required this.source, required this.destination});
}
