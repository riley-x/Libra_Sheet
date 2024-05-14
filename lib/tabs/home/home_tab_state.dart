import 'package:flutter/material.dart';
import 'package:libra_sheet/components/buttons/time_frame_selector.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/time_value.dart';

enum HomeChartMode {
  netWorth,
  stacked,
  pies,
}

class AccountHistory {
  final Account account;
  final List<int> values;

  AccountHistory(this.account, this.values);
}

class HomeTabState extends ChangeNotifier {
  final LibraAppState appState;
  bool _disposed = false;

  HomeTabState(this.appState) {
    appState.transactions.addListener(load);
    load();
  }

  @override
  void dispose() {
    _disposed = true;
    appState.transactions.removeListener(load);
    super.dispose();
  }

  /// Selections
  TimeFrame timeFrame = const TimeFrame(TimeFrameEnum.all);
  (int, int) timeFrameRange = (0, 0);
  HomeChartMode mode = HomeChartMode.stacked;

  /// We store an extra list here instead of relying on [appState.monthList] to make sure there's
  /// no sync issues.
  List<DateTime> monthList = [];

  /// Warning this data contains dates using the local time zone because that's what the syncfusion
  /// charts expect. Don't use to save to database!
  List<TimeIntValue> netWorthData = [];

  List<AccountHistory> assetAccounts = [];
  List<AccountHistory> liabAccounts = [];

  Future<void> load() async {
    final netWorthRaw = await LibraDatabase.read((db) => db.getMonthlyNet()) ?? [];
    final accountHistoryRaw = await LibraDatabase.read((db) => db.getMonthlyNetAllAccounts()) ?? {};
    if (_disposed) return; // can happen due to async gap

    monthList = List.from(appState.monthList);
    timeFrameRange = timeFrame.getRange(monthList);
    assetAccounts = [];
    liabAccounts = [];

    for (final account in appState.accounts.list) {
      final list = (account.type == AccountType.liability) ? liabAccounts : assetAccounts;
      final rawValues = accountHistoryRaw[account.key];
      if (rawValues == null) continue;
      final values = rawValues.alignValues(monthList, cumulate: true);
      // if (list.isNotEmpty) {
      //   values.addElementwise(list.last.values);
      // }
      list.add(AccountHistory(account, values));
    }

    netWorthData = netWorthRaw.withAlignedTimes(monthList, cumulate: true).fixedForSyncfusion();
    notifyListeners();
  }

  void setTimeFrame(TimeFrame t) {
    timeFrame = t;
    timeFrameRange = timeFrame.getRange(monthList);
    notifyListeners();
  }

  void setMode(HomeChartMode t) {
    mode = t;
    notifyListeners();
  }
}
