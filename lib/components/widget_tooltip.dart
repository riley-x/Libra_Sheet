import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A wrapper widget that allows creating a tooltip via a Widget. Hovering over [child] shows
/// [tooltip].
class WidgetTooltip extends StatefulWidget {
  const WidgetTooltip({
    super.key,
    required this.tooltip,
    required this.child,
    this.delay = 500,
    this.verticalOffset = 24,
    this.beforeHover,
  });

  final Widget tooltip;
  final Widget child;
  final int delay;
  final double verticalOffset;
  final Future? Function()? beforeHover;

  @override
  State<WidgetTooltip> createState() => _WidgetTooltipState();
}

class _WidgetTooltipState extends State<WidgetTooltip> {
  final OverlayPortalController _overlayController = OverlayPortalController();
  Future? _userFuture;
  Timer? _timer;
  bool visible = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void show() async {
    if (_userFuture != null) await _userFuture;
    if (mounted) {
      _overlayController.show();
    }
  }

  void _handleMouseEnter(PointerEnterEvent event) {
    if (!visible) {
      _userFuture = widget.beforeHover?.call();
      _timer ??= Timer(Duration(milliseconds: widget.delay), show);
    }
  }

  void _handleMouseExit(PointerExitEvent event) {
    _timer?.cancel();
    _timer = null;
    _userFuture = null;
    _overlayController.hide();
  }

  Widget _buildTooltipOverlay(BuildContext context) {
    final OverlayState overlayState = Overlay.of(context, debugRequiredFor: widget);
    final RenderBox box = this.context.findRenderObject()! as RenderBox;
    final Offset target = box.localToGlobal(
      box.size.center(Offset.zero),
      ancestor: overlayState.context.findRenderObject(),
    );

    return Positioned.fill(
      bottom: MediaQuery.maybeViewInsetsOf(context)?.bottom ?? 0.0,
      child: CustomSingleChildLayout(
        delegate: _TooltipPositionDelegate(
          target: target,
          verticalOffset: widget.verticalOffset,
          preferBelow: true,
        ),
        child: widget.tooltip,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _overlayController,
      overlayChildBuilder: _buildTooltipOverlay,
      child: MouseRegion(
        onEnter: _handleMouseEnter,
        onExit: _handleMouseExit,
        child: widget.child,
      ),
    );
  }
}

/// A delegate for computing the layout of a tooltip to be displayed above or
/// below a target specified in the global coordinate system.
class _TooltipPositionDelegate extends SingleChildLayoutDelegate {
  /// Creates a delegate for computing the layout of a tooltip.
  _TooltipPositionDelegate({
    required this.target,
    required this.verticalOffset,
    required this.preferBelow,
  });

  /// The offset of the target the tooltip is positioned near in the global
  /// coordinate system.
  final Offset target;

  /// The amount of vertical distance between the target and the displayed
  /// tooltip.
  final double verticalOffset;

  /// Whether the tooltip is displayed below its widget by default.
  ///
  /// If there is insufficient space to display the tooltip in the preferred
  /// direction, the tooltip will be displayed in the opposite direction.
  final bool preferBelow;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return positionDependentBox(
      size: size,
      childSize: childSize,
      target: target,
      verticalOffset: verticalOffset,
      preferBelow: preferBelow,
    );
  }

  @override
  bool shouldRelayout(_TooltipPositionDelegate oldDelegate) {
    return target != oldDelegate.target ||
        verticalOffset != oldDelegate.verticalOffset ||
        preferBelow != oldDelegate.preferBelow;
  }
}
