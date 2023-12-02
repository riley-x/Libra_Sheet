import 'package:flutter/material.dart';

class Printer extends StatelessWidget {
  final int test;
  const Printer(this.test, {super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('Printer! $test');
    return Placeholder();
  }
}

class ConstraintsPrinter extends StatelessWidget {
  const ConstraintsPrinter(this.child, {super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstraintsTransformBox(
      constraintsTransform: (it) {
        debugPrint("Incoming constraints: $it");
        return it;
      },
      child: child,
    );
  }
}
