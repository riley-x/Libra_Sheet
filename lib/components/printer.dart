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
  const ConstraintsPrinter({super.key, required this.child, this.msg});
  final Widget child;
  final String? msg;

  @override
  Widget build(BuildContext context) {
    return ConstraintsTransformBox(
      constraintsTransform: (it) {
        debugPrint("${msg ?? 'Incoming constraints:'} $it");
        return it;
      },
      child: child,
    );
  }
}
