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
  var myInt = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              "Recent Transactions",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Spacer(),
            IconButton(
              onPressed: null,
              icon: Icon(
                Icons.filter_alt,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              childAspectRatio: 5,
            ),
            itemCount: widget.transactions.length,
            itemBuilder: (context, index) {
              return TransactionCard(trans: widget.transactions[index]);
            },
          ),
        ),
      ],
    );
  }
}
