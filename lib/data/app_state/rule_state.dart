// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'package:flutter/material.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/database/rules.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/objects/category_rule.dart';

/// Helper module for handling the category rules
class RuleState {
  //----------------------------------------------------------------------------
  // Fields
  //----------------------------------------------------------------------------
  LibraAppState appState;
  RuleState(this.appState);

  Map<Category, List<CategoryRule>> income = {};
  Map<Category, List<CategoryRule>> expense = {};

  //----------------------------------------------------------------------------
  // Modification Functions
  //----------------------------------------------------------------------------
  Future<void> load() async {
    final map = appState.categories.createKeyMap();
    final incomeRules = await getRules(ExpenseType.income, map);
    final expenseRules = await getRules(ExpenseType.expense, map);

    // Doing this forces the order of the rules in each map to align with the category order
    income = {for (final cat in map.values) cat: []};
    expense = {for (final cat in map.values) cat: []};
    for (final rule in incomeRules) {
      if (rule.category == null) continue;
      income[rule.category!]?.add(rule);
    }
    for (final rule in expenseRules) {
      if (rule.category == null) continue;
      expense[rule.category!]?.add(rule);
    }

    appState.notifyListeners();
  }

  Future<void> add(CategoryRule rule) async {
    debugPrint("RuleState::add() $rule");
    if (rule.category == null) return;
    final map = (rule.type == ExpenseType.income) ? income : expense;
    int key = await insertRule(rule, listIndex: 0);
    rule = rule.copyWith(key: key);
    map[rule.category!]?.add(rule);
    appState.notifyListeners();
  }

  Future<void> delete(CategoryRule rule) async {
    debugPrint("RuleState::delete() $rule");
    if (rule.category == null) return;
    final map = (rule.type == ExpenseType.income) ? income : expense;
    map[rule.category!]?.removeWhere((it) => it.key == rule.key);
    appState.notifyListeners();
  }

  /// The rule members are modified in place already. This function serves to move the rule if the
  /// category has changed, notify listeners, and also update the database.
  Future<void> update(CategoryRule rule, Category? originalCategory) async {
    debugPrint("RuleState::update() $rule");
    if (rule.category == null) return;

    final map = (rule.type == ExpenseType.income) ? income : expense;
    if (originalCategory != rule.category) {
      if (originalCategory != null) map[originalCategory]?.removeWhere((it) => it.key == rule.key);
      map[rule.category!]?.add(rule);
    }

    appState.notifyListeners();
    await updateRule(rule);
  }

  //----------------------------------------------------------------------------
  // Parsing
  //----------------------------------------------------------------------------
  /// Finds the category rule that matches [text] and [type]. If there are multiple matches, returns
  /// the rule with the longest pattern length, priority to the first by category order.
  CategoryRule? match(String text, ExpenseType type) {
    final map = (type == ExpenseType.expense) ? expense : income;

    CategoryRule? bestRule;
    for (final entry in map.entries) {
      for (final rule in entry.value) {
        if (text.contains(rule.pattern)) {
          if (rule.pattern.length > (bestRule?.pattern.length ?? 0)) {
            bestRule = rule;
          }
        }
      }
    }

    return bestRule;
  }
}
