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

final testCategories = [
  Category(key: 1, level: 1, name: 'cat 1', color: Colors.amber, parent: Category.expense),
  Category(key: 2, level: 1, name: 'cat 2', color: Colors.blue, parent: Category.expense),
  Category(
      key: 3,
      level: 1,
      name: 'cat 3',
      color: Colors.green,
      parent: Category.expense,
      subCats: [
        Category(key: 4, level: 2, name: 'subcat 1', color: Colors.grey, parent: Category.expense),
        Category(
            key: 5,
            level: 2,
            name: 'subcat 2',
            color: Colors.greenAccent,
            parent: Category.expense),
        Category(
            key: 6, level: 2, name: 'subcat 3', color: Colors.lightGreen, parent: Category.expense),
        Category(
            key: 7,
            level: 2,
            name: 'subcat 4',
            color: Colors.lightGreenAccent,
            parent: Category.expense),
        Category(key: 8, level: 2, name: 'subcat 5', color: Colors.green, parent: Category.expense),
      ]),
  Category(key: 9, level: 1, name: 'cat 4', color: Colors.red, parent: Category.expense),
  Category(key: 10, level: 1, name: 'cat 5', color: Colors.purple, parent: Category.expense),
];

const testCategoryValues = {
  1: 357000,
  2: 23000,
  3: 1000000,
  4: 200000,
  5: 200000,
  6: 200000,
  7: 200000,
  8: 200000,
  9: 223000,
  10: 43000
};

const testTags = [
  Tag(key: 0, name: 'Tag 1', color: Colors.amber),
  Tag(key: 1, name: 'Tag 2', color: Colors.green),
  Tag(key: 2, name: 'Tag 3', color: Colors.blue),
];

final testAllocations = [
  Allocation(key: 0, name: 'Alloc 1', category: testCategories[0], value: 100000),
  Allocation(key: 1, name: 'Alloc 2', category: testCategories[1], value: 100000),
  Allocation(key: 2, name: 'Alloc 3', category: testCategories[2].subCats[0], value: 100000),
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
