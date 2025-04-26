import 'package:flutter/material.dart';

class SankeyNode {
  final String label;
  final Color color;
  final double value;

  List<SankeyFlow> sources = [];
  List<SankeyFlow> destinations = [];

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
    sources.add(flow);
    node.destinations.add(flow);
  }

  void addDestination(SankeyNode node, {Color? color, double? value}) {
    node.addSource(this, color: color, value: value);
  }
}

class SankeyFlow {
  final SankeyNode source;
  final SankeyNode destination;
  final Color color;
  final double value;

  SankeyFlow({
    required this.source,
    required this.destination,
    required this.color,
    required this.value,
  });
}
