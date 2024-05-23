import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/components/cards/color_indicator_card.dart';
import 'package:libra_sheet/components/cards/libra_chip.dart';
import 'package:libra_sheet/components/cards/transaction_tooltip.dart';
import 'package:libra_sheet/components/widget_tooltip.dart';
import 'package:libra_sheet/data/app_state/account_state.dart';
import 'package:libra_sheet/data/app_state/transaction_service.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/objects/transaction.dart';
import 'package:libra_sheet/theme/colorscheme.dart';
import 'package:provider/provider.dart';

/// This is used throughout the app as the main UI graphic for displaying the info from a single
/// transaction.
class TransactionCard extends StatelessWidget {
  const TransactionCard({
    super.key,
    required this.trans,
    this.maxRowsForName = 1,
    this.onTap,
    this.margin,
    this.showTags = true,
    this.showTooltip = true,
    this.rightContent,
    this.contextMenu,
    this.selected = false,
  });

  final Transaction trans;
  final int? maxRowsForName;
  final Function(Transaction)? onTap;
  final EdgeInsets? margin;
  final bool showTags;
  final Widget? rightContent;
  final bool showTooltip;
  final Widget? contextMenu;
  final bool selected;

  static const double colorIndicatorWidth = 4;
  static const double colorIndicatorOffset = 10;

  @override
  Widget build(BuildContext context) {
    final color = (trans.category.level == 0) ? null : trans.category.color;

    bool isUncategorized = trans.category.isUncategorized;
    bool isInvestment = trans.category == Category.other;

    final signedReimb = (trans.value > 0) ? -trans.totalReimbusrements : trans.totalReimbusrements;
    final valueAfterReimb = trans.value + signedReimb;

    final card = ColorIndicatorCard(
      color: color,
      borderColor: (isUncategorized && valueAfterReimb != 0)
          ? Theme.of(context).colorScheme.error
          : (isInvestment)
              ? Theme.of(context).colorScheme.primary
              : null,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      onTap: () => onTap?.call(trans),
      contextMenu: contextMenu,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TextElements(
            trans: trans,
            maxRowsForName: maxRowsForName,
            rightContent: rightContent,
          ),
          if (showTags && trans.tags.isNotEmpty) ...[
            const SizedBox(height: 3),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final tag in trans.tags)
                  LibraChip(
                    tag.name,
                    color: tag.color,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
              ],
            ),
          ]
        ],
      ),
    );

    if (!showTooltip) return card;
    return WidgetTooltip(
      verticalOffset: 30,
      delay: 1000,
      tooltip: TransactionTooltip(trans),
      beforeHover: () async {
        if (!trans.relationsAreLoaded()) {
          await context.read<TransactionService>().loadRelations(trans);
        }
      },
      child: card,
    );
  }
}

final _dtFormat = DateFormat("M/d/yy");

class _TextElements extends StatelessWidget {
  const _TextElements({
    required this.trans,
    required this.maxRowsForName,
    required this.rightContent,
  });

  final Transaction trans;
  final int? maxRowsForName;
  final Widget? rightContent;

  @override
  Widget build(BuildContext context) {
    /// TODO think of a cleaner way to not have to remember to watch AccountState every time you
    /// use an account.
    context.watch<AccountState>();

    final theme = Theme.of(context);
    var subText = '';
    if (trans.account != null) {
      subText += trans.account!.name;
    }
    if (subText.isNotEmpty) {
      subText += ', ';
    }
    subText += trans.category.name;
    if (trans.note.isNotEmpty) {
      if (subText.isNotEmpty) {
        subText += ' - ';
      }
      subText += trans.note;
    }

    final adjValue = trans.adjustedValue();
    final sign = (trans.value < 0) ? -1 : 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trans.name,
                maxLines: maxRowsForName,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                if (trans.totalReimbusrements != 0 && adjValue != 0) ...[
                  _AllocIndicator(trans.totalReimbusrements * sign, Category.ignore),
                  const SizedBox(width: 10),
                ],
                for (final alloc in trans.softAllocations) ...[
                  _AllocIndicator(alloc.value * sign, alloc.category),
                  const SizedBox(width: 10),
                ],
                if (adjValue != trans.value && adjValue != 0) ...[
                  _AllocIndicator(adjValue, trans.category),
                  const SizedBox(width: 10),
                ],
                Text(
                  trans.value.dollarString(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    // decoration: (adjValue == 0) ? TextDecoration.lineThrough : null,
                    color: (trans.value == 0)
                        ? null
                        : (adjValue == 0)
                            ? Theme.of(context).colorScheme.outline
                            : (trans.value < 0)
                                ? Colors.red
                                : Colors.green,
                    fontStyle: (trans.totalReimbusrements > 0 || trans.nAllocations > 0)
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ],
            ),
            Text(
              _dtFormat.format(trans.date),
            ),
          ],
        ),
        if (rightContent != null) rightContent!,
      ],
    );
  }
}

class _AllocIndicator extends StatelessWidget {
  const _AllocIndicator(this.value, this.category, {super.key});

  final int value;
  final Category category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 3, right: 3, bottom: 1),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: (category.isSpecial)
              ? BorderSide(
                  color: (category == Category.other)
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade700)
              : BorderSide.none,
          borderRadius: BorderRadius.circular(8),
        ),
        color: (category.isSpecial)
            ? null
            : Color.alphaBlend(
                category.color.withAlpha(200), Theme.of(context).colorScheme.background),
      ),
      child: Center(
        child: Text(
          value.dollarString(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: (category == Category.other)
                    ? Theme.of(context).colorScheme.primary
                    : (category.isSpecial)
                        ? Colors.grey.shade700
                        : adaptiveTextColor(category.color),
              ),
        ),
      ),
    );
  }
}

class _ReimbIndicator extends StatelessWidget {
  const _ReimbIndicator(this.value, {super.key});

  final int value;

  @override
  Widget build(BuildContext context) {
    final color = Colors.grey.shade700;
    return Container(
      padding: const EdgeInsets.only(left: 3, right: 3, bottom: 1),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: color),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Center(
        child: Text(
          value.dollarString(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ),
    );
  }
}

class _NumberIndicator extends StatelessWidget {
  const _NumberIndicator(this.n, this.isAlloc);

  final int n;
  final bool isAlloc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 3, right: 3, bottom: 1),
      decoration: BoxDecoration(
          color: (isAlloc)
              ? const Color.fromARGB(255, 221, 79, 145)
              : const Color.fromARGB(255, 100, 65, 197),
          borderRadius: BorderRadius.circular(4)
          // border: Border.all(
          //   color: Colors.white,
          //   width: 5.0,
          //   style: BorderStyle.solid,
          // ),
          ),
      child: Center(
        child: Text(
          (n < 10)
              ? '$n'
              : (isAlloc)
                  ? 'A'
                  : 'R',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
