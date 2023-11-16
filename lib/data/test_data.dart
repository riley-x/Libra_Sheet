import 'package:flutter/material.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/transaction.dart';

final List<Account> testAccounts = [
  Account(
    name: 'Robinhood',
    number: 'xxx-1234',
    balance: 13451200,
    lastUpdated: DateTime(2023, 11, 15),
    color: Colors.green,
  ),
  Account(
    name: 'Virgo',
    number: 'xxx-1234',
    balance: 4221100,
    lastUpdated: DateTime(2023, 10, 15),
    color: Colors.red,
  ),
  Account(
    name: 'TD',
    number: 'xxx-1234',
    balance: 124221100,
    lastUpdated: DateTime(2023, 10, 15),
    color: Colors.lightBlue,
  ),
];

final List<Transaction> testTransactions = [
  Transaction(
    name: "TARGET abbey is awesome",
    date: DateTime(2023, 11, 16),
    value: -502300,
    account: testAccounts[0],
  ),
  Transaction(
    name: "awefljawkelfjlkasdjflkajsdkljf klasdjfkljasl kdjfkla jsdlkfj",
    date: DateTime(2023, 11, 15),
    value: 502300,
  ),
  Transaction(
    name: "test test",
    date: DateTime(2023, 11, 12),
    value: 12322300,
  ),
];
