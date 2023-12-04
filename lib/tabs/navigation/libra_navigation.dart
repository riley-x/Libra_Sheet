import 'package:flutter/material.dart';
import 'package:libra_sheet/data/app_state/transaction_service.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/transaction.dart';
import 'package:libra_sheet/tabs/csv/add_csv_screen.dart';
import 'package:libra_sheet/tabs/home/account_screen.dart';
import 'package:libra_sheet/tabs/navigation/no_animation_route.dart';
import 'package:libra_sheet/tabs/transactionDetails/transaction_details_screen.dart';

void toAccountScreen(BuildContext context, Account account) {
  Navigator.push(
    context,
    NoAnimationRoute(
      (context) => AccountScreen(account: account),
    ),
  );
}

void toTransactionDetails(BuildContext context, Transaction? t) {
  Navigator.push(
    context,
    NoAnimationRoute(
      (context) => TransactionDetailsScreen(t),
    ),
  );
}

void toCsvScreen(BuildContext context) {
  Navigator.push(
    context,
    NoAnimationRoute((context) => const AddCsvScreen()),
  );
}
