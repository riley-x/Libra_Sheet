// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'dart:math';

import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/database/rules.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/objects/category_rule.dart';
import 'package:libra_sheet/data/objects/category.dart';

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
    income.addAll(
        await getRules(ExpenseType.income, appState.categories.income.subCats.createKeyMap()));
    expense.addAll(
        await getRules(ExpenseType.expense, appState.categories.expense.subCats.createKeyMap()));
    appState.notifyListeners();
  }

  Future<void> add(CategoryRule rule) async {
    if (rule.category == null) return;
    final list = (rule.category!.type == ExpenseType.income) ? income : expense;
    int key = await insertRule(rule, listIndex: list.length);
    rule = rule.copyWith(key: key);
    list.add(rule);
    appState.notifyListeners();
  }

  Future<void> delete(CategoryRule rule) async {
    if (rule.category == null) return;
    final list = (rule.category!.type == ExpenseType.income) ? income : expense;
    list.removeWhere((it) => it.key == rule.key);
    appState.notifyListeners();
    await deleteRule(rule);
  }

  /// Rules are modified in place already. This function serves to notify listeners, and also update
  /// the database.
  Future<void> notifyUpdate(CategoryRule rule) async {
    appState.notifyListeners();
    await updateRule(rule);
  }

  // void reorder(Category parent, int oldIndex, int newIndex) async {
  //   final cat = parent.subCats.removeAt(oldIndex);
  //   if (newIndex > oldIndex) {
  //     parent.subCats.insert(newIndex - 1, cat);
  //   } else {
  //     parent.subCats.insert(newIndex, cat);
  //   }
  //   appState.notifyListeners();

  //   await libraDatabase?.transaction((txn) async {
  //     if (newIndex > oldIndex) {
  //       await shiftListIndicies(parent.key, oldIndex, newIndex, -1, db: txn);
  //       await updateCategory(cat, listIndex: newIndex - 1, db: txn);
  //     } else {
  //       await shiftListIndicies(parent.key, newIndex, oldIndex, 1, db: txn);
  //       await updateCategory(cat, listIndex: newIndex, db: txn);
  //     }
  //   });
}
