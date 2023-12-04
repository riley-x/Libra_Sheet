import 'package:flutter/material.dart';

class NoAnimationRoute<T> extends PageRouteBuilder<T> {
  NoAnimationRoute(
    Widget Function(BuildContext) builder,
  ) : super(
          pageBuilder: (context, animation1, animation2) => builder(context),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        );
}
