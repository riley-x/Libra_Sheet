import 'package:flutter/material.dart';

class ColorIndicatorCard extends StatelessWidget {
  const ColorIndicatorCard({
    super.key,
    required this.child,
    this.color,
    this.borderColor,
    this.margin = EdgeInsets.zero,
    this.onTap,
  }) : assert(!(color != null && borderColor != null));

  final Widget child;
  final Color? color;
  final Color? borderColor;
  final EdgeInsets margin;
  final Function()? onTap;

  static const double colorIndicatorWidth = 4;
  static const double colorIndicatorOffset = 10;

  @override
  Widget build(BuildContext context) {
    return LimitedBox(
      maxWidth: 500,
      child: Card(
        margin: margin,
        shape: (borderColor != null)
            ? RoundedRectangleBorder(
                side: BorderSide(color: borderColor!),
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        // color: Color.alphaBlend(
        //     trans.account?.color?.withAlpha(30) ?? Theme.of(context).colorScheme.primaryContainer,
        //     Theme.of(context).colorScheme.surface),
        surfaceTintColor: color ?? Theme.of(context).colorScheme.background,
        shadowColor: (borderColor != null) ? Colors.transparent : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Stack(
              /// We use a stack here to easily make the color indicator bar have the same height as
              /// the content via [Positioned].
              children: [
                Positioned(
                  left: 0,
                  width: colorIndicatorWidth,
                  top: 0,
                  bottom: 0,
                  child: Container(color: color),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: colorIndicatorWidth + colorIndicatorOffset),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
