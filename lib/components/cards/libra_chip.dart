import 'package:flutter/material.dart';
import 'package:libra_sheet/theme/colorscheme.dart';

/// A tighter, simple chip that avoids the Material minimum touch size
class LibraChip extends StatelessWidget {
  const LibraChip(
    this.text, {
    super.key,
    this.onTap,
    this.color,
    this.style,
  });

  final String text;
  final Function()? onTap;
  final Color? color;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color ?? Theme.of(context).colorScheme.secondaryContainer,
        ),
        child: Text(
          text,
          style: (style ?? Theme.of(context).textTheme.labelLarge)
              ?.copyWith(color: (color == null) ? null : adaptiveTextColor(color!)),
        ),
      ),
    );
  }
}
