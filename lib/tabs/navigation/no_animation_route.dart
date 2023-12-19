import 'package:flutter/material.dart';

class NoAnimationRoute<T> extends PageRouteBuilder<T> {
  NoAnimationRoute(
    Widget Function(BuildContext) builder,
  ) : super(
          /// Wrap the child with a ModalBarrier since the default PageRoute includes one, but
          /// the barrier is set to non-dismissable, which causes a beep whenever you click any
          /// dead area.
          ///
          /// https://github.com/flutter/flutter/issues/117342.
          pageBuilder: (context, animation1, animation2) => Stack(
            fit: StackFit.expand,
            children: [
              ModalBarrier(onDismiss: () {}),
              builder(context),
            ],
          ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          opaque: true,
        );
}
