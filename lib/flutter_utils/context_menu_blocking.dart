import 'dart:js_interop';

import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Prevents browser context menu from showing. All widgets that listen to right clicks
/// should wrap with this.
class ContextMenuBlocking extends StatelessWidget {
  final Widget child;

  const ContextMenuBlocking({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        if (event.buttons == kSecondaryMouseButton) {
          // Prevent context menu on right-click
          web.window.addEventListener('contextmenu', _preventContextMenu.toJS);
        }
      },
      onPointerUp: (event) {
        // Remove the event listener after handling
        web.window.removeEventListener('contextmenu', _preventContextMenu.toJS);
      },
      child: child,
    );
  }
}

void _preventContextMenu(web.Event event) {
  event.preventDefault();
}
