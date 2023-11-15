import 'package:flutter/material.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/time_value.dart';

class LibraAppState extends ChangeNotifier {
  final List<TimeValue> chartData = [
    TimeValue.monthEnd(2010, 1, 35),
    TimeValue.monthEnd(2011, 2, 28),
    TimeValue.monthEnd(2012, 3, 34),
    TimeValue.monthEnd(2013, 4, 32),
    TimeValue.monthEnd(2014, 5, 40)
  ];

  final List<Account> accounts = [
    Account(
        name: 'Robinhood',
        number: 'xxx-1234',
        balance: 13451200,
        lastUpdated: DateTime(2023, 11, 15)),
    const Account(name: 'Virgo', number: 'xxx-1234', balance: -221100),
  ];

  void increment() {
    notifyListeners();
  }
}
