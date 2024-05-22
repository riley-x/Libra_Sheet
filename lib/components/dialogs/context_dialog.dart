import 'package:flutter/material.dart';

/// Unused attempt at creating a context menu dialog that can pass-through mouse hover events.
class CustomRoute<T> extends OverlayRoute<T> {
  late OverlayEntry _modalBarrier;
  Widget _buildModalBarrier(BuildContext context) {
    return Placeholder();
  }

  @override
  Iterable<OverlayEntry> createOverlayEntries() {
    return [
      // _modalBarrier = OverlayEntry(builder: _buildModalBarrier),
      // This blocks all mouse events by itself!?
      OverlayEntry(
        builder: (context) => Text('hi'),
      ),
    ];
  }
}

Future<T?> showContextDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
  TraversalEdgeBehavior? traversalEdgeBehavior,
}) {
  final CapturedThemes themes = InheritedTheme.capture(
    from: context,
    to: Navigator.of(
      context,
      rootNavigator: useRootNavigator,
    ).context,
  );

  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(CustomRoute<T>());
}
