import 'dart:async';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/data/app_state/account_state.dart';
import 'package:libra_sheet/data/app_state/rule_state.dart';
import 'package:libra_sheet/data/app_state/transaction_service.dart';
import 'package:libra_sheet/data/app_state/category_state.dart';
import 'package:libra_sheet/data/app_state/tag_state.dart';
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/export/history_csv.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/theme/colorscheme.dart';

class LibraAppState extends ChangeNotifier {
  late final CategoryState categories;
  late final TagState tags;
  late final RuleState rules;
  late final TransactionService transactions;
  late final AccountState accounts;

  LibraAppState() {
    categories = CategoryState(this);
    tags = TagState(this);
    rules = RuleState(this);
    transactions = TransactionService(this);
    accounts = AccountState(transactions);
  }

  //--------------------------------------------------------------------------------
  // Init
  //--------------------------------------------------------------------------------
  Future<void> init() async {
    /// Load account, categories
    var futures = <Future>[];
    futures.add(accounts.load());
    futures.add(categories.load());
    futures.add(tags.load());
    futures.add(_loadMonths());
    await Future.wait(futures);

    _loadNetWorth(); // not needed downstream, but needs months
    rules.load(); // not needed until adding transactions/editing rules
    notifyListeners();
  }

  /// Make sure to NOT subscribe this to [transactions] as the month list MUST be awaited before
  /// anything else is updated. I'm not sure if the ChangeNotifier updates in order, but it
  /// probably doesn't await anything.
  Future<void> reloadAfterTransactions() async {
    await _loadMonths();
    _loadNetWorth(); // not needed downstream, no need to await
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
  // Time data
  //--------------------------------------------------------------------------------
  List<DateTime> monthList = [];

  Future<void> _loadMonths() async {
    final earliestMonth = await LibraDatabase.db.getEarliestMonth();
    if (earliestMonth == null) {
      monthList = _getDefaultMonths(); // So that the charts don't look too weird
      return;
    }

    // no easy way to do this in dart, so do manually
    final now = DateTime.now();
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
  final navigatorKey = GlobalKey<NavigatorState>();

  /// Current tab as an index into [LibraNavDestination.values].
  int currentTab = 0;

  void setTab(int i) {
    currentTab = i;
    // TODO pop to beginning on internal navigators on re-select tab?
    // NOT the top level navigator:
    // navigatorKey.currentState?.popUntil((route) => route.isFirst);
    notifyListeners();
  }

  //--------------------------------------------------------------------------------
  // Export
  //--------------------------------------------------------------------------------
  final _csvDateFormat = DateFormat('yyyy-MM-dd');
  Future<String?> exportBalanceHistoryToCsv() async {
    final now = DateTime.now();
    final fileName = 'balance_history_${_csvDateFormat.format(now)}.csv';
    final FileSaveLocation? result = await getSaveLocation(suggestedName: fileName);
    if (result == null) return null;

    final csvString = await createBalanceHistoryCsvString(accounts.list, monthList);
    final Uint8List fileData = Uint8List.fromList(csvString.codeUnits);
    const String mimeType = 'text/csv';
    final XFile textFile = XFile.fromData(fileData, mimeType: mimeType, name: fileName);
    await textFile.saveTo(result.path);
    return result.path;
  }

  Future<String?> exportTransactionsToCsv() async {
    await createTransactionHistoryCsvString(
      accounts: accounts.createAccountMap(),
      categories: categories.createKeyMap(),
      tags: tags.createKeyMap(),
    );
    return null;

    final now = DateTime.now();
    final fileName = 'transaction_history_${_csvDateFormat.format(now)}.csv';
    final FileSaveLocation? result = await getSaveLocation(suggestedName: fileName);
    if (result == null) return null;

    final csvString = await createTransactionHistoryCsvString(
      accounts: accounts.createAccountMap(),
      categories: categories.createKeyMap(),
      tags: tags.createKeyMap(),
    );
    final Uint8List fileData = Uint8List.fromList(csvString.codeUnits);
    const String mimeType = 'text/csv';
    final XFile textFile = XFile.fromData(fileData, mimeType: mimeType, name: fileName);
    await textFile.saveTo(result.path);
    return result.path;
  }
}

List<DateTime> _getDefaultMonths() {
  final now = DateTime.now();
  return [
    for (int i = 11; i >= 0; i--) DateTime.utc(now.year, now.month - i, 1),
  ];
}
