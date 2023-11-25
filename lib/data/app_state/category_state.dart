import 'package:flutter/material.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/database/categories.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/test_data.dart';

/// Helper module for handling the categories
class CategoryState {
  //----------------------------------------------------------------------------
  // Fields
  //----------------------------------------------------------------------------
  LibraAppState appState;
  CategoryState(this.appState);

  //----------------------------------------------------------------------------
  // Editing and updating categories
  //----------------------------------------------------------------------------
  void add(Category cat) async {
    debugPrint("CategoryState::add() $cat");
    int key = await insertCategory(cat, listIndex: cat.parent!.subCats.length);
    cat = cat.copyWith(key: key);
    cat.parent!.subCats.add(cat);
    appState.notifyListeners();
  }

  void delete(Category cat) {
    debugPrint("CategoryState::delete() $cat");
    final parentList = cat.parent!.subCats;
    final ind = parentList.indexOf(cat);
    parentList.removeAt(ind);
    appState.notifyListeners();

    /// We don't delete from the database because no real need, and also used by [update].
    shiftListIndicies(cat.parent!.key, ind + 1, -1);
  }

  void update(Category old, Category cat) {
    if (old.parent != cat.parent) {
      delete(old);
      add(cat);
    } else {
      debugPrint("CategoryState::update() $cat");
      final parentList = cat.parent!.subCats;
      final ind = parentList.indexOf(cat);
      parentList[ind] = cat;
      appState.notifyListeners();
      updateCategory(cat);
    }
  }

  void save(Category cat) {
    if (cat.key == 0) {
      add(cat);
    } else {
      /// update old category
    }
  }

  void reorder(Category parent, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      parent.subCats.insert(newIndex - 1, parent.subCats.removeAt(oldIndex));
    } else {
      parent.subCats.insert(newIndex, parent.subCats.removeAt(oldIndex));
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
        nested = Category.income.subCats + Category.expense.subCats;
      case ExpenseFilterType.income:
        nested = Category.income.subCats;
      case ExpenseFilterType.expense:
        nested = Category.expense.subCats;
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
    if (current.type case ExpenseType.expense) {
      out.add(Category.expense);
      for (final cat in Category.expense.subCats) {
        if (cat != current) out.add(cat);
      }
    } else if (current.type case ExpenseType.income) {
      out.add(Category.income);
      for (final cat in Category.income.subCats) {
        if (cat != current) out.add(cat);
      }
    }
    return out;
  }
}
