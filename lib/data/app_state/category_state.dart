import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/test_data.dart';

/// Helper module for handling the categories
class CategoryState {
  //----------------------------------------------------------------------------
  // Fields
  //----------------------------------------------------------------------------
  LibraAppState parent;
  CategoryState(this.parent);

  List<Category> expenseList = [];
  List<Category> incomeList = List.from(testCategories);

  //----------------------------------------------------------------------------
  // Editing and updating categories
  //----------------------------------------------------------------------------
  void reorder(bool isExpense, int oldIndex, int newIndex) {
    final list = (isExpense) ? expenseList : incomeList;
    if (newIndex > oldIndex) {
      list.insert(newIndex - 1, list.removeAt(oldIndex));
    } else {
      list.insert(newIndex, list.removeAt(oldIndex));
    }
    parent.notifyListeners();
  }

  void reorderSub(Category parent, int oldIndex, int newIndex) {
    if (parent.subCats.isEmpty) return;
    final list = parent.subCats;
    if (newIndex > oldIndex) {
      list.insert(newIndex - 1, list.removeAt(oldIndex));
    } else {
      list.insert(newIndex, list.removeAt(oldIndex));
    }
    this.parent.notifyListeners();
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
        nested = incomeList + expenseList;
      case ExpenseFilterType.income:
        nested = incomeList;
      case ExpenseFilterType.expense:
        nested = expenseList;
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

  /// Gets a list of potential parent categories. Excludes [current] from the list. Also prepends
  /// [null] to indicate no parent (i.e. income or expense).
  List<Category?> getPotentialParents(Category current) {
    var out = <Category?>[null];
    final list = switch (current.type) {
      ExpenseType.expense => expenseList,
      ExpenseType.income => incomeList,
    };
    for (final cat in list) {
      if (cat != current) out.add(cat);
    }
    return out;
  }
}
