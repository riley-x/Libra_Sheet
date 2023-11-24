import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'package:flutter/material.dart';

Database? database;

FutureOr<void> initDatabase() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  /// /Users/riley/Library/Containers/com.example.libraSheet/Data/Documents/libra_sheet.db
  final path = join(await getDatabasesPath(), 'libra_sheet.db');
  debugPrint('initDatabase() path=$path');

  database = await openDatabase(
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
  await db.execute("CREATE TABLE IF NOT EXISTS `categories` ("
      "`key` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
      "`id` TEXT NOT NULL, "
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
}
