import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/components/cards/libra_chip.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/transaction.dart';

class TransactionCard extends StatelessWidget {
  const TransactionCard({
    super.key,
    required this.trans,
    this.maxRowsForName = 1,
    this.onSelect,
    this.margin,
    this.showTags = true,
  });

  final Transaction trans;
  final int? maxRowsForName;
  final Function(Transaction)? onSelect;
  final EdgeInsets? margin;
  final bool showTags;

  static const double colorIndicatorWidth = 6;
  static const double colorIndicatorOffset = 10;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      // color: Color.alphaBlend(
      //     trans.account?.color?.withAlpha(30) ?? Theme.of(context).colorScheme.primaryContainer,
      //     Theme.of(context).colorScheme.surface),
      surfaceTintColor: trans.category?.color,
      // shadowColor: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onSelect?.call(trans),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Stack(
            children: [
              // Positioned(
              //   left: 0,
              //   width: colorIndicatorWidth,
              //   top: 0,
              //   bottom: 0,
              //   child: Container(color: trans.category?.color ?? Colors.transparent),
              // ),
              Padding(
                // padding: const EdgeInsets.only(left: colorIndicatorWidth + colorIndicatorOffset),
                padding: const EdgeInsets.only(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TextElements(
                      trans: trans,
                      maxRowsForName: maxRowsForName,
                    ),
                    if (showTags && trans.tags?.isNotEmpty == true) ...[
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final tag in trans.tags!)
                            LibraChip(
                              tag.name,
                              color: tag.color,
                              style: Theme.of(context).textTheme.labelSmall,
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
    );
  }
}

final _dtFormat = DateFormat("M/d/yy");

class _TextElements extends StatelessWidget {
  const _TextElements({
    super.key,
    required this.trans,
    required this.maxRowsForName,
  });

  final Transaction trans;
  final int? maxRowsForName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var subText = '';
    if (trans.account != null) {
      subText += trans.account!.name;
    }
    if (trans.category != null) {
      if (subText.isNotEmpty) {
        subText += ', ';
      }
      subText += trans.category!.name;
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
                if (trans.nReimbursements > 0) ...[
                  _NumberIndicator(trans.nReimbursements, true),
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
      ],
    );
  }
}

class _NumberIndicator extends StatelessWidget {
  const _NumberIndicator(this.n, this.isAlloc, {super.key});

  final int n;
  final bool isAlloc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 3, right: 3, bottom: 1),
      decoration: BoxDecoration(
        color: (isAlloc) ? const Color(0xffde237a) : const Color(0xff4a1bcc),
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
