import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:libra_sheet/data/app_state/rule_state.dart';
import 'package:libra_sheet/data/app_state/transaction_service.dart';
import 'package:libra_sheet/data/date_time_utils.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/app_state/category_state.dart';
import 'package:libra_sheet/data/app_state/tag_state.dart';
import 'package:libra_sheet/data/database/accounts.dart' as db;
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/test_data.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/theme/colorscheme.dart';

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
  }

  //--------------------------------------------------------------------------------
  // Init
  //--------------------------------------------------------------------------------
  Future<void> init() async {
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
    notifyListeners();
  }

  //--------------------------------------------------------------------------------
  // Config
  //--------------------------------------------------------------------------------
  ColorScheme colorScheme = libraDarkColorScheme;
  bool isDarkMode = true;

  void toggleDarkMode() {
    if (isDarkMode) {
      isDarkMode = false;
      colorScheme = libraLightColorScheme;
    } else {
      isDarkMode = true;
      colorScheme = libraDarkColorScheme;
    }
    notifyListeners();
  }

  //--------------------------------------------------------------------------------
  // Accounts
  //--------------------------------------------------------------------------------
  final List<Account> accounts = [];

  Future<void> _loadAccounts() async {
    accounts.clear();
    accounts.addAll(testAccounts);
  }

  Future<void> addAccount(Account acc) async {
    debugPrint("LibraAppState::addAccount() ${acc.dump()}");
    accounts.add(acc);
    notifyListeners();
  }

  /// The account is modified in-place (because accounts must have single instances so that pointers
  /// don't become stale). This just propogates to listerners and database.
  Future<void> notifyUpdateAccount(Account acc) async {
    debugPrint("LibraAppState::notifyUpdateAccount() ${acc.dump()}");
    notifyListeners();
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
    final earliestMonth = startOfMonth(now.subtract(const Duration(days: 360)));

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
    const vals = [
      163246100,
      165128600,
      169421500,
      174295300,
      179102000,
      176138000,
      180194200,
      182143900,
      184094300,
      183497500,
      187915400,
      189134200,
      190438100,
      191968900,
      191968900,
    ];
    final newData = [
      for (int i = 0; i < monthList.length; i++) TimeIntValue(time: monthList[i], value: vals[i])
    ];
    netWorthData = newData.fixedForCharts();
    notifyListeners();
  }

  //--------------------------------------------------------------------------------
  // Screen handling
  //--------------------------------------------------------------------------------
  final navigatorKey = GlobalKey<NavigatorState>();

  /// Current tab as an index into [LibraNavDestination.values].
  int currentTab = 0;

  void setTab(int i) {
    currentTab = i;
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    notifyListeners();
  }
}
