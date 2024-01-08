import 'package:flutter/material.dart';

/// A row with two children that aligns them right and left, respectively. They must both have
/// fixed widths.
class RightLeftRow extends StatelessWidget {
  const RightLeftRow({
    super.key,
    required this.left,
    required this.right,
    this.leftWidth = 200,
    this.rightWidth = 300,
    this.spacing = 20,
    this.verticalAlignment = CrossAxisAlignment.center,
  });

  final Widget left;
  final Widget right;
  final double leftWidth;
  final double rightWidth;
  final double spacing;
  final CrossAxisAlignment verticalAlignment;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: verticalAlignment,
      children: [
        SizedBox(
          width: leftWidth,
          child: Align(
            alignment: Alignment.centerRight,
            child: left,
          ),
        ),
        SizedBox(width: spacing),
        SizedBox(
          width: rightWidth,
          child: Align(
            alignment: Alignment.centerLeft,
            child: right,
          ),
        ),
      ],
    );
  }
}
