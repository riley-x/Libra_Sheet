import 'package:flutter/material.dart';
import 'package:libra_sheet/components/buttons/time_frame_selector.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/time_value.dart';

enum HomeChartMode {
  netWorth,
  stacked,
  pies,
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

  /// Warning this data contains dates using the local time zone because that's what the syncfusion
  /// charts expect. Don't use to save to database!
  List<TimeIntValue> netWorthData = [];

  Future<void> load() async {
    final newData = await LibraDatabase.read((db) => db.getMonthlyNet()) ?? [];
    if (_disposed) return; // can happen due to async gap
    netWorthData = newData.withAlignedTimes(appState.monthList, cumulate: true).fixedForCharts();
    timeFrameRange = timeFrame.getRange(appState.monthList);
    notifyListeners();
  }

  void setTimeFrame(TimeFrame t) {
    timeFrame = t;
    timeFrameRange = timeFrame.getRange(appState.monthList);
    notifyListeners();
  }

  void setMode(HomeChartMode t) {
    mode = t;
    notifyListeners();
  }
}
