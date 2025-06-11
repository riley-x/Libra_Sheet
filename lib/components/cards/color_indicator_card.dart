import 'package:flutter/material.dart';
import 'package:libra_sheet/components/menus/context_menu.dart';
import 'package:libra_sheet/flutter_utils/context_menu_blocking.dart';

/// A rounded card with a colored bar on the left and a shaded background to match. Content is
/// filled by passing [child].
class ColorIndicatorCard extends StatelessWidget {
  const ColorIndicatorCard({
    super.key,
    required this.child,
    this.color,
    this.borderColor,
    this.fillColor,
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.contextMenu,
  }) : assert(!(color != null && borderColor != null));

  final Widget child;
  final Color? color;
  final Color? borderColor;
  final Color? fillColor;
  final EdgeInsets margin;
  final Function()? onTap;
  final Widget? contextMenu;

  static const double colorIndicatorWidth = 4;
  static const double colorIndicatorOffset = 10;
  static const double verticalPadding = 4;
  static const padding = EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 8);

  Future<void> _onSecondaryTapUp(BuildContext context, TapUpDetails details) async {
    await showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => CustomSingleChildLayout(
        delegate: ContextMenuPositionDelegate(target: details.globalPosition),
        child: contextMenu,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
        color:
            fillColor ?? ((cs.brightness == Brightness.dark) ? cs.surfaceContainerLow : cs.surface),
        surfaceTintColor: (fillColor != null) ? null : color,
        shadowColor: (borderColor != null) ? Colors.transparent : null,
        child: ContextMenuBlocking(
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,

            /// Using a dialog for the context menu seems to be the best. ContextMenuController does
            /// not provide a way to close the menu outside of the region, so would need some
            /// wrapper listener that sits above everything else, listens everywhere and handles the
            /// closing. MenuAnchor doesn't prevent the creation of other menus and persists across
            /// some transitions.
            ///
            /// The downside of the dialog is that is blocks all mouse activity; would be nice to
            /// pass-through the hover effects still. Also, requires two right clicks to open another
            /// context menu.
            onSecondaryTapUp: (contextMenu == null) ? null : (it) => _onSecondaryTapUp(context, it),
            child: Padding(
              padding: padding,
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
                    padding: const EdgeInsets.only(
                      left: colorIndicatorWidth + colorIndicatorOffset,
                    ),
                    child: child,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
