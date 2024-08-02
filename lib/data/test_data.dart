// ignore_for_file: use_full_hex_values_for_flutter_colors

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/allocation.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/objects/category_rule.dart';
import 'package:libra_sheet/data/objects/reimbursement.dart';
import 'package:libra_sheet/data/objects/tag.dart';
import 'package:libra_sheet/data/objects/transaction.dart';

final DateTime now = DateTime.now();
final rng = Random(0);

final List<Account> testAccounts = [
  Account(
    key: 3,
    type: AccountType.cash,
    name: 'Cash',
    description: '',
    balance: 200000,
    lastTransaction: now.subtract(const Duration(days: 5)),
    color: const Color(0xffb2d9c4),
  ),
  Account(
    key: 4,
    type: AccountType.cash,
    name: 'Venmo',
    description: '',
    balance: 232600,
    lastTransaction: now.subtract(const Duration(days: 5)),
    color: const Color(0xff80b9c8),
  ),
  Account(
    key: 1,
    type: AccountType.bank,
    name: 'Checkings',
    description: 'xxx-1234',
    balance: 4341200,
    lastTransaction: now.subtract(const Duration(days: 15)),
    color: const Color(0xffc29470),
  ),
  Account(
    key: 2,
    type: AccountType.bank,
    name: 'Savings',
    description: 'xxx-1234',
    balance: 14221100,
    lastTransaction: now.subtract(const Duration(days: 15)),
    color: const Color(0xff247d7f),
  ),
  Account(
    key: 5,
    type: AccountType.investment,
    name: 'IRA',
    description: 'xxxx-1234',
    balance: 18238900,
    lastTransaction: now.subtract(const Duration(days: 32)),
    color: const Color(0xff44916f),
  ),
  Account(
    key: 6,
    type: AccountType.liability,
    name: 'Credit Card',
    description: 'xxxx-1234',
    balance: -1264900,
    lastTransaction: now.subtract(const Duration(days: 15)),
    color: Colors.pink.shade800,
  )
];

final testCategories = [
  Category(key: 1, color: const Color(4279939415), parent: Category.income, name: 'Paycheck'),
  Category(key: 2, color: const Color(4278607389), parent: Category.income, name: 'Cash Back'),
  Category(key: 3, color: const Color(4293828260), parent: Category.income, name: 'Gifts'),
  Category(key: 4, color: const Color(4285770954), parent: Category.income, name: 'Interest'),
  Category(key: 5, color: const Color(4284238947), parent: Category.income, name: 'Tax Refund'),

  ///
  Category(key: 10, color: const Color(4283611708), parent: Category.expense, name: 'Food'),
  Category(key: 16, color: const Color(4278434036), parent: Category.expense, name: 'Shopping'),
  Category(key: 6, color: const Color(4286531083), parent: Category.expense, name: 'Household'),
  Category(
      key: 21, color: const Color(4293960260), parent: Category.expense, name: 'Entertainment'),
  Category(key: 25, color: const Color(4291904339), parent: Category.expense, name: 'Health'),
  Category(
      key: 30, color: const Color(4281353876), parent: Category.expense, name: 'Transportation'),
  Category(key: 35, color: const Color(4287993237), parent: Category.expense, name: 'Other'),
];

