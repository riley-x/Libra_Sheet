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
  Category other = Category.other;
  Category ignore = Category.ignore;

  //----------------------------------------------------------------------------
  // Loading
  //----------------------------------------------------------------------------
  Future<void> load() async {
    income.subCats.clear();
    expense.subCats.clear();
    await LibraDatabase.readTransaction((txn) async {
      await txn.loadChildCategories(income);
      await txn.loadChildCategories(expense);
    });
    debugPrint(
        "CategoryState::load() Loaded ${income.subCats.length}+${expense.subCats.length} categories");
  }

  //----------------------------------------------------------------------------
  // Editing and updating categories
  //----------------------------------------------------------------------------
  void add(Category cat) async {
    debugPrint("CategoryState::add() $cat");
    LibraDatabase.update((db) async {
      cat.key = await db.insertCategory(cat, listIndex: cat.parent!.subCats.length);
    });
    cat.parent!.subCats.add(cat);
    appState.notifyListeners();
  }

  void delete(Category cat, {Category? oldParent, bool deleteFromDatabase = true}) async {
    debugPrint("CategoryState::delete() $cat");
    final parentList = oldParent?.subCats ?? cat.parent!.subCats;
    final ind = parentList.indexWhere((it) => it.key == cat.key);
    parentList.removeAt(ind);
    appState.notifyListeners();

    if (deleteFromDatabase) await LibraDatabase.backup(tag: '.before_delete_category');
    await LibraDatabase.updateTransaction((txn) async {
      if (deleteFromDatabase) {
        await txn.deleteCategory(cat);
      }
      await txn.shiftCategoryListIndicies(cat.parent!.key, ind + 1, parentList.length + 1, -1);
    });
    if (deleteFromDatabase) {
      /// We basically have to reset everything. Anything that watches transactions, reload the rules,
      /// reset any category filters, etc. So this is easier, though it does reset the navigation
      /// (which is necessary because nested states have category filters, etc.)
      await appState.onDatabaseReplaced();
    }
  }

  Future<void> update(Category cat, Category? oldParent) async {
    debugPrint("CategoryState::update() $cat");
    int? listIndex;
    if (cat.parent != oldParent) {
      delete(cat, oldParent: oldParent, deleteFromDatabase: false);
      listIndex = cat.parent!.subCats.length;
      cat.parent!.subCats.add(cat);
    }
    appState.notifyListeners();
    await LibraDatabase.update((db) async => await db.updateCategory(cat, listIndex: listIndex));
  }

  void reorder(Category parent, int oldIndex, int newIndex) async {
    final cat = parent.subCats.removeAt(oldIndex);
    if (newIndex > oldIndex) {
      parent.subCats.insert(newIndex - 1, cat);
    } else {
      parent.subCats.insert(newIndex, cat);
    }
    appState.notifyListeners();

    await LibraDatabase.updateTransaction((txn) async {
      if (newIndex > oldIndex) {
        await txn.shiftCategoryListIndicies(parent.key, oldIndex, newIndex, -1);
        await txn.updateCategory(cat, listIndex: newIndex - 1);
      } else {
        await txn.shiftCategoryListIndicies(parent.key, newIndex, oldIndex, 1);
        await txn.updateCategory(cat, listIndex: newIndex);
      }
    });
  }

  //----------------------------------------------------------------------------
  // List retrieval helpers
  //----------------------------------------------------------------------------

  /// Gets a list of parent categories.
  List<Category> parentCategories([ExpenseFilterType type = ExpenseFilterType.all]) {
    switch (type) {
      case ExpenseFilterType.all:
        return income.subCats + expense.subCats;
      case ExpenseFilterType.income:
        return income.subCats;
      case ExpenseFilterType.expense:
        return expense.subCats;
    }
  }

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
      Category.other.key: Category.other,
    };
    _updateKeyMap(out, income);
    _updateKeyMap(out, expense);
    return out;
  }
}
