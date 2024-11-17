import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:libra_sheet/components/cards/transaction_card.dart';
import 'package:libra_sheet/components/menus/transaction_context_menu.dart';
import 'package:libra_sheet/data/app_state/transaction_service.dart';
import 'package:libra_sheet/data/date_time_utils.dart';
import 'package:libra_sheet/data/objects/transaction.dart';
import 'package:provider/provider.dart';

/// Simpler version of TransactionGrid, with just one column.
class TransactionList extends StatelessWidget {
  TransactionList({
    required this.transactions,
    this.maxRowsForName = 1,
    this.selected,
    this.onTap,
    this.onMultiselect,
    this.padding,
    super.key,
  }) : listItems = _parseList(transactions);

  final List<Transaction> transactions;
  final List<_TransactionOrLabel> listItems;
  final int? maxRowsForName;
  final Map<int, Transaction>? selected;
  final Function(Transaction t, int index)? onTap;
  final Function(Transaction t, int index, bool shift)? onMultiselect;
  final EdgeInsets? padding;

  void _onSelect(Transaction t, int index, bool onlyMulti) {
    if (HardwareKeyboard.instance.isShiftPressed) {
      onMultiselect?.call(t, index, true);
    } else if (onlyMulti ||
        (Platform.isMacOS && HardwareKeyboard.instance.isMetaPressed) ||
        (Platform.isWindows && HardwareKeyboard.instance.isControlPressed)) {
      onMultiselect?.call(t, index, false);
    } else {
      onTap?.call(t, index);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Text(
          "No transactions",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
        ),
      );
    }

    final includeLimitText = transactions.length == 300;
    return ListView.builder(
      itemCount: listItems.length + (includeLimitText ? 1 : 0),
      padding: includeLimitText ? padding?.copyWith(bottom: 0) : padding,
      itemBuilder: (context, index) {
        if (includeLimitText && index == listItems.length) {
          return Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 4, top: (padding?.bottom ?? 28) - 20),
              child: Text(
                "Results are limited to the first 300 transactions",
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          );
        }
        if (index >= listItems.length) return null;

        final item = listItems[index];
        if (item.label != null) {
          return _Label(item.label!);
        } else {
          return TransactionCard(
            trans: item.transaction!,
            selected: selected?.containsKey(item.transactionIndex) ?? false,
            maxRowsForName: maxRowsForName,
            onTap: (onTap == null && onMultiselect == null)
                ? null
                : (it) => _onSelect(it, item.transactionIndex!, false),
            contextMenu: TransactionContextMenu(
              onDuplicate: () =>
                  context.read<TransactionService>().createDuplicate(item.transaction!),
              onSelect: () => _onSelect(item.transaction!, item.transactionIndex!, true),
            ),
          );
        }
      },
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 6),
      child: Text(label, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _TransactionOrLabel {
  final Transaction? transaction;
  final int? transactionIndex;
  final String? label;

  _TransactionOrLabel({this.transaction, this.transactionIndex, this.label});
}

List<_TransactionOrLabel> _parseList(List<Transaction> transactions) {
  final out = <_TransactionOrLabel>[];
  for (final (i, t) in transactions.indexed) {
    out.add(_TransactionOrLabel(transaction: t, transactionIndex: i));
    if (i < transactions.length - 1 && differentMonth(t.date, transactions[i + 1].date)) {
      out.add(_TransactionOrLabel(label: transactions[i + 1].date.MMMMyyyy()));
    }
  }
  return out;
}
