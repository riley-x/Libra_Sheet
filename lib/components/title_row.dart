import 'package:flutter/material.dart';

/// Creates a row with a centered title and optionally left or right-aligned content
class TitleRow extends StatelessWidget {
  const TitleRow({super.key, this.title, this.right, this.left});

  final Widget? title;
  final Widget? right;
  final Widget? left;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        if (title != null) title!,
        Align(alignment: Alignment.centerLeft, child: left),
        Align(alignment: Alignment.centerRight, child: right),
      ],
    );
  }
}
