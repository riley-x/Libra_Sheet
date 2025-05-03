import 'package:flutter/material.dart';

enum SankeyPriority { lesser, source, destination }

class SankeyNode<T> {
  final String label;
  final Color color;
  final double value;
  final Alignment labelAlignment;
  final T? data;

  List<SankeyFlow> incomingFlows = [];
  List<SankeyFlow> outgoingFlows = [];

  SankeyNode({
    required this.label,
    required this.color,
    required this.value,
    this.labelAlignment = Alignment.centerRight,
    this.data,
  });

  void addSource(
    SankeyNode node, {
    Color? color,
    double? value,
    SankeyPriority focus = SankeyPriority.lesser,
  }) {
    final focusNode = switch (focus) {
      SankeyPriority.source => node,
      SankeyPriority.destination => this,
      SankeyPriority.lesser => (node.value > this.value) ? this : node,
    };
    final flow = SankeyFlow(
      source: node,
      destination: this,
      focus: focus,
      color: color ?? focusNode.color,
      value: value ?? focusNode.value,
    );
    incomingFlows.add(flow);
    node.outgoingFlows.add(flow);
  }

  void addDestination(
    SankeyNode node, {
    Color? color,
    double? value,
    SankeyPriority focus = SankeyPriority.lesser,
  }) {
    node.addSource(this, color: color, value: value, focus: focus);
  }

  @override
  String toString() {
    return "SankeyNode($label): $value ${incomingFlows.length}-${outgoingFlows.length}";
  }
}

class SankeyFlow {
  final SankeyNode source;
  final SankeyNode destination;
  final SankeyPriority focus;
  final Color color;
  final double value;

  SankeyNode get focusNode => switch (focus) {
        SankeyPriority.source => source,
        SankeyPriority.destination => destination,
        SankeyPriority.lesser => (source.value > destination.value) ? destination : source,
      };

  const SankeyFlow({
    required this.source,
    required this.destination,
    required this.focus,
    required this.color,
    required this.value,
  });
}