void _initTestCategories() {
  Category.income.subCats.addAll(testCategories.sublist(0, 5));
  Category.expense.subCats.addAll(testCategories.sublist(5));

  final household = testCategories[7];
  household.subCats.addAll([
    Category(key: 7, color: const Color(4293303345), parent: household, name: 'Utilities'),
    Category(key: 8, color: const Color(4287500554), parent: household, name: 'Rent/Mortgage'),
    Category(key: 9, color: const Color(4290017826), parent: household, name: 'Supplies'),
  ]);

  final food = testCategories[5];
  food.subCats.addAll([
    Category(key: 11, color: const Color(4285851992), parent: food, name: 'Groceries'),
    Category(key: 12, color: const Color(4291882280), parent: food, name: 'Takeout'),
    Category(key: 13, color: const Color(4278422059), parent: food, name: 'Restaurants'),
    Category(key: 14, color: const Color(4285369631), parent: food, name: 'Snacks'),
    Category(key: 15, color: const Color(4287806109), parent: food, name: 'Alcohol'),
  ]);

  final shopping = testCategories[6];
  shopping.subCats.addAll([
    Category(key: 17, color: const Color(4283008198), parent: shopping, name: 'Clothes'),
    Category(key: 18, color: const Color(4282903786), parent: shopping, name: 'Electronics'),
    Category(key: 19, color: const Color(4283925399), parent: shopping, name: 'Furniture'),
    Category(key: 20, color: const Color(4278937202), parent: shopping, name: 'Gifts'),
  ]);

  final entertainment = testCategories[8];
  entertainment.subCats.addAll([
    Category(key: 22, color: const Color(4289683232), parent: entertainment, name: 'Subscriptions'),
    Category(key: 23, color: const Color(4293907217), parent: entertainment, name: 'Games'),
    Category(
        key: 24, color: const Color(4292836714), parent: entertainment, name: 'Movies & Events'),
  ]);

  final health = testCategories[9];
  health.subCats.addAll([
    Category(key: 26, color: const Color(4291053104), parent: health, name: 'Pharmacy'),
    Category(key: 27, color: const Color(4294923164), parent: health, name: 'Beauty'),
    Category(key: 28, color: const Color(4290810794), parent: health, name: 'Copays'),
    Category(key: 29, color: const Color(4288020487), parent: health, name: 'Insurance'),
  ]);

  final transportation = testCategories[10];
  transportation.subCats.addAll([
    Category(key: 31, color: const Color(4284443815), parent: transportation, name: 'Car'),
    Category(key: 32, color: const Color(4283382146), parent: transportation, name: 'Gas'),
    Category(key: 33, color: const Color(4282349036), parent: transportation, name: 'Taxis'),
    Category(key: 34, color: const Color(4289710333), parent: transportation, name: 'Fares'),
  ]);

  final other = testCategories[11];
  other.subCats.addAll([
    Category(key: 37, color: const Color(4289687417), parent: other, name: 'Taxes'),
    Category(key: 38, color: const Color(4287460443), parent: other, name: 'Services'),
  ]);
}

Map<int, List<int>> testCategoryHistory = {
  1: List.generate(13, (index) => 40000000),
  2: [1000000, 0, 0, 0, 1000000, 0, 0, 0, 1220000, 0, 0, 0, 1000000],
  3: [0, 1000000, 0, 0, 0, 0, 0, 0, 0, 0, 0, 420000, 200000],
  4: List.generate(13, (index) => 0),
  5: List.generate(13, (index) => 0),

  /// Household
  6: List.generate(13, (index) => 0),
  7: List.generate(13, (index) => 200000 + rng.nextInt(1000000)),
  8: List.generate(13, (index) => 12000000),
  9: List.generate(14, (index) => rng.nextInt(1000000)),

  /// Food
  10: List.generate(13, (index) => 0),
  11: List.generate(13, (index) => 4000000 + rng.nextInt(1000000)),
  12: List.generate(13, (index) => 2000000 + rng.nextInt(1000000)),
  13: List.generate(13, (index) => 3000000 + rng.nextInt(1000000)),
  14: List.generate(14, (index) => 200000 + rng.nextInt(300000)),

  /// Shopping
  16: List.generate(14, (index) => rng.nextInt(1000000)),
  17: List.generate(14, (index) => rng.nextInt(1000000)),
  18: List.generate(14, (index) => rng.nextInt(1000000)),
  20: List.generate(14, (index) => rng.nextInt(1000000)),

  /// Entertainment
  22: List.generate(14, (index) => 600000),
  24: List.generate(14, (index) => rng.nextInt(1000000)),

  /// Health
  26: List.generate(14, (index) => 300000 + rng.nextInt(10000) * 100),
  27: List.generate(14, (index) => rng.nextInt(2000) * 100),

  /// Transportation
  33: List.generate(14, (index) => rng.nextInt(2000) * 100),
  34: List.generate(14, (index) => rng.nextInt(6000) * 100),
};

