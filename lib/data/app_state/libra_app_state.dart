import 'dart:async';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/components/dialogs/confirmation_dialog.dart';
import 'package:libra_sheet/data/app_state/account_state.dart';
import 'package:libra_sheet/data/app_state/rule_state.dart';
import 'package:libra_sheet/data/app_state/transaction_service.dart';
import 'package:libra_sheet/data/app_state/category_state.dart';
import 'package:libra_sheet/data/app_state/tag_state.dart';
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/export/history_csv.dart';
import 'package:libra_sheet/main.dart';
import 'package:libra_sheet/tabs/navigation/libra_nav.dart';
import 'package:libra_sheet/theme/colorscheme.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefKeyDarkMode = 'dark_mode';

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

  Future<void> initPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode = prefs.getBool(_prefKeyDarkMode) ?? true;
    if (!isDarkMode) colorScheme = libraLightColorScheme;
  }

  /// Initializes all app state data from the database. Must be called after the database has been
  /// initialized.
  ///
  /// Warning, this can be called again on a database replacement.
  Future<void> initData() async {
    var futures = <Future>[];
    futures.add(accounts.load());
    futures.add(categories.load());
    futures.add(tags.load());
    futures.add(_loadMonths());
    await Future.wait(futures);

    rules.load(); // not needed until adding transactions/editing rules
    notifyListeners();
  }

  /// Make sure to NOT subscribe this to [transactions] as the month list MUST be awaited before
  /// anything else is updated. I'm not sure if the ChangeNotifier updates in order, but it
  /// probably doesn't await anything.
  Future<void> reloadAfterTransactions() async {
    await _loadMonths();
    notifyListeners();
  }

  //--------------------------------------------------------------------------------
  // Config
  //--------------------------------------------------------------------------------
  ColorScheme colorScheme = libraDarkColorScheme;
  bool isDarkMode = true;

  Future<void> toggleDarkMode() async {
    if (isDarkMode) {
      isDarkMode = false;
      colorScheme = libraLightColorScheme;
    } else {
      isDarkMode = true;
      colorScheme = libraDarkColorScheme;
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyDarkMode, isDarkMode);
  }

  //--------------------------------------------------------------------------------
  // Time data
  //--------------------------------------------------------------------------------
  List<DateTime> monthList = [];

  Future<void> _loadMonths() async {
    final earliestMonth = await LibraDatabase.read((db) => db.getEarliestMonth());
    final latestMonth = await LibraDatabase.read((db) => db.getLatestMonth());
    if (earliestMonth == null || latestMonth == null) {
      monthList = _getDefaultMonths(); // So that the charts don't look too weird
      return;
    }

    // no easy way to do this in dart, so do manually
    var year = earliestMonth.year;
    var month = earliestMonth.month;

    monthList = [];
    while (year < latestMonth.year || (year == latestMonth.year && month <= latestMonth.month)) {
      monthList.add(DateTime.utc(year, month));
      if (month == 12) {
        year++;
        month = 1;
      } else {
        month++;
      }
    }
    debugPrint("LibraAppState::_loadMonths() Loaded ${monthList.length} months "
        "between $earliestMonth and $latestMonth");
  }

  //--------------------------------------------------------------------------------
  // Screen handling
  //--------------------------------------------------------------------------------
  final appNavigatorKey = GlobalKey<NavigatorState>();
  final tabNavigatorKeys = List.generate(
    libraNavDestinations.length,
    (index) => GlobalKey<NavigatorState>(),
  );
  final scaffoldKey = GlobalKey<ScaffoldMessengerState>();

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

  /// Returns the filepath of the newly saved CSV file, or null on cancel/error
  Future<String?> exportBalanceHistoryToCsv() async {
    try {
      final now = DateTime.now();
      final fileName = 'balance_history_${_csvDateFormat.format(now)}.csv';
      final FileSaveLocation? result = await getSaveLocation(suggestedName: fileName);
      if (result == null) return null; // cancelled by user

      final csvString = await createBalanceHistoryCsvString(accounts.list, monthList);
      final Uint8List fileData = Uint8List.fromList(csvString.codeUnits);
      const String mimeType = 'text/csv';
      final XFile textFile = XFile.fromData(fileData, mimeType: mimeType, name: fileName);
      await textFile.saveTo(result.path);
      return result.path;
    } catch (e) {
      debugPrint("$e");
      return null;
    }
  }

  Future<String?> exportTransactionsToCsv() async {
    try {
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
    } catch (e) {
      debugPrint("$e");
      return null;
    }
  }

  FutureOr<bool> userConfirmOverwrite() {
    final context = scaffoldKey.currentContext;
    if (context == null || !context.mounted) return false;
    return showConfirmationDialog(
      context: context,
      title: 'Google Drive Sync',
      msg: 'A newer database file exists on Google Drive. Overwrite the current database file?'
          '\n\nIf you want to replace the file on Google Drive instead, click "Cancel" for now. '
          'Delete the file on Google Drive then retry the sync.',
    );
  }

  Future<void> onDatabaseReplaced() async {
    /// All the navigation destinations are dependent on data objects, like transaction details
    /// or account focus screen, so back out of all of them.
    for (final nav in tabNavigatorKeys) {
      nav.currentState?.popUntil((route) => route.isFirst);
    }
    await initData();

    final context = scaffoldKey.currentContext;
    if (context != null && context.mounted) {
      // This only rebuilds the widget tree and therefore recreates the state of any
      // ChangeNotifierProvider, but doesn't reset StatefulWidget state.
      RestartWidget.restartApp(context);
    }
    transactions.notifyListeners();
  }
}

List<DateTime> _getDefaultMonths() {
  final now = DateTime.now();
  return [
    for (int i = 11; i >= 0; i--) DateTime.utc(now.year, now.month - i, 1),
  ];
}
