import 'package:flutter/material.dart';

class TransactionContextMenu extends StatelessWidget {
  const TransactionContextMenu({
    super.key,
    this.onSelect,
    this.onDuplicate,
  });

  final Function()? onSelect;
  final Function()? onDuplicate;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceVariant,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ContextMenuItem(text: 'Multi-select', onTap: onSelect, isFirst: true),
            ContextMenuItem(text: 'Duplicate', onTap: onDuplicate, isLast: true),
          ],
        ),
      ),
    );
  }
}

/// This contains a single menu item for dialog menus. It should only be used inside the build of a
/// [showDialog] because the buttons will pop the menu from the Navigator.
class ContextMenuItem extends StatelessWidget {
  const ContextMenuItem({
    super.key,
    required this.text,
    this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  final String text;
  final bool isFirst;
  final bool isLast;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: InkWell(
        onTap: () {
          onTap?.call();
          Navigator.pop(context, text);
        },
        borderRadius: BorderRadius.vertical(
          top: Radius.circular((isFirst) ? 10 : 0),
          bottom: Radius.circular((isLast) ? 10 : 0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: Text(
            text,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}
