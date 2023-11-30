import 'package:flutter/foundation.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/time_value.dart';

class CashFlowState extends ChangeNotifier {
  CashFlowState(this.appState) {
    _init();
  }

  final LibraAppState appState;

  List<CategoryHistory> data = [];

  Future<void> _init() async {
    data.clear();
    final categories = appState.categories.createKeyMap();
    final categoryHistory = await getCategoryHistory();
    for (final categoryId in categoryHistory.keys) {
      final cat = categories[categoryId];
      if (cat == null) continue;
      data.add(CategoryHistory(
        cat,
        alignTimes(categoryHistory[categoryId]!, appState.monthList),
      ));
    }
  }
}
