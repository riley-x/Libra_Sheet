import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/app_state/category_state.dart';
import 'package:libra_sheet/data/database/accounts.dart' as db;
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/database_setup.dart';
import 'package:libra_sheet/data/tag.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/data/test_data.dart';
import 'package:libra_sheet/data/transaction.dart';

enum DetailScreen {
  account,
  transaction,
}

class LibraAppState extends ChangeNotifier {
  late final CategoryState categories;

  LibraAppState() {
    categories = CategoryState(this);

    _init();
  }

  void _init() async {
    /// Setup database
    await initDatabase();

    /// Load account, categories
    var futures = <Future>[];
    futures.add(_loadAccounts());
    futures.add(_loadNetWorth());
    futures.add(categories.load());
    await Future.wait(futures);

    notifyListeners();
    // TODO
  }

  final List<TimeValue> chartData = [
    TimeValue.monthStart(2019, 1, 35),
    TimeValue.monthStart(2019, 2, 28),
    TimeValue.monthStart(2019, 3, 34),
    TimeValue.monthStart(2019, 4, 32),
    TimeValue.monthStart(2019, 5, 40),
    TimeValue.monthStart(2019, 6, 35),
    TimeValue.monthStart(2019, 7, 28),
    TimeValue.monthStart(2019, 8, 34.140001),
    TimeValue.monthStart(2019, 9, 32.01),
    TimeValue.monthStart(2019, 10, 40.10)
  ];

  final List<Tag> tags = testTags;

  //--------------------------------------------------------------------------------
  // Accounts
  //--------------------------------------------------------------------------------
  final List<Account> accounts = [];

  Future<void> _loadAccounts() async {
    accounts.addAll(await db.getAccounts());
    if (!kReleaseMode) {
      for (final acc in accounts) {
        debugPrint("LibraAppState::_loadAccounts() $acc");
      }
    }
  }

  Future<void> addAccount(Account acc) async {
    debugPrint("LibraAppState::addAccount() $acc");
    int key = await db.insertAccount(acc, listIndex: accounts.length);
    accounts.add(acc.copyWith(key: key));
    notifyListeners();
  }

  Future<void> updateAccount(Account acc) async {
    debugPrint("LibraAppState::updateAccount() $acc");
    final i = accounts.indexWhere((it) => it.key == acc.key);
    accounts[i] = acc;
    notifyListeners();
    db.updateAccount(acc);
  }

  //--------------------------------------------------------------------------------
  // Net worth
  //--------------------------------------------------------------------------------
  List<TimeIntValue> netWorthData = [];

  Future<void> _loadNetWorth() async {
    netWorthData = await getNetWorth();
    notifyListeners();
  }

  //--------------------------------------------------------------------------------
  // Screen handling
  //--------------------------------------------------------------------------------

  /// Current tab as an index into [LibraNavDestination.values].
  int currentTab = 0;

  /// Current screen being displayed. When not empty, contains the back stack of detail screens.
  /// When empty, defaults to the main tab specified by LibraHomePage. The Object is the input used
  /// to initialize the respective screens.
  final List<(DetailScreen, Object?)> backStack = [];

  void setTab(int i) {
    if (currentTab != i || backStack.isNotEmpty) {
      currentTab = i;
      backStack.clear();
      notifyListeners();
    }
  }

  void popBackStack() {
    if (backStack.isNotEmpty) {
      backStack.removeLast();
      notifyListeners();
    }
  }

  void focusAccount(Account x) {
    // TODO maybe load the transactions here? And change to AccountWithTransactions?
    // Or maybe async load on Widget create...is that possible?
    backStack.add((DetailScreen.account, x));
    notifyListeners();
  }

  void focusTransaction(Transaction? t) {
    backStack.add((DetailScreen.transaction, t));
    notifyListeners();
  }
}
