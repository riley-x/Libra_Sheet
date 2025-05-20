import 'dart:math';

import 'package:libra_sheet/graphing/sankey/sankey_node.dart';

class SankeyTree {
  final SankeyTreeNode outgoingBranch;
  final SankeyTreeNode incomingBranch;

  SankeyNode get root => incomingBranch.node;

  SankeyTree(SankeyNode root, {required double Function(int layer) paddingFn})
      : outgoingBranch = SankeyTreeNode(
          layer: 0,
          node: root,
          parent: null,
          paddingFn: paddingFn,
          outgoing: true,
        ),
        incomingBranch = SankeyTreeNode(
          layer: 0,
          node: root,
          parent: null,
          paddingFn: paddingFn,
          outgoing: false,
        );

  @override
  String toString() {
    final buffer = StringBuffer();

    void writeNode(SankeyTreeNode node, String prefix, bool isLast) {
      buffer.writeln('$prefix${isLast ? "└── " : "├── "}${node.node.label}: ${node.node.value}');
      final childPrefix = prefix + (isLast ? "    " : "│   ");
      for (var i = 0; i < node.children.length; i++) {
        writeNode(node.children[i], childPrefix, i == node.children.length - 1);
      }
    }

    buffer.writeln('Root node: ${root.label}: ${root.value}');
    buffer.writeln('Income tree:');
    for (var i = 0; i < incomingBranch.children.length; i++) {
      writeNode(incomingBranch.children[i], '', i == incomingBranch.children.length - 1);
    }
    buffer.writeln('Expense tree:');
    for (var i = 0; i < outgoingBranch.children.length; i++) {
      writeNode(outgoingBranch.children[i], '', i == outgoingBranch.children.length - 1);
    }
    return buffer.toString();
  }
}

class SankeyTreeNode {
  final int layer;
  late final int maxDescendantLayer;
  final double layerPerElemPadding;
  late final double totalPadding;
  final SankeyNode node;
  final SankeyTreeNode? parent;
  final List<SankeyTreeNode> children = [];

  SankeyTreeNode({
    required this.layer,
    required this.node,
    required this.parent,
    required bool outgoing,
    required double Function(int layer) paddingFn,
  }) : layerPerElemPadding = paddingFn.call(layer) {
    final flows = outgoing ? node.outgoingFlows : node.incomingFlows;
    var maxDescendantLayer = layer;
    var totalPadding = 0.0;
    for (final flow in flows) {
      final child = outgoing ? flow.destination : flow.source;
      if (child.value > node.value) {
        throw SankeyTreeLayoutException(
            "Child has greater value than parent: ${child.label}=${child.value} ${node.label}=${node.value}");
      }

      final parentFlows = outgoing ? child.incomingFlows : child.outgoingFlows;
      if (parentFlows.length != 1) {
        throw SankeyTreeLayoutException(
            "Expected node to only have one ${outgoing ? "source" : "destination"}: ${child.label}");
      }

      final childNode = SankeyTreeNode(
        layer: layer + 1,
        node: child,
        parent: this,
        outgoing: outgoing,
        paddingFn: paddingFn,
      );
      children.add(childNode);
      maxDescendantLayer = max(maxDescendantLayer, childNode.maxDescendantLayer);
      totalPadding += childNode.totalPadding;
      if (flow != flows.first) totalPadding += layerPerElemPadding;
    }
    this.maxDescendantLayer = maxDescendantLayer;
    this.totalPadding = totalPadding;
  }
}

SankeyTree createTree(List<SankeyNode> nodes, {required double Function(int layer) paddingFn}) {
  SankeyNode? keyNode;
  bool multipleNodes = false;
  for (final node in nodes) {
    if (node.value > (keyNode?.value ?? 0)) {
      keyNode = node;
      multipleNodes = false;
    } else if (node.value == keyNode?.value) {
      multipleNodes = true;
    }
  }
  if (keyNode == null) {
    throw SankeyTreeLayoutException("Node list is empty.");
  }
  if (multipleNodes) {
    throw SankeyTreeLayoutException("Multiple candidate key nodes with max value ${keyNode.value}");
  }
  return SankeyTree(keyNode, paddingFn: paddingFn);
}

class SankeyTreeLayoutException implements Exception {
  final String message;

  SankeyTreeLayoutException([this.message = ""]);

  @override
  String toString() => message;
}
