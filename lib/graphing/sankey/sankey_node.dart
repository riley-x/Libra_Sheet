import 'package:flutter/material.dart';

class SankeyNode {
  final String label;
  final Color color;
  final double value;

  List<SankeyFlow> incomingFlows = [];
  List<SankeyFlow> outgoingFlows = [];

  SankeyNode({
    required this.label,
    required this.color,
    required this.value,
  });

  void addSource(SankeyNode node, {Color? color, double? value}) {
    final lesserNode = (node.value > this.value) ? this : node;
    final flow = SankeyFlow(
      source: node,
      destination: this,
      color: color ?? lesserNode.color,
      value: value ?? lesserNode.value,
    );
    incomingFlows.add(flow);
    node.outgoingFlows.add(flow);
  }

  void addDestination(SankeyNode node, {Color? color, double? value}) {
    node.addSource(this, color: color, value: value);
  }

  @override
  String toString() {
    return "SankeyNode($label): $value ${incomingFlows.length}-${outgoingFlows.length}";
  }
}

class SankeyFlow {
  final SankeyNode source;
  final SankeyNode destination;
  final Color color;
  final double value;

  const SankeyFlow({
    required this.source,
    required this.destination,
    required this.color,
    required this.value,
  });
}
