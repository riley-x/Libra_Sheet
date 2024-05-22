import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/transcoder/v1.dart';

/// Common class for positioning context menus.
///
/// This will try to position the child in the following order:
///   1. Bottom-right (top-right of child aligned to [target])
///   2. Top-right (bottom-right of child aligned to [target])
///   3. Bottom-most-right (left edge of child aligned to [target], moved down as far as possible)
///   4. Repeat 1-3 for left side.
///
/// Usage:
///     CustomSingleChildLayout(
///       delegate: ContextMenuPositionDelegate(
///         target: details.globalPosition,
///       ),
///       child: Text('Hello World!'),
///     ),
///
/// PS don't use ContextMenuController, really under-developed class. The example shown in
///     https://api.flutter.dev/flutter/widgets/ContextMenuController-class.html
/// does not provide a way to close the menu outside of the region, i.e. So would need some wrapper
/// listener that sits above everything else, listens everywhere and handles the closing.
class ContextMenuPositionDelegate extends SingleChildLayoutDelegate {
  ContextMenuPositionDelegate({required this.target, this.softMargin = const EdgeInsets.all(10)});

  /// The offset in the global coordinate system of where to create the tooltip.
  final Offset target;

  /// Minimum margins from the edge of the window to place the child when optimizing the location.
  /// In the fail case (i.e. neither top nor bottom aligned works), will break this margin.
  final EdgeInsets softMargin;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  /// Returns the global x offset for the top-left point of the child.
  double _getHorizontalPosition(Size size, Size childSize) {
    /// Place right (aligned with child left edge)
    if (target.dx + childSize.width <= size.width - softMargin.right) {
      return target.dx;
    }

    /// Place left (aligned with child right edge)
    else if (target.dx - childSize.width >= softMargin.left) {
      return target.dx - childSize.width;
    }

    /// Place as right as possible
    else {
      return size.width - childSize.width;
    }
  }

  /// Returns the global y offset for the top-left point of the child.
  double _getVerticalPosition(Size size, Size childSize) {
    /// Place bottom (aligned with child top edge)
    if (target.dy + childSize.height <= size.height - softMargin.bottom) {
      return target.dy;
    }

    /// Place top (aligned with child bottom edge)
    else if (target.dy - childSize.height >= softMargin.top) {
      return target.dy - childSize.height;
    }

    /// Place as bottom as possible
    else {
      return size.height - childSize.height;
    }
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return Offset(
      _getHorizontalPosition(size, childSize),
      _getVerticalPosition(size, childSize),
    );
  }

  @override
  bool shouldRelayout(ContextMenuPositionDelegate oldDelegate) {
    return target != oldDelegate.target;
  }
}
