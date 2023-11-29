import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:libra_sheet/data/app_state/rule_state.dart';
import 'package:libra_sheet/data/database/transactions.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/app_state/category_state.dart';
import 'package:libra_sheet/data/app_state/tag_state.dart';
import 'package:libra_sheet/data/database/accounts.dart' as db;
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/database_setup.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/data/objects/transaction.dart';

enum DetailScreen {
  account,
  transaction,
  addCsv,
}

class LibraAppState extends ChangeNotifier {
  late final CategoryState categories;
  late final TagState tags;
  late final RuleState rules;

  LibraAppState() {
    categories = CategoryState(this);
    tags = TagState(this);
    rules = RuleState(this);

    _init();
  }

  void _init() async {
    /// Setup database
    await initDatabase();

    /// Load account, categories
    var futures = <Future>[];
    futures.add(_loadAccounts());
    futures.add(categories.load());
    futures.add(tags.load());
    _loadNetWorth(); // not needed downstream, no need to await (but do place before the await below)
    await Future.wait(futures);

    rules.load(); // not needed until adding transactions/editing rules

    notifyListeners();
    // TODO
  }

  void reloadAfterTransactions() async {
    var futures = <Future>[];
    futures.add(_loadAccounts());
    _loadNetWorth(); // not needed downstream, no need to await (but do place before the await below)
    await Future.wait(futures);
    notifyListeners();
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

  //--------------------------------------------------------------------------------
  // Accounts
  //--------------------------------------------------------------------------------
  final List<Account> accounts = [];

  Future<void> _loadAccounts() async {
    accounts.clear();
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

  // TODO cache this?
  Map<int, Account> createAccountMap() {
    final out = <int, Account>{};
    for (final acc in accounts) {
      out[acc.key] = acc;
    }
    return out;
  }

  //--------------------------------------------------------------------------------
  // Net worth
  //--------------------------------------------------------------------------------
  /// Warning this data contains dates using the local time zone because that's what the syncfusion
  /// charts expect. Don't use to save to database!
  List<TimeIntValue> netWorthData = [];

  Future<void> _loadNetWorth() async {
    /// TODO this is wrong, need to cummulate
    netWorthData = await getMonthlyNet();
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

  void focusTransaction(Transaction? t) async {
    if (t != null && !t.relationsAreLoaded()) {
      await loadTransactionRelations(t, categories.createKeyMap());
    }
    backStack.add((DetailScreen.transaction, t));
    notifyListeners();
  }

  void navigateToAddCsvScreen() {
    backStack.add((DetailScreen.addCsv, null));
    notifyListeners();
  }
}
