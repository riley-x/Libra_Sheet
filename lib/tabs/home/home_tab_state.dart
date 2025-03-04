import 'package:flutter/material.dart';
import 'package:libra_sheet/components/buttons/time_frame_selector.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/month.dart';
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
  final Map<Month, int> monthEndValues;

  AccountHistory(this.account, this.values, List<DateTime> months)
      : monthEndValues = {
          for (int i = 0; i < values.length; i++)
            Month(year: months[i].year, index: months[i].month): values[i],
        };
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
  Map<int, AccountHistory> historyMap = {};

  Future<void> load() async {
    final netWorthRaw = await LibraDatabase.read((db) => db.getMonthlyNet()) ?? [];
    final accountHistoryRaw = await LibraDatabase.read((db) => db.getMonthlyNetAllAccounts()) ?? {};
    if (_disposed) return; // can happen due to async gap

    monthList = List.from(appState.monthList);
    timeFrameRange = timeFrame.getRange(monthList);
    assetAccounts = [];
    liabAccounts = [];
    historyMap = {};

    for (final account in appState.accounts.list) {
      final rawValues = accountHistoryRaw[account.key];
      if (rawValues == null) continue;
      final values = rawValues.alignValues(monthList, cumulate: true);

      final list = (account.type == AccountType.liability) ? liabAccounts : assetAccounts;
      final history = AccountHistory(account, values, monthList);
      list.add(history);
      historyMap[account.key] = history;
    }

    netWorthData = netWorthRaw.withAlignedTimes(monthList, cumulate: true);
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
