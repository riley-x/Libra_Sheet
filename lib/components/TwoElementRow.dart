import 'package:flutter/material.dart';

/// A row with two fixed-width children that aligns them by default towards the center.
class TwoElementRow extends StatelessWidget {
  const TwoElementRow({
    super.key,
    required this.left,
    required this.right,
    this.leftWidth = 200,
    this.rightWidth = 280,
    this.spacing = 20,
    this.verticalAlignment = CrossAxisAlignment.center,
    this.leftAlign = Alignment.centerRight,
    this.rightAlign = Alignment.centerLeft,
  });

  final Widget left;
  final Widget right;
  final double leftWidth;
  final double rightWidth;
  final double spacing;
  final CrossAxisAlignment verticalAlignment;
  final Alignment leftAlign;
  final Alignment rightAlign;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: verticalAlignment,
      children: [
        SizedBox(
          width: leftWidth,
          child: Align(
            alignment: leftAlign,
            child: left,
          ),
        ),
        SizedBox(width: spacing),
        SizedBox(
          width: rightWidth,
          child: Align(
            alignment: rightAlign,
            child: right,
          ),
        ),
      ],
    );
  }
}
