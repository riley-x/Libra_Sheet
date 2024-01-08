import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/components/cards/libra_chip.dart';
import 'package:libra_sheet/data/app_state/account_state.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/objects/transaction.dart';
import 'package:provider/provider.dart';

class TransactionCard extends StatelessWidget {
  const TransactionCard({
    super.key,
    required this.trans,
    this.maxRowsForName = 1,
    this.onSelect,
    this.margin,
    this.showTags = true,
    this.rightContent,
  });

  final Transaction trans;
  final int? maxRowsForName;
  final Function(Transaction)? onSelect;
  final EdgeInsets? margin;
  final bool showTags;
  final Widget? rightContent;

  static const double colorIndicatorWidth = 4;
  static const double colorIndicatorOffset = 10;

  @override
  Widget build(BuildContext context) {
    final color = (trans.category.level == 0) ? Colors.transparent : trans.category.color;

    bool isUncategorized = trans.category == Category.income || trans.category == Category.expense;
    bool isInvestment = trans.category == Category.investment;

    final signedReimb = (trans.value > 0) ? -trans.totalReimbusrements : trans.totalReimbusrements;
    final valueAfterReimb = trans.value + signedReimb;

    return LimitedBox(
      maxWidth: 500,
      child: Card(
        margin: margin ?? const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        shape: (isUncategorized && valueAfterReimb != 0)
            ? RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).colorScheme.error),
                borderRadius: BorderRadius.circular(8),
              )
            : (isInvestment)
                ? RoundedRectangleBorder(
                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
        // color: Color.alphaBlend(
        //     trans.account?.color?.withAlpha(30) ?? Theme.of(context).colorScheme.primaryContainer,
        //     Theme.of(context).colorScheme.surface),
        surfaceTintColor: color,
        shadowColor: (isUncategorized || isInvestment) ? Colors.transparent : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onSelect?.call(trans),
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
                  // padding: const EdgeInsets.only(),
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
                ),
              ],
            ),
          ),
        ),
      ),
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

    String afterReimbValue() {
      final signedReimb =
          (trans.value > 0) ? -trans.totalReimbusrements : trans.totalReimbusrements;
      return "(${(trans.value + signedReimb).dollarString()})";
    }

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
                if (trans.nAllocations > 0) ...[
                  _NumberIndicator(trans.nAllocations, true),
                  const SizedBox(width: 10),
                ],
                if (trans.totalReimbusrements > 0) ...[
                  Text(
                    afterReimbValue(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: (trans.value < 0) ? Colors.red : Colors.green,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  trans.value.dollarString(),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: (trans.value < 0) ? Colors.red : Colors.green),
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
        shape: BoxShape.circle,
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
