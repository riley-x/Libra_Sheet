import 'package:flutter/material.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/tag.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/data/test_data.dart';
import 'package:libra_sheet/data/transaction.dart';

enum DetailScreen {
  account,
  transaction,
}

class LibraAppState extends ChangeNotifier {
  final List<TimeValue> chartData = [
    TimeValue.monthStart(2019, 1, 35),
    TimeValue.monthStart(2019, 2, 28),
    TimeValue.monthStart(2019, 3, 34),
    TimeValue.monthStart(2019, 4, 32),
    TimeValue.monthStart(2019, 5, 40),
    TimeValue.monthStart(2019, 6, 35),
    TimeValue.monthStart(2019, 7, 28),
    TimeValue.monthStart(2019, 8, 34.140001),
    TimeValue.monthStart(2019, 9, 32.01),
    TimeValue.monthStart(2019, 10, 40.10)
  ];

  final List<Account> accounts = testAccounts;
  final List<Tag> tags = testTags;

  final List<Category> incomeCategories = [];
  final List<Category> expenseCategories = List.from(testCategoryValues);

  List<Category> flattenedCategories([ExpenseFilterType type = ExpenseFilterType.all]) {
    List<Category> nested;
    switch (type) {
      case ExpenseFilterType.all:
        nested = incomeCategories + expenseCategories;
      case ExpenseFilterType.income:
        nested = incomeCategories;
      case ExpenseFilterType.expense:
        nested = expenseCategories;
    }

    final out = <Category>[];
    for (final cat in nested) {
      out.add(cat);
      if (cat.subCats != null) {
        for (final subCat in cat.subCats!) {
          out.add(subCat);
        }
      }
    }
    return out;
  }

  /// Current tab as an index into [LibraNavDestination.values].
  int currentTab = 0;

  /// Current screen being displayed. When not empty, contains the back stack of detail screens.
  /// When empty, defaults to the main tab specified by LibraHomePage. The Object is the input used
  /// to initialize the respective screens.
  final List<(DetailScreen, Object?)> backStack = [];

  void setTab(int i) {
    if (currentTab != i || backStack.isNotEmpty) {
      currentTab = i;
      backStack.clear();
      notifyListeners();
    }
  }

  void popBackStack() {
    if (backStack.isNotEmpty) {
      backStack.removeLast();
      notifyListeners();
    }
  }

  void focusAccount(Account x) {
    // TODO maybe load the transactions here? And change to AccountWithTransactions?
    // Or maybe async load on Widget create...is that possible?
    backStack.add((DetailScreen.account, x));
    notifyListeners();
  }

  void focusTransaction(Transaction? t) {
    backStack.add((DetailScreen.transaction, t));
    notifyListeners();
  }

  void increment() {
    notifyListeners();
  }

  void reorderCategories(bool isExpense, int oldIndex, int newIndex) {
    final list = (isExpense) ? expenseCategories : incomeCategories;
    if (newIndex > oldIndex) {
      list.insert(newIndex - 1, list.removeAt(oldIndex));
    } else {
      list.insert(newIndex, list.removeAt(oldIndex));
    }
    notifyListeners();
  }
}
