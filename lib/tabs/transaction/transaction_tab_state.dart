import 'package:flutter/material.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/test_data.dart';
import 'package:libra_sheet/data/transaction.dart';

class TransactionTabState extends ChangeNotifier {
  DateTime? startTime;
  DateTime? endTime;
  bool startTimeError = false;
  bool endTimeError = false;

  double? minValue;
  double? maxValue;
  bool minValueError = false;
  bool maxValueError = false;

  Set<ExpenseType> expenseFilterSelected = {};
  Set<int> accountFilterSelected = {};
  Set<int> categoryFilterSelected = {};

  List<Transaction> transactions = testTransactions;
  Transaction? focusedTransaction;

  void focus(Transaction? trans) {
    focusedTransaction = trans;
    notifyListeners();
  }

  void setExpenseFilter(Set<ExpenseType> newSelection) {
    expenseFilterSelected = newSelection;
    notifyListeners();
  }

  void setAccountFilter(Account account, bool selected) {
    if (selected) {
      accountFilterSelected.add(account.key);
    } else {
      accountFilterSelected.remove(account.key);
    }
    notifyListeners();
  }

  void setCategoryFilter(Category cat, bool selected) {
    if (selected) {
      categoryFilterSelected.add(cat.key);
    } else {
      categoryFilterSelected.remove(cat.key);
    }
    notifyListeners();
  }

  (double?, bool) _strToDbl(String? text) {
    double? val;
    bool error = false;
    if (text == null || text.isEmpty) {
      // pass
    } else {
      val = double.tryParse(text);
      if (val == null) {
        error = true;
      }
    }
    debugPrint('TransactionTabState::_strToDbl() text:$text val=$val error=$error');
    return (val, error);
  }

  void setMinValue(String? text) {
    final val = _strToDbl(text);
    if (minValue != val.$1) {
      // TODO load transactions
      minValue = val.$1;
      minValueError = val.$2;
      notifyListeners();
    } else if (minValueError != val.$2) {
      minValueError = val.$2;
      notifyListeners();
    }
  }

  void setMaxValue(String? text) {
    final val = _strToDbl(text);
    if (maxValue != val.$1) {
      // TODO load transactions
      maxValue = val.$1;
      maxValueError = val.$2;
      notifyListeners();
    } else if (maxValueError != val.$2) {
      maxValueError = val.$2;
      notifyListeners();
    }
  }
}
