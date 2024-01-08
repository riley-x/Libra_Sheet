import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/database/transactions.dart';
import 'package:libra_sheet/data/date_time_utils.dart';
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
  final netChanges = await LibraDatabase.readThrow((db) => db.getMonthlyNetAllAccounts());
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
  final converter = ListToCsvConverter(eol: Platform.isWindows ? '\r\n' : '\n');
  List<List<String>> out = [];

  /// Header
  out.add([
    'Key',
    'Date',
    'Name',
    'Value',
    'Account',
    'Category',
    'Tags',
    'Note',
    'Allocations',
    'Reimbursements'
  ]);

  /// Data
  final transactions = await LibraDatabase.readThrow((db) => db.loadAllTransactionsForCsv(
        accounts: accounts,
        categories: categories,
        tags: tags,
      ));
  for (final t in transactions) {
    out.add([
      t.t.key.toString(),
      t.t.date.MMddyy(),
      t.t.name,
      t.t.value.dollarString(commas: false, dollarSign: false),
      t.t.account?.name ?? '',
      t.t.category.name,
      t.t.tags.map((e) => e.name).join(','),
      t.t.note,
      t.allocs
          .map((e) => "${e.category}: ${e.value.dollarString(commas: false)} (${e.name})")
          .join(', '),
      t.reimbs.map((e) => "${e.$1}: ${e.$2.dollarString(commas: false)}").join(', '),
    ]);
  }

  return converter.convert(out);
}
