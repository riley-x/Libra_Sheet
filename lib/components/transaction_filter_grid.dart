import 'package:flutter/material.dart';
import 'package:libra_sheet/components/transaction_card.dart';
import 'package:libra_sheet/data/transaction.dart';

class TransactionFilterGrid extends StatefulWidget {
  const TransactionFilterGrid(this.transactions, {super.key, this.title});

  final Widget? title;
  final List<Transaction> transactions;

  @override
  State<TransactionFilterGrid> createState() => _TransactionFilterGridState();
}

class _TransactionFilterGridState extends State<TransactionFilterGrid> {
  // TODO put current filter state here, do the actual filtering
  var myInt = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            (widget.title != null)
                ? widget.title!
                : Text(
                    "Recent Transactions",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
            const Spacer(),
            IconButton(
              onPressed: null,
              icon: Icon(
                Icons.filter_list,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
        Expanded(
          child: TransactionGrid(widget.transactions),
        ),
      ],
    );
  }
}

class TransactionGrid extends StatelessWidget {
  const TransactionGrid(
    this.transactions, {
    super.key,
  });

  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    // Don't use GridLayout here because it has to fix the aspect ratio on the items instead
    // of using the instrinsic height.
    return LayoutBuilder(
      builder: (context, constraints) {
        const minWidth = 300;
        final numCols = (constraints.maxWidth / minWidth).floor();
        final numRows = (transactions.length + numCols - 1) ~/ numCols;
        return ListView.builder(
          itemCount: numRows,
          itemBuilder: (context, index) {
            final startIndex = index * numCols;
            if (startIndex >= transactions.length) return null;
            return Row(
              children: [
                for (int i = startIndex; i < startIndex + numCols; i++)
                  (i >= transactions.length)
                      ? const Spacer()
                      : Expanded(
                          child: TransactionCard(
                            trans: transactions[i],
                          ),
                        ),
              ],
            );
          },
        );
      },
    );
  }
}
