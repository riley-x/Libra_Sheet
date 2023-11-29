import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:libra_sheet/data/database/accounts.dart';
import 'package:libra_sheet/data/database/allocations.dart';
import 'package:libra_sheet/data/database/categories.dart';
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/rules.dart';
import 'package:libra_sheet/data/database/tags.dart';
import 'package:libra_sheet/data/database/transactions.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'package:flutter/material.dart';

Database? libraDatabase;

FutureOr<void> initDatabase() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  /// /Users/riley/Library/Containers/com.example.libraSheet/Data/Documents/libra_sheet.db
  final path = join(await getDatabasesPath(), 'libra_sheet.db');
  debugPrint('initDatabase() path=$path');

  libraDatabase = await openDatabase(
    path,
    onCreate: _createDatabse,
    version: 14,
  );
}

FutureOr<void> _createDatabse(Database db, int version) {
  return switch (version) {
    14 => _createDatabse14(db),
    _ => null,
  };
}

FutureOr<void> _createDatabse14(Database db) async {
  await db.execute(createAccountsTableSql);
  await db.execute("CREATE TABLE IF NOT EXISTS $categoryTable ("
      "`key` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
      "`name` TEXT NOT NULL, "
      "`colorLong` INTEGER NOT NULL, "
      "`parentKey` INTEGER NOT NULL, "
      "`listIndex` INTEGER NOT NULL)");
  await db.execute(createCategoryHistoryTableSql);
  await db.execute(createRulesTableSql);
  await db.execute(createTagsTableSql);
  await db.execute(createTransactionsTableSql);
  await db.execute(createAllocationsTableSql);
  await db.execute("CREATE TABLE IF NOT EXISTS `reimbursements` ("
      "`expenseId` INTEGER NOT NULL, "
      "`incomeId` INTEGER NOT NULL, "
      "`value` INTEGER NOT NULL, "
      "PRIMARY KEY(`expenseId`, `incomeId`))");
  await db.execute(createTagJoinTableSql);
  await db.execute(createDefaultCategories);
  if (kDebugMode) {
    await db.execute(createTestAccountsSql);
    await db.execute(createTestTagsSql);
  }
}

const createDefaultCategories = '''
INSERT INTO "categories" ("key", "name", "colorLong", "parentKey", "listIndex") VALUES
('1', 'Paycheck', '4279939415', '-1', '0'),
('2', 'Cash Back', '4278607389', '-1', '1'),
('3', 'Gifts', '4293828260', '-1', '2'),
('4', 'Interest', '4285770954', '-1', '3'),
('5', 'Tax Refund', '4284238947', '-1', '4'),
('6', 'Household', '4294947100', '-2', '0'),
('7', 'Utilities', '4294957568', '6', '1'),
('8', 'Rent/Mortgage', '4286863910', '6', '0'),
('9', 'Supplies', '4292638720', '6', '2'),
('10', 'Food', '4283611708', '-2', '1'),
('11', 'Groceries', '4285851992', '10', '0'),
('12', 'Takeout', '4291882280', '10', '1'),
('13', 'Restaurants', '4278422059', '10', '2'),
('14', 'Snacks', '4285369631', '10', '3'),
('15', 'Alcohol', '4287806109', '10', '4'),
('16', 'Shopping', '4278434036', '-2', '2'),
('17', 'Clothes', '4283008198', '16', '0'),
('18', 'Electronics', '4282903786', '16', '1'),
('19', 'Furniture', '4283925399', '16', '2'),
('20', 'Gifts', '4278937202', '16', '3'),
('21', 'Entertainment', '4292821468', '-2', '3'),
('22', 'Subscriptions', '4290003343', '21', '0'),
('23', 'Games', '4293636323', '21', '1'),
('24', 'Attractions/Events', '4290532312', '21', '2'),
('25', 'Health', '4293404476', '-2', '4'),
('26', 'Pharmacy', '4291053104', '25', '0'),
('27', 'Beauty', '4294923164', '25', '1'),
('28', 'Copays', '4290810794', '25', '2'),
('29', 'Insurance', '4288020487', '25', '3'),
('30', 'Transportation', '4280963542', '-2', '5'),
('31', 'Car', '4284443815', '30', '0'),
('32', 'Gas', '4283382146', '30', '1'),
('33', 'Taxis', '4282349036', '30', '2'),
('34', 'Fares', '4289710333', '30', '3'),
('35', 'Other', '4287993237', '-2', '6'),
('36', 'Hotels', '4287322772', '35', '0'),
('37', 'Taxes', '4289687417', '35', '1'),
('38', 'Services', '4287460443', '35', '2');
''';
