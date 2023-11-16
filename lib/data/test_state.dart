import 'package:flutter/material.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/time_value.dart';

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

  final List<Account> accounts = [
    Account(
        name: 'Robinhood',
        number: 'xxx-1234',
        balance: 13451200,
        lastUpdated: DateTime(2023, 11, 15)),
    Account(
      name: 'Virgo',
      number: 'xxx-1234',
      balance: 4221100,
      lastUpdated: DateTime(2023, 10, 15),
    ),
    Account(
      name: 'TD',
      number: 'xxx-1234',
      balance: 124221100,
      lastUpdated: DateTime(2023, 10, 15),
    ),
  ];

  void increment() {
    notifyListeners();
  }
}
