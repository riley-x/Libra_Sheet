import 'package:libra_sheet/data/database/account_balance_history.dart';
import 'package:libra_sheet/data/database/transactions.dart';
import 'package:libra_sheet/data/date_time_utils.dart';
import 'package:sqflite/sqlite_api.dart';

/// Populates the account_balance_history table from existing transaction data.
///
/// This migration loads all transactions and accumulates their values by month and account,
/// then writes the aggregated data to the account_balance_history table.
Future<void> populateAccountBalanceHistory(DatabaseExecutor db) async {
  // Load all raw transactions from the database
  final List<Map<String, dynamic>> transactions = await db.query(
    transactionsTable,
    columns: [transactionAccount, transactionDate, transactionValue],
  );

  // Accumulate transaction values by (account, month)
  final Map<int, Map<DateTime, int>> accountMonthlyDeltas = {};

  for (final txn in transactions) {
    final account = txn[transactionAccount] as int;
    final date = DateTime.fromMillisecondsSinceEpoch(txn[transactionDate] as int, isUtc: true);
    final value = txn[transactionValue] as int;

    // Normalize date to start of month
    final monthStart = startOfMonth(date);

    // Accumulate the value for this (account, month) pair
    accountMonthlyDeltas.putIfAbsent(account, () => {});
    accountMonthlyDeltas[account]!.update(
      monthStart,
      (existing) => existing + value,
      ifAbsent: () => value,
    );
  }

  // Write accumulated data to account_balance_history table
  for (final accountEntry in accountMonthlyDeltas.entries) {
    for (final monthEntry in accountEntry.value.entries) {
      await updateAccountBalanceHistoryForMigration(
        db,
        account: accountEntry.key,
        date: monthEntry.key,
        delta: monthEntry.value,
      );
    }
  }
}
