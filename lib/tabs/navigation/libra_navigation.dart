import 'package:flutter/material.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filter_state.dart';
import 'package:libra_sheet/data/app_state/transaction_service.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/objects/transaction.dart';
import 'package:libra_sheet/tabs/category/category_focus_screen.dart';
import 'package:libra_sheet/tabs/csv/add_csv_screen.dart';
import 'package:libra_sheet/tabs/home/account_screen.dart';
import 'package:libra_sheet/tabs/navigation/no_animation_route.dart';
import 'package:libra_sheet/tabs/transactionDetails/transaction_details_screen.dart';
import 'package:provider/provider.dart';

void toAccountScreen(BuildContext context, Account account) {
  Navigator.push(
    context,
    NoAnimationRoute(
      (context) => AccountScreen(account: account),
    ),
  );
}

void toCategoryScreen(
  BuildContext context,
  Category category, {
  TransactionFilters? initialFilters,
}) {
  Navigator.push(
    context,
    NoAnimationRoute(
      (context) => CategoryFocusScreen(
        category: category,
        initialFilters: initialFilters,
      ),
    ),
  );
}

void toTransactionDetails(BuildContext context, Transaction? t, {Account? initialAccount}) async {
  if (t != null && !t.relationsAreLoaded()) {
    await context.read<TransactionService>().loadRelations(t);
  }
  if (!context.mounted) return;
  Navigator.push(
    context,
    NoAnimationRoute(
      (context) => TransactionDetailsScreen(
        t,
        initialAccount: initialAccount,
      ),
    ),
  );
}

void toCsvScreen(BuildContext context, {Account? initialAccount}) {
  Navigator.push(
    context,
    NoAnimationRoute((context) => AddCsvScreen(initialAccount: initialAccount)),
  );
}
