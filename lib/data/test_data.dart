import 'package:flutter/material.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/allocation.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/objects/category_rule.dart';
import 'package:libra_sheet/data/objects/reimbursement.dart';
import 'package:libra_sheet/data/objects/tag.dart';
import 'package:libra_sheet/data/objects/transaction.dart';

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
  Category(key: 1, name: 'cat 1', color: Colors.amber, parent: Category.expense),
  Category(key: 2, name: 'cat 2', color: Colors.blue, parent: Category.expense),
  Category(key: 3, name: 'cat 3', color: Colors.green, parent: Category.expense),
  Category(key: 9, name: 'cat 4', color: Colors.red, parent: Category.expense),
  Category(key: 10, name: 'cat 5', color: Colors.purple, parent: Category.expense),
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

final testTags = [
  Tag(key: 0, name: 'Tag 1', color: Colors.amber),
  Tag(key: 1, name: 'Tag 2', color: Colors.green),
  Tag(key: 2, name: 'Tag 3', color: Colors.blue),
];

final testRules = [
  CategoryRule(
      key: 1,
      pattern: "THIASDF ASDF LKASDJF ASDFKLJ",
      category: testCategories[0],
      type: ExpenseType.expense),
  CategoryRule(
      key: 2,
      pattern: "4320558230495890358",
      category: testCategories[1],
      type: ExpenseType.expense),
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
    category: testCategories[0],
    reimbursements: [],
    tags: testTags,
  ),
  Transaction(
    key: 2,
    name: "awefljawkelfjlkasdjflkajsdkljf klasdjfkljasl kdjfkla jsdlkfj",
    date: DateTime(2023, 11, 15),
    value: 1502300,
    category: Category.income,
  ),
  Transaction(
    key: 3,
    name: "test test",
    date: DateTime(2023, 11, 12),
    value: 12322300,
    category: Category.income,
  ),
];

final List<Reimbursement> testReimbursements = [
  Reimbursement(
    target: testTransactions[1],
    value: 2300,
  ),
];

void initializeTestData() {
  testTransactions[0].reimbursements!.add(testReimbursements[0]);

  // Category.expense.subCats.addAll(testCategories);

  final parent = testCategories[2];
  parent.subCats.addAll([
    Category(key: 4, name: 'subcat 1', color: Colors.grey, parent: parent),
    Category(key: 5, name: 'subcat 2', color: Colors.greenAccent, parent: parent),
    Category(key: 6, name: 'subcat 3', color: Colors.lightGreen, parent: parent),
    Category(key: 7, name: 'subcat 4', color: Colors.lightGreenAccent, parent: parent),
    Category(key: 8, name: 'subcat 5', color: Colors.green, parent: parent),
  ]);
}
