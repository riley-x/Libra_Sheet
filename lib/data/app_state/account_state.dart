import 'package:flutter/foundation.dart';
import 'package:libra_sheet/data/app_state/transaction_service.dart';
import 'package:libra_sheet/data/database/accounts.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/objects/account.dart';

class AccountState extends ChangeNotifier {
  final TransactionService txnService;
  AccountState(this.txnService) {
    txnService.addListener(_updateAfterTransactions);
  }

  @override
  void dispose() {
    txnService.removeListener(_updateAfterTransactions);
    super.dispose();
  }

  final List<Account> list = [];

  /// Initial load of accounts from the database. DO NOT replace objects other than a complete app
  /// restart!
  Future<void> load() async {
    list.clear();
    LibraDatabase.read((db) async {
      list.addAll(await db.getAccounts());
    });
    debugPrint("AccountState::load() Loaded ${list.length} accounts");
    notifyListeners();
  }

  /// Refetches the calculated fields from the database, i.e. after transaction change.
  ///
  /// DO NOT replace the original objects! Accounts are kept as pointers by other objects.
  Future<void> _updateAfterTransactions() async {
    final map = createAccountMap();
    final tempList = await LibraDatabase.read((db) => db.getAccounts()) ?? [];
    for (final newAcc in tempList) {
      final oldAcc = map[newAcc.key];
      oldAcc?.balance = newAcc.balance;
      oldAcc?.lastUpdated = newAcc.lastUpdated;
    }
    notifyListeners();
  }

  Future<void> add(Account acc) async {
    debugPrint("AccountState::add() ${acc.dump()}");
    final key = await LibraDatabase.update((db) => db.insertAccount(acc, listIndex: list.length));
    if (key != null) {
      acc.key = key;
      list.add(acc);
      notifyListeners();
    }
  }

  /// The account is modified in-place (because accounts must have single instances so that pointers
  /// don't become stale). This just propogates to listerners and database.
  Future<void> notifyUpdate(Account acc) async {
    debugPrint("AccountState::notifyUpdate() ${acc.dump()}");
    notifyListeners();
    await LibraDatabase.update((db) => db.updateAccount(acc));
  }

  void reorder(int oldIndex, int newIndex) async {
    final acc = list.removeAt(oldIndex);
    if (newIndex > oldIndex) {
      list.insert(newIndex - 1, acc);
    } else {
      list.insert(newIndex, acc);
    }
    notifyListeners();

    await LibraDatabase.updateTransaction((txn) async {
      if (newIndex > oldIndex) {
        await txn.shiftAccountIndicies(oldIndex, newIndex, -1);
        await txn.updateAccount(acc, listIndex: newIndex - 1);
      } else {
        await txn.shiftAccountIndicies(newIndex, oldIndex, 1);
        await txn.updateAccount(acc, listIndex: newIndex);
      }
    });
  }

  // TODO cache this?
  Map<int, Account> createAccountMap() {
    final out = <int, Account>{};
    for (final acc in list) {
      out[acc.key] = acc;
    }
    return out;
  }
}
