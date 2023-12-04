import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:libra_sheet/data/app_state/rule_state.dart';
import 'package:libra_sheet/data/app_state/transaction_service.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/app_state/category_state.dart';
import 'package:libra_sheet/data/app_state/tag_state.dart';
import 'package:libra_sheet/data/database/accounts.dart' as db;
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
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
  late final TransactionService transactions;

  LibraAppState() {
    categories = CategoryState(this);
    tags = TagState(this);
    rules = RuleState(this);
    transactions = TransactionService(this);

    _init();
  }

  void _init() async {
    /// Setup database
    await LibraDatabase.init();

    /// Load account, categories
    var futures = <Future>[];
    futures.add(_loadAccounts());
    futures.add(categories.load());
    futures.add(tags.load());
    futures.add(_loadMonths());
    await Future.wait(futures);

    _loadNetWorth(); // not needed downstream, but needs months
    rules.load(); // not needed until adding transactions/editing rules
    notifyListeners();
  }

  Future<void> reloadAfterTransactions() async {
    var futures = <Future>[];
    futures.add(_loadMonths());
    futures.add(_loadAccounts());
    await Future.wait(futures);
    _loadNetWorth(); // not needed downstream, no need to await
    notifyListeners();
  }

  //--------------------------------------------------------------------------------
  // Accounts
  //--------------------------------------------------------------------------------
  final List<Account> accounts = [];

  Future<void> _loadAccounts() async {
    accounts.clear();
    accounts.addAll(await db.getAccounts());
    if (!kReleaseMode) {
      for (final acc in accounts) {
        debugPrint("LibraAppState::_loadAccounts() ${acc.dump()}");
      }
    }
  }

  Future<void> addAccount(Account acc) async {
    debugPrint("LibraAppState::addAccount() ${acc.dump()}");
    acc.key = await db.insertAccount(acc, listIndex: accounts.length);
    accounts.add(acc);
    notifyListeners();
  }

  /// The account is modified in-place (because accounts must have single instances so that pointers
  /// don't become stale). This just propogates to listerners and database.
  Future<void> notifyUpdateAccount(Account acc) async {
    debugPrint("LibraAppState::notifyUpdateAccount() ${acc.dump()}");
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
  // Time data
  //--------------------------------------------------------------------------------
  List<DateTime> monthList = [];

  Future<void> _loadMonths() async {
    final now = DateTime.now();
    final earliestMonth = await LibraDatabase.db.getEarliestMonth();
    if (earliestMonth == null) return;

    // no easy way to do this in dart, so do manually
    final current = (now.year, now.month);
    var iter = (earliestMonth.year, earliestMonth.month);

    monthList = [];
    while (iter.$1 <= current.$1 && iter.$2 <= current.$2) {
      monthList.add(DateTime.utc(iter.$1, iter.$2));
      if (iter.$2 == 12) {
        iter = (iter.$1 + 1, 1);
      } else {
        iter = (iter.$1, iter.$2 + 1);
      }
    }
    debugPrint("LibraAppState::_loadMonths() $monthList");
  }

  /// Warning this data contains dates using the local time zone because that's what the syncfusion
  /// charts expect. Don't use to save to database!
  List<TimeIntValue> netWorthData = [];

  Future<void> _loadNetWorth() async {
    final newData = await LibraDatabase.db.getMonthlyNet();
    netWorthData = newData.withAlignedTimes(monthList, cumulate: true).fixedForCharts();
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

  // void focusAccount(Account x) {
  //   backStack.add((DetailScreen.account, x));
  //   notifyListeners();
  // }

  void focusTransaction(Transaction? t) async {
    if (t != null && !t.relationsAreLoaded()) {
      await transactions.loadRelations(t);
    }
    backStack.add((DetailScreen.transaction, t));
    notifyListeners();
  }

  void navigateToAddCsvScreen() {
    backStack.add((DetailScreen.addCsv, null));
    notifyListeners();
  }
}
