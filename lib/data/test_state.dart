import 'package:flutter/material.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/data/test_data.dart';

class LibraAppState extends ChangeNotifier {
  final List<TimeValue> chartData = [
    TimeValue.monthEnd(2019, 1, 35),
    TimeValue.monthEnd(2019, 2, 28),
    TimeValue.monthEnd(2019, 3, 34),
    TimeValue.monthEnd(2019, 4, 32),
    TimeValue.monthEnd(2019, 5, 40),
    TimeValue.monthEnd(2019, 6, 35),
    TimeValue.monthEnd(2019, 7, 28),
    TimeValue.monthEnd(2019, 8, 34.140001),
    TimeValue.monthEnd(2019, 9, 32.01),
    TimeValue.monthEnd(2019, 10, 40.10)
  ];

  final List<Account> accounts = testAccounts;

  void increment() {
    notifyListeners();
  }
}
