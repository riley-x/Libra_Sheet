import 'dart:async';
import 'package:libra_sheet/data/database/categories.dart';
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
  await db.execute("CREATE TABLE IF NOT EXISTS `accounts` ("
      "`key` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
      "`name` TEXT NOT NULL, "
      "`description` TEXT NOT NULL, "
      "`type` TEXT NOT NULL, "
      "`csvPattern` TEXT NOT NULL DEFAULT '', "
      "`screenReaderAlias` TEXT NOT NULL DEFAULT '', "
      "`colorLong` INTEGER NOT NULL, "
      "`listIndex` INTEGER NOT NULL, "
      "`balance` INTEGER NOT NULL)");
  await db.execute("CREATE TABLE IF NOT EXISTS $categoryTable ("
      "`key` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
      "`name` TEXT NOT NULL, "
      "`colorLong` INTEGER NOT NULL, "
      "`parentKey` INTEGER NOT NULL, "
      "`listIndex` INTEGER NOT NULL)");
  await db.execute("CREATE TABLE IF NOT EXISTS `rules` ("
      "`key` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
      "`pattern` TEXT NOT NULL, "
      "`categoryKey` INTEGER NOT NULL, "
      "`isIncome` INTEGER NOT NULL, "
      "`listIndex` INTEGER NOT NULL)");
  await db.execute("CREATE TABLE IF NOT EXISTS `category_history` ("
      "`accountKey` INTEGER NOT NULL, "
      "`categoryKey` INTEGER NOT NULL, "
      "`date` INTEGER NOT NULL, "
      "`value` INTEGER NOT NULL, "
      "PRIMARY KEY(`accountKey`, `categoryKey`, `date`))");
  await db.execute("CREATE TABLE IF NOT EXISTS `transaction_table` "
      "(`key` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
      "`name` TEXT NOT NULL, "
      "`date` INTEGER NOT NULL, "
      "`accountKey` INTEGER NOT NULL, "
      "`categoryKey` INTEGER NOT NULL, "
      "`value` INTEGER NOT NULL, "
      "`valueAfterReimbursements` INTEGER NOT NULL)");
  await db.execute("CREATE TABLE IF NOT EXISTS `allocations` ("
      "`key` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
      "`name` TEXT NOT NULL, "
      "`transactionKey` INTEGER NOT NULL, "
      "`categoryKey` INTEGER NOT NULL, "
      "`value` INTEGER NOT NULL, "
      "`listIndex` INTEGER NOT NULL)");
  await db.execute("CREATE TABLE IF NOT EXISTS `reimbursements` ("
      "`expenseId` INTEGER NOT NULL, "
      "`incomeId` INTEGER NOT NULL, "
      "`value` INTEGER NOT NULL, "
      "PRIMARY KEY(`expenseId`, `incomeId`))");
  await db.execute("CREATE TABLE IF NOT EXISTS `tags` ("
      "`key` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
      "`name` TEXT NOT NULL, "
      "`listIndex` INTEGER NOT NULL)");
  await db.execute("CREATE TABLE IF NOT EXISTS `tag_join` ("
      "`transactionKey` INTEGER NOT NULL, "
      "`tagKey` INTEGER NOT NULL, "
      "PRIMARY KEY(`transactionKey`, `tagKey`))");
  await db.execute('''
INSERT INTO "categories" ("key", "name", "colorLong", "parentKey", "listIndex") VALUES
('1', 'Paycheck', '4279939415', '-1', '0'),
('2', 'Cash Back', '4278607389', '-1', '1'),
('3', 'Gifts', '4293828260', '-1', '2'),
('4', 'Interest', '4285770954', '-1', '3'),
('5', 'Tax Refund', '4284238947', '-1', '4'),
('6', 'Household', '4293104896', '-2', '0'),
('7', 'Utilities', '4294957568', '6', '1'),
('8', 'Rent/Mortgage', '4286863910', '6', '0'),
('9', 'Supplies', '4292638720', '6', '2'),
('10', 'Food', '4283611708', '-2', '1'),
('11', 'Groceries', '4285851992', '10', '0'),
('12', 'Takeout', '4291882280', '10', '1'),
('13', 'Restaurants', '4278422059', '10', '2'),
('14', 'Snacks', '4285369631', '10', '3'),
('15', 'Alcohol', '4287806109', '10', '4');
''');
}
