// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/database/categories.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/enums.dart';

/// Helper module for handling the categories
class CategoryState {
  //----------------------------------------------------------------------------
  // Fields
  //----------------------------------------------------------------------------
  LibraAppState appState;
  CategoryState(this.appState);

  Category income = Category.income;
  Category expense = Category.expense;

  //----------------------------------------------------------------------------
  // Loading
  //----------------------------------------------------------------------------
  Future<void> load() async {}

  //----------------------------------------------------------------------------
  // Editing and updating categories
  //----------------------------------------------------------------------------
  void add(Category cat) async {
    debugPrint("CategoryState::add() $cat");
    cat.parent!.subCats.add(cat);
    appState.notifyListeners();
  }

  void delete(Category cat, {Category? oldParent, bool deleteFromDatabase = true}) async {
    debugPrint("CategoryState::delete() $cat");
    final parentList = cat.parent!.subCats;
    final ind = parentList.indexWhere((it) => it.key == cat.key);
    parentList.removeAt(ind);
    appState.notifyListeners();
  }

  Future<void> update(Category cat, Category? oldParent) async {
    debugPrint("CategoryState::update() $cat");
    if (cat.parent != oldParent) {
      delete(cat, oldParent: oldParent, deleteFromDatabase: false);
      cat.parent!.subCats.add(cat);
    }
    appState.notifyListeners();
  }

  void reorder(Category parent, int oldIndex, int newIndex) async {
    final cat = parent.subCats.removeAt(oldIndex);
    if (newIndex > oldIndex) {
      parent.subCats.insert(newIndex - 1, cat);
    } else {
      parent.subCats.insert(newIndex, cat);
    }
    appState.notifyListeners();
  }

  //----------------------------------------------------------------------------
  // List retrieval helpers
  //----------------------------------------------------------------------------

  /// Gets a flattened list of all categories and their subcategories for the given expense type.
  /// Useful for selection menus for picking out any category.
  List<Category> flattenedCategories([ExpenseFilterType type = ExpenseFilterType.all]) {
    List<Category> nested;
    switch (type) {
      case ExpenseFilterType.all:
        nested = income.subCats + expense.subCats;
      case ExpenseFilterType.income:
        nested = income.subCats;
      case ExpenseFilterType.expense:
        nested = expense.subCats;
    }

    final out = <Category>[];
    for (final cat in nested) {
      out.add(cat);
      for (final subCat in cat.subCats) {
        out.add(subCat);
      }
    }
    return out;
  }

  /// Gets a list of potential parent categories. Excludes [current] from the list. Prepends
  /// the corresponding super category to [current.type].
  List<Category> getPotentialParents(Category current) {
    List<Category> out = [];
    if (current.type case ExpenseFilterType.expense) {
      out.add(expense);
      for (final cat in expense.subCats) {
        if (cat != current) out.add(cat);
      }
    } else if (current.type case ExpenseFilterType.income) {
      out.add(income);
      for (final cat in income.subCats) {
        if (cat != current) out.add(cat);
      }
    }
    return out;
  }

  void _updateKeyMap(Map<int, Category> map, Category cat) {
    map[cat.key] = cat;
    for (final subCat in cat.subCats) {
      _updateKeyMap(map, subCat);
    }
  }

  // TODO cache this?
  Map<int, Category> createKeyMap() {
    final out = <int, Category>{
      Category.empty.key: Category.empty,
      Category.ignore.key: Category.ignore,
      Category.investment.key: Category.investment,
    };
    _updateKeyMap(out, income);
    _updateKeyMap(out, expense);
    return out;
  }
}
