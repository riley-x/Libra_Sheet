import 'package:flutter/foundation.dart' as fnd;
import 'package:libra_sheet/components/buttons/time_frame_selector.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/tabs/analyze/analyze_tab_view_state.dart';

class AnalyzeTabState extends fnd.ChangeNotifier {
  final LibraAppState appState;
  bool _disposed = false;

  AnalyzeTabState(this.appState) {
    appState.transactions.addListener(load);
    load();
  }

  @override
  void dispose() {
    _disposed = true;
    appState.transactions.removeListener(load);
    super.dispose();
  }

  Future<void> load() async {
    notifyListeners();
  }

  /// Main view state defines which graph we're looking at as well as per-graph
  /// viewing options.
  AnalyzeTabViewState viewState = DoubleStackView();

  /// Load filters
  final Set<Account> accounts = {};
  TimeFrame timeFrame = const TimeFrame(TimeFrameEnum.all);

  //------------------------------------------------------------------------------
  // Filter field callbacks
  //------------------------------------------------------------------------------
  void setTimeFrame(TimeFrame t) {
    timeFrame = t;
    notifyListeners();
    // _loadTotals();
  }
}
