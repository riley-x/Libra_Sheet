import 'package:flutter/material.dart';

class AnalyzeTabViewSelector extends StatelessWidget {
  const AnalyzeTabViewSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Button(text: 'test', selected: false, width: 100),
      ],
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    super.key,
    required this.text,
    required this.selected,
    required this.width,
  });

  static const double height = 20;

  final String text;
  final bool selected;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
      alignment: Alignment.center,
      child: Text('asdf'),
    );
  }
}
