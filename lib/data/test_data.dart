import 'package:flutter/material.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/allocation.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/reimbursement.dart';
import 'package:libra_sheet/data/tag.dart';
import 'package:libra_sheet/data/transaction.dart';

final List<Account> testAccounts = [
  Account(
    key: 1,
    name: 'Robinhood',
    description: 'xxx-1234',
    balance: 13451200,
    lastUpdated: DateTime(2023, 11, 15),
    color: Colors.green,
  ),
  Account(
    key: 2,
    name: 'Virgo',
    description: 'xxx-1234',
    balance: 4221100,
    lastUpdated: DateTime(2023, 10, 15),
    color: Colors.red,
  ),
  Account(
    key: 3,
    name: 'TD',
    description: 'xxx-1234',
    balance: 124221100,
    lastUpdated: DateTime(2023, 10, 15),
    color: Colors.lightBlue,
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
  Tag(key: 1, name: 'Tag 2', color: Colors.green),
  Tag(key: 2, name: 'Tag 3', color: Colors.blue),
];

final testAllocations = [
  Allocation(key: 0, name: 'Alloc 1', category: testCategoryValues[0], value: 100000),
  Allocation(key: 1, name: 'Alloc 2', category: testCategoryValues[1], value: 100000),
  Allocation(key: 2, name: 'Alloc 3', category: testCategoryValues[2].subCats![0], value: 100000),
];

final List<Transaction> testTransactions = [
  Transaction(
    key: 1,
    name: "TARGET abbey is awesome",
    date: DateTime(2023, 11, 16),
    value: -502300,
    account: testAccounts[0],
    reimbursements: [],
  ),
  Transaction(
    key: 2,
    name: "awefljawkelfjlkasdjflkajsdkljf klasdjfkljasl kdjfkla jsdlkfj",
    date: DateTime(2023, 11, 15),
    value: 1502300,
  ),
  Transaction(
    key: 3,
    name: "test test",
    date: DateTime(2023, 11, 12),
    value: 12322300,
  ),
];

final List<Reimbursement> testReimbursements = [
  Reimbursement(
    parentTransaction: testTransactions[0],
    otherTransaction: testTransactions[1],
    value: 2300,
  ),
];

void initializeTestData() {
  testTransactions[0].reimbursements!.add(testReimbursements[0]);
}
