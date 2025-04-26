import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/sankey/sankey_node.dart';

class SankeyPainter extends CustomPainter {
  final ThemeData theme;
  final List<List<SankeyNode>> data;

  List<SankeyLayoutNode> drawNodes = [];
  List<SankeyLayoutFlow> drawFlows = [];

  SankeyPainter({super.repaint, required this.theme, required this.data});

  void _layout() {}

  @override
  void paint(Canvas canvas, Size size) {
    _layout();
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
