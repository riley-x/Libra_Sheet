import 'package:flutter/material.dart';
import 'package:libra_sheet/data/app_state/transaction_service.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/transaction.dart';
import 'package:libra_sheet/tabs/home/account_screen.dart';
import 'package:libra_sheet/tabs/navigation/no_animation_route.dart';
import 'package:libra_sheet/tabs/transactionDetails/transaction_details_screen.dart';
import 'package:provider/provider.dart';

void toAccountScreen(BuildContext context, Account account) {
  Navigator.push(
    context,
    NoAnimationRoute(
      (context) => Material(
        child: AccountScreen(account: account),
      ),
    ),
  );
}

void toTransactionDetails(BuildContext context, Transaction? t) async {
  Navigator.push(
    context,
    NoAnimationRoute(
      (context) => Material(
        child: TransactionDetailsScreen(t),
      ),
    ),
  );
  if (t != null && !t.relationsAreLoaded()) {
    await context.read<TransactionService>().loadRelations(t);
  }
}
