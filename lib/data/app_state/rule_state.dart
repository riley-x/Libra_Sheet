// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'package:flutter/foundation.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/database/database_setup.dart';
import 'package:libra_sheet/data/database/rules.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/objects/category_rule.dart';

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
    final map = appState.categories.createKeyMap();
    income.addAll(await getRules(ExpenseType.income, map));
    expense.addAll(await getRules(ExpenseType.expense, map));
    appState.notifyListeners();
  }

  Future<void> add(CategoryRule rule) async {
    debugPrint("RuleState::add() $rule");
    if (rule.category == null) return;
    final list = (rule.type == ExpenseType.income) ? income : expense;
    int key = await insertRule(rule, listIndex: list.length);
    rule = rule.copyWith(key: key);
    list.add(rule);
    appState.notifyListeners();
  }

  Future<void> delete(CategoryRule rule) async {
    if (rule.category == null) return;
    final list = (rule.type == ExpenseType.income) ? income : expense;
    final ind = list.indexWhere((it) => it.key == rule.key);
    list.removeAt(ind);
    appState.notifyListeners();

    await libraDatabase?.transaction((txn) async {
      await deleteRule(rule, db: txn);
      await shiftRuleIndicies(rule.type, ind + 1, list.length + 1, -1, db: txn);
    });
  }

  /// Rules are modified in place already. This function serves to notify listeners, and also update
  /// the database.
  Future<void> notifyUpdate(CategoryRule rule) async {
    appState.notifyListeners();
    await updateRule(rule);
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

    await libraDatabase?.transaction((txn) async {
      if (newIndex > oldIndex) {
        await shiftRuleIndicies(type, oldIndex, newIndex, -1, db: txn);
        await updateRule(rule, listIndex: newIndex - 1, db: txn);
      } else {
        await shiftRuleIndicies(type, newIndex, oldIndex, 1, db: txn);
        await updateRule(rule, listIndex: newIndex, db: txn);
      }
    });
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
