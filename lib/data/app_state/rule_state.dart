// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'package:flutter/foundation.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/database/rules.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/objects/category_rule.dart';
import 'package:libra_sheet/data/test_data.dart';

/// Helper module for handling the category rules
class RuleState {
  //----------------------------------------------------------------------------
  // Fields
  //----------------------------------------------------------------------------
  LibraAppState appState;
  RuleState(this.appState);

  final List<CategoryRule> income = [];
  final List<CategoryRule> expense = [];

  //----------------------------------------------------------------------------
  // Modification Functions
  //----------------------------------------------------------------------------
  Future<void> load() async {
    income.add(testRules[0]);
    expense.add(testRules[1]);
    appState.notifyListeners();
  }

  Future<void> add(CategoryRule rule) async {
    debugPrint("RuleState::add() $rule");
    if (rule.category == null) return;
    final list = (rule.type == ExpenseType.income) ? income : expense;
    list.add(rule);
    appState.notifyListeners();
  }

  Future<void> delete(CategoryRule rule) async {
    if (rule.category == null) return;
    final list = (rule.type == ExpenseType.income) ? income : expense;
    final ind = list.indexWhere((it) => it.key == rule.key);
    list.removeAt(ind);
    appState.notifyListeners();
  }

  /// Rules are modified in place already. This function serves to notify listeners, and also update
  /// the database.
  Future<void> notifyUpdate(CategoryRule rule) async {
    appState.notifyListeners();
  }

  void reorder(ExpenseType type, int oldIndex, int newIndex) async {
    final list = (type == ExpenseType.income) ? income : expense;
    final rule = list.removeAt(oldIndex);
    if (newIndex > oldIndex) {
      list.insert(newIndex - 1, rule);
    } else {
      list.insert(newIndex, rule);
    }
    appState.notifyListeners();
  }

  //----------------------------------------------------------------------------
  // Parsing
  //----------------------------------------------------------------------------
  CategoryRule? match(String text, ExpenseType type) {
    final list = (type == ExpenseType.expense) ? expense : income;

    for (final rule in list) {
      if (text.contains(rule.pattern)) {
        return rule;
      }
    }
    return null;
  }
}
