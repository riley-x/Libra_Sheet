import 'dart:io';

import 'package:intl/intl.dart';
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/database/transactions.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/objects/tag.dart';
import 'package:libra_sheet/data/time_value.dart';

final _monthFormat = DateFormat.yMMM();
Future<String> createBalanceHistoryCsvString(List<Account> accounts, List<DateTime> months) async {
  String out = '';
  final lineEnd = Platform.isWindows ? '\r\n' : '\n';

  /// Header
  out += 'Month';
  for (final account in accounts) {
    out += ',${account.name}';
  }
  out += lineEnd;

  /// Data
  final netChanges = await LibraDatabase.db.getMonthlyNetAllAccounts();
  final balances = {
    for (final entry in netChanges.entries)
      entry.key: entry.value.alignValues(months, cumulate: true),
  };

  /// Entries
  for (int i = 0; i < months.length; i++) {
    var row = _monthFormat.format(months[i]);
    for (final account in accounts) {
      final value = balances[account.key]?[i] ?? 0;
      row += ',${value.dollarString(dollarSign: false, commas: false)}';
    }
    out += row + lineEnd;
  }

  return out;
}

Future<String> createTransactionHistoryCsvString({
  required Map<int, Account> accounts,
  required Map<int, Category> categories,
  required Map<int, Tag> tags,
}) async {
  final lineEnd = Platform.isWindows ? '\r\n' : '\n';

  /// Header
  String out = 'Key,Date,Name,Value,Account,Category,Tags,Note,Allocations,Reimbursements$lineEnd';

  /// Data
  final maps = await LibraDatabase.db
      .loadAllTransactions(accounts: accounts, categories: categories, tags: tags);

  print(maps.length);
  return out;
}