final testTags = [
  Tag(key: 0, name: 'Needs Reimbursement', color: Colors.red),
  Tag(key: 1, name: 'You', color: Colors.orange),
  Tag(key: 2, name: 'can', color: Colors.amber),
  Tag(key: 3, name: 'have', color: Colors.yellow),
  Tag(key: 4, name: 'multiple', color: Colors.lime),
  Tag(key: 5, name: 'tags', color: Colors.green),
  Tag(key: 6, name: 'per', color: Colors.teal),
  Tag(key: 7, name: 'transaction', color: Colors.blue),
  Tag(key: 8, name: '😎', color: Colors.indigo),
];

final testRules = [
  CategoryRule(
    key: 1,
    pattern: "DIRECT DEPOSIT",
    category: testCategories[0],
    type: ExpenseType.income,
  ),
  CategoryRule(
    key: 2,
    pattern: "AMAZON",
    category: testCategories[5],
    type: ExpenseType.expense,
  ),
];

final testAllocations = [
  Allocation(key: 0, name: 'Alloc 1', category: testCategories[0], value: 100000),
  Allocation(key: 1, name: 'Alloc 2', category: testCategories[1], value: 100000),
  Allocation(key: 2, name: 'Alloc 3', category: testCategories[2].subCats[0], value: 100000),
];

final List<Transaction> testTransactions = [
  Transaction(
    key: 0,
    name: "This is a transaction!",
    date: DateTime(2023, 11, 23),
    value: -502300,
    account: testAccounts[2],
    category: testCategories[5],
  ),
  Transaction(
    key: 0,
    name: "Each transaction is assigned a category",
    date: DateTime(2023, 11, 22),
    value: -122300,
    account: testAccounts[2],
    category: testCategories[8],
  ),
  Transaction(
    key: 0,
    name: "But you can add allocations to split a transaction into multiple categories",
    date: DateTime(2023, 11, 21),
    value: -1050000,
    account: testAccounts[2],
    category: testCategories[6],
    allocations: [],
  ),
  Transaction(
    key: 0,
    name: "You can also add tags to transactions",
    date: DateTime(2023, 11, 20),
    value: 20428900,
    account: testAccounts[3],
    category: testCategories[0],
    tags: testTags.sublist(0, 1),
  ),
  Transaction(
    key: 0,
    name: "A transaction can have multiple tags",
    date: DateTime(2023, 11, 19),
    value: -326800,
    account: testAccounts[2],
    category: testCategories[7],
    tags: testTags.sublist(1),
  ),
  Transaction(
    key: 0,
    name: "And be reimbursed! Imagine you paid for dinner",
    note: "This only adds -\$32 to the restaurant category",
    date: DateTime(2023, 11, 18),
    value: -640000,
    account: testAccounts[2],
    category: testCategories[5],
    reimbursements: [],
  ),
  Transaction(
    key: 0,
    name: "And your friend Venmo'd you back 🍔",
    note: "This adds \$0 to your income",
    date: DateTime(2023, 11, 17),
    value: 320000,
    account: testAccounts[1],
    category: Category.income,
    reimbursements: [],
  ),
];

final List<Reimbursement> testReimbursements = [
  Reimbursement(
    target: testTransactions[1],
    value: 2300,
    commitedValue: 2300,
  ),
];

void initializeTestData() {
  _initTestCategories();

  testTransactions[2]
      .allocations!
      .add(Allocation(name: '', category: testCategories[5].subCats[4], value: 100000));
  testTransactions[5].reimbursements!.add(Reimbursement(
        target: testTransactions[6],
        value: 320000,
        commitedValue: 320000,
      ));
  testTransactions[6].reimbursements!.add(Reimbursement(
        target: testTransactions[5],
        value: 320000,
        commitedValue: 320000,
      ));
}
