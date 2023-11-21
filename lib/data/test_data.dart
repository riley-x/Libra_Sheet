import 'package:flutter/material.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/tag.dart';
import 'package:libra_sheet/data/transaction.dart';

final List<Account> testAccounts = [
  Account(
    key: 1,
    name: 'Robinhood',
    number: 'xxx-1234',
    balance: 13451200,
    lastUpdated: DateTime(2023, 11, 15),
    color: Colors.green,
  ),
  Account(
    key: 2,
    name: 'Virgo',
    number: 'xxx-1234',
    balance: 4221100,
    lastUpdated: DateTime(2023, 10, 15),
    color: Colors.red,
  ),
  Account(
    key: 3,
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

const testCategoryValues = [
  CategoryValue(key: 1, level: 1, name: 'cat 1', color: Colors.amber, value: 357000),
  CategoryValue(key: 2, level: 1, name: 'cat 2', color: Colors.blue, value: 23000),
  CategoryValue(key: 3, level: 1, name: 'cat 3', color: Colors.green, value: 1000000, subCats: [
    CategoryValue(key: 4, level: 2, name: 'subcat 1', color: Colors.grey, value: 200000),
    CategoryValue(key: 5, level: 2, name: 'subcat 2', color: Colors.greenAccent, value: 200000),
    CategoryValue(key: 6, level: 2, name: 'subcat 3', color: Colors.lightGreen, value: 200000),
    CategoryValue(
        key: 7, level: 2, name: 'subcat 4', color: Colors.lightGreenAccent, value: 200000),
    CategoryValue(key: 8, level: 2, name: 'subcat 5', color: Colors.green, value: 200000),
  ]),
  CategoryValue(key: 9, level: 1, name: 'cat 4', color: Colors.red, value: 223000),
  CategoryValue(key: 10, level: 1, name: 'cat 5', color: Colors.purple, value: 43000),
];

const testTags = [
  Tag(key: 0, name: 'Tag 1', color: Colors.amber),
  Tag(key: 0, name: 'Tag 2', color: Colors.green),
  Tag(key: 0, name: 'Tag 3', color: Colors.blue),
];
