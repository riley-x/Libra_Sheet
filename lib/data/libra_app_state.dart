import 'package:flutter/material.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/data/test_data.dart';
import 'package:libra_sheet/data/transaction.dart';

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

  final List<Category> categories = testCategoryValues;

  /// Current transaction being focused. If not null, shows the transaction details screen with this
  /// transaction as the initial values (and uses its key for update operations).
  Transaction? focusTransaction;

  void increment() {
    notifyListeners();
  }
}
