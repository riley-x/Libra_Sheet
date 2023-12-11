import 'package:flutter/foundation.dart';
import 'package:libra_sheet/data/app_state/transaction_service.dart';
import 'package:libra_sheet/data/database/accounts.dart' as db;
import 'package:libra_sheet/data/objects/account.dart';

class AccountState extends ChangeNotifier {
  final TransactionService txnService;
  AccountState(this.txnService) {
    txnService.addListener(updateBalances);
  }

  final List<Account> list = [];

  /// Initial load of accounts from the database. DO NOT replace objects!
  Future<void> load() async {
    assert(list.isEmpty);
    list.addAll(await db.getAccounts());
    if (!kReleaseMode) {
      for (final acc in list) {
        debugPrint("AccountState::load() ${acc.dump()}");
      }
    }
    notifyListeners();
  }

  /// Refetches the balances from the database, i.e. after transaction change. DO NOT replace objects!
  Future<void> updateBalances() async {
    // TODO
  }

  Future<void> add(Account acc) async {
    debugPrint("AccountState::add() ${acc.dump()}");
    acc.key = await db.insertAccount(acc, listIndex: list.length);
    list.add(acc);
    notifyListeners();
  }

  /// The account is modified in-place (because accounts must have single instances so that pointers
  /// don't become stale). This just propogates to listerners and database.
  Future<void> notifyUpdate(Account acc) async {
    debugPrint("AccountState::notifyUpdate() ${acc.dump()}");
    notifyListeners();
    db.updateAccount(acc);
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
