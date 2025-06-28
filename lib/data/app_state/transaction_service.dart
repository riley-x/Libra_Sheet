import 'package:flutter/material.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filters.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/database/reimbursements.dart';
import 'package:libra_sheet/data/database/transactions.dart';
import 'package:libra_sheet/data/objects/allocation.dart';
import 'package:libra_sheet/data/objects/transaction.dart';

/// Helper class for managing transactions. Every widget that monitors transactions should probably
/// watch this service, so that they can be notified when transactions are added or edited (which
/// affects all value-based entities and, because of reimbursements, can affect all other
/// transactions).
class TransactionService extends ChangeNotifier {
  final LibraAppState appState;
  TransactionService(this.appState);

  Future<void> onUpdate() async {
    // This updates the monthsList, which is used downstream
    await appState.reloadAfterTransactions();
    notifyListeners();
  }

  Future<List<Transaction>> load(TransactionFilters filters) async {
    final ts = await LibraDatabase.read(
      (db) async => await db.loadTransactions(
        filters,
        accounts: appState.accounts.createAccountMap(),
        categories: appState.categories.createKeyMap(),
        tags: appState.tags.createKeyMap(),
      ),
    );
    return ts ?? [];
  }

  Future<void> save(Transaction? old, Transaction nu) async {
    debugPrint("TransactionService::save() \nold=$old\nnew=$nu");
    if (old == null) {
      assert(nu.key == 0);
      await LibraDatabase.updateTransaction((txn) => txn.insertTransaction(nu));
    } else {
      await LibraDatabase.updateTransaction((txn) => txn.updateTransaction(old, nu));
    }
    onUpdate();
  }

  Future<void> addAll(List<Transaction> transactions) async {
    await LibraDatabase.backup(tag: '.before_add_csv');
    await LibraDatabase.updateTransaction((txn) async {
      for (final t in transactions) {
        await txn.insertTransaction(t);
      }
    });
    onUpdate();
  }

  Future<void> updateAll(List<(Transaction, Transaction)> items) async {
    await LibraDatabase.backup(tag: '.before_add_csv');
    await LibraDatabase.updateTransaction((txn) async {
      for (final (old, nu) in items) {
        await txn.updateTransaction(old, nu);
      }
    });
    onUpdate();
  }

  Future<void> createDuplicate(Transaction old) async {
    debugPrint("TransactionService::createDuplicate() \n$old");
    await LibraDatabase.updateTransaction((txn) async {
      if (!old.relationsAreLoaded()) {
        await txn.loadTransactionRelations(
          old,
          accounts: appState.accounts.createAccountMap(),
          categories: appState.categories.createKeyMap(),
          tags: appState.tags.createKeyMap(),
        );
      }
      final nu = Transaction(
        name: old.name,
        date: old.date,
        value: old.value,
        category: old.category,
        account: old.account,
        note: old.note,
        allocations: old.allocations
            ?.map(
              (e) => Allocation(
                // Need key = 0 to create a new allocation entry in the database
                name: e.name,
                category: e.category,
                value: e.value,
              ),
            )
            .toList(),
        tags: old.tags,
        // Don't copy reimbursements
      );
      await txn.insertTransaction(nu);
    });
    onUpdate();
  }

  Future<void> delete(Transaction t) async {
    debugPrint("TransactionService::delete() $t");
    deleteBulk([t]);
  }

  Future<void> deleteBulk(List<Transaction> transactions) async {
    debugPrint("TransactionService::deleteBulk() ${transactions.length}");
    final accounts = appState.accounts.createAccountMap();
    final categories = appState.categories.createKeyMap();
    final tags = appState.tags.createKeyMap();

    for (final t in transactions) {
      await LibraDatabase.updateTransaction((txn) async {
        final reloaded = await txn.loadTransactionByKey(
          t.key,
          accounts: accounts,
          categories: categories,
          tags: tags,
        );
        if (reloaded == null) return;
        await txn.loadTransactionRelations(
          reloaded,
          accounts: accounts,
          categories: categories,
          tags: tags,
        );
        await txn.deleteTransaction(reloaded);
      });
    }
    onUpdate();
  }

  Future<void> loadRelations(Transaction t) async {
    await LibraDatabase.readTransaction(
      (txn) => txn.loadTransactionRelations(
        t,
        accounts: appState.accounts.createAccountMap(),
        categories: appState.categories.createKeyMap(),
        tags: appState.tags.createKeyMap(),
      ),
    );
  }

  Future<void> reloadReimbursements(Transaction t) async {
    t.reimbursements =
        await LibraDatabase.read(
          (db) => db.loadReimbursements(
            parent: t,
            accounts: appState.accounts.createAccountMap(),
            categories: appState.categories.createKeyMap(),
            tags: appState.tags.createKeyMap(),
          ),
        ) ??
        [];
  }

  Future<Map<int, Transaction>> loadByKey(Iterable<int> keys) async {
    final out = await LibraDatabase.read(
      (db) => db.loadTransactionsByKey(
        keys,
        accounts: appState.accounts.createAccountMap(),
        categories: appState.categories.createKeyMap(),
        tags: appState.tags.createKeyMap(),
      ),
    );
    return out ?? {};
  }

  Future<Transaction?> loadSingle(int key) async {
    final map = await loadByKey({key});
    final t = map[key];
    if (t == null) return null;
    await loadRelations(t);
    return t;
  }
}
