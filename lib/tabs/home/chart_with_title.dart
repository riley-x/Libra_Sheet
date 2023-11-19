import 'package:flutter/material.dart';

class ChartWithTitle extends StatelessWidget {
  final double height;
  final String? textLeft;
  final String? textRight;
  final TextStyle? textStyle;
  final EdgeInsets padding;
  final Widget? child;

  ChartWithTitle(
      {super.key,
      required this.height,
      this.textLeft,
      this.textRight,
      this.textStyle,
      this.padding = EdgeInsets.zero,
      this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10) + padding,
        child: Column(
          children: [
            if (textLeft != null || textRight != null)
              Row(
                children: [
                  if (textLeft != null)
                    Text(
                      textLeft!,
                      style: textStyle,
                    ),
                  Spacer(),
                  if (textRight != null)
                    Text(
                      textRight!,
                      style: textStyle,
                    ),
                ],
              ),
            if (child != null) Expanded(child: child!),
          ],
        ),
      ),
    );
  }
}
