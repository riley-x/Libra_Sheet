import 'dart:math';
import 'package:libra_sheet/graphing/sankey/sankey_node.dart';

class SankeyTree {
  final SankeyTreeNode outgoingBranch;
  final SankeyTreeNode incomingBranch;
  final List<SankeyTreeLayer> outgoingLayers = [];
  final List<SankeyTreeLayer> incomingLayers = [];
  final double Function(int layer) paddingFn;

  SankeyNode get root => incomingBranch.node;

  SankeyTree(SankeyNode root, {required this.paddingFn})
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
        ) {
    for (int i = 0; i <= outgoingBranch.maxDescendantLayer; i++) {
      outgoingLayers.add(SankeyTreeLayer(i));
    }
    for (int i = 0; i <= incomingBranch.maxDescendantLayer; i++) {
      incomingLayers.add(SankeyTreeLayer(i));
    }
    outgoingBranch.collateLayer(outgoingLayers);
    incomingBranch.collateLayer(incomingLayers);
  }

  (double valueSacle, double paddingScale) getScale(double height, double maxPadding) {
    double valueScale = double.maxFinite;
    double paddingScale = double.maxFinite;
    for (final layer in outgoingLayers.skip(1).toList() + incomingLayers.skip(1).toList()) {
      final (layerVScale, layerPScale) = _getScale(layer, height, maxPadding);
      if (layerPScale < paddingScale) {
        paddingScale = layerPScale;
        // print("Updating paddingScale: ${layer.layer} ${paddingScale}");
      }
      if (layerVScale < valueScale) {
        valueScale = layerVScale;
        // print("Updating valueScale: ${layer.first.node.label} ${valueScale}");
      }
    }
    return (valueScale, paddingScale);
  }

  (double valueSacle, double paddingScale) _getScale(
    SankeyTreeLayer layer,
    double height,
    double maxPadding,
  ) {
    double totalPadding = layer.padding;
    double totalValue = 0;
    for (final node in layer.nodes) {
      totalPadding += node.totalPadding;
      totalValue += node.node.value;
    }

    // final layerPadding = paddingFn.call(layer.layer);
    // SankeyTreeNode? previous;
    // for (final node in layer.nodes) {
    //   if (_canSqueezeIntoSiblingPadding(layer.layer, previous, node)) {
    //     print("Squeezing ${node.node.label}: ${totalPadding} - ${previous!.totalPadding / 2}");
    //     node.offset = -0.5 * previous!.totalPadding - layerPadding;
    //     totalPadding += node.offset;
    //   }
    //   previous = node;
    // }

    double paddingScale;
    double valueScale;
    if (totalPadding > maxPadding) {
      paddingScale = maxPadding / totalPadding;
      valueScale = (height - maxPadding) / totalValue;
    } else {
      paddingScale = 1;
      valueScale = (height - totalPadding) / totalValue;
    }
    return (valueScale, paddingScale);
  }

  bool _canSqueezeIntoSiblingPadding(int layer, SankeyTreeNode? previous, SankeyTreeNode current) {
    if (previous == null) return false;
    if (current.maxDescendantLayer != layer) return false;
    if (previous.totalPadding == 0) return false;
    // TODO
    return true;
  }

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
  final double childPadding;
  late final double totalPadding;
  final SankeyNode node;
  final SankeyTreeNode? parent;
  final List<SankeyTreeNode> children = [];
  double offset = 0;

  SankeyTreeNode({
    required this.layer,
    required this.node,
    required this.parent,
    required bool outgoing,
    required double Function(int layer) paddingFn,
  }) : childPadding = paddingFn.call(layer + 1) {
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
      if (flow != flows.first) totalPadding += childPadding;
    }
    this.maxDescendantLayer = maxDescendantLayer;
    this.totalPadding = totalPadding;
  }

  void collateLayer(List<SankeyTreeLayer> agg) {
    agg[layer].nodes.add(this);
    for (final child in children) {
      child.collateLayer(agg);
      if (child != children.last) {
        for (int i = layer + 1; i < agg.length; i++) {
          agg[i].padding += childPadding;
        }
      }
    }
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

class SankeyTreeLayer {
  final int layer;
  List<SankeyTreeNode> nodes = [];
  double padding = 0;

  SankeyTreeLayer(this.layer);
}
