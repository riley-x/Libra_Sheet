import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// This widget controls the hover for a generic graph. The [child] is drawn next to the mouse
/// position position and placed to not fall off the graph boundaries.
///
/// This widget should be used in a [Stack] with a [CustomPaint] such that they have the same size.
class MouseHover extends SingleChildRenderObjectWidget {
  final Offset loc;

  const MouseHover({
    super.key,
    super.child,
    required this.loc,
  });

  @override
  RenderMouseHover createRenderObject(BuildContext context) {
    return RenderMouseHover(loc: loc);
  }

  @override
  void updateRenderObject(BuildContext context, RenderMouseHover renderObject) {
    if (renderObject.loc != loc) {
      renderObject.loc = loc;
      renderObject.markNeedsPaint();
    }
  }
}

class RenderMouseHover extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  static const _offset = 10.0;
  Offset loc;

  RenderMouseHover({required this.loc});

  @override
  void performLayout() {
    size = constraints.biggest;
    child?.layout(constraints.loosen());
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;

    final placeRight = loc.dx + _offset + child!.size.width < size.width;
    final placeBottom = loc.dy + _offset + child!.size.height < size.height;
    Offset childPos;
    if (placeRight && placeBottom) {
      childPos = loc.translate(_offset, _offset);
    } else if (placeRight && !placeBottom) {
      childPos = loc.translate(_offset, -child!.size.height);
    } else if (!placeRight && placeBottom) {
      childPos = loc.translate(-child!.size.width, _offset);
    } else {
      childPos = loc.translate(-child!.size.width, -child!.size.height);
    }

    childPos = Offset(
      child!.size.width > size.width
          ? 0
          : clampDouble(childPos.dx, 0, size.width - child!.size.width),
      child!.size.height > size.height
          ? 0
          : clampDouble(childPos.dy, 0, size.height - child!.size.height),
    );
    context.paintChild(child!, childPos);
  }
}
