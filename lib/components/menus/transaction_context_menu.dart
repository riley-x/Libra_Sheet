import 'package:flutter/material.dart';
import 'package:libra_sheet/components/menus/context_menu.dart';

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
