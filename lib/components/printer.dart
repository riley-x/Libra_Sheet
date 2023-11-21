import 'package:flutter/material.dart';

class Printer extends StatelessWidget {
  final int test;
  const Printer(this.test, {super.key});

  @override
  Widget build(BuildContext context) {
    print('Printer! $test');
    return Placeholder();
  }
}
