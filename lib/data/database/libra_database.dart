import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/data/database/accounts.dart';
import 'package:libra_sheet/data/database/allocations.dart';
import 'package:libra_sheet/data/database/categories.dart';
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/reimbursements.dart';
import 'package:libra_sheet/data/database/rules.dart';
import 'package:libra_sheet/data/database/tags.dart';
import 'package:libra_sheet/data/database/transactions.dart';
import 'package:libra_sheet/data/export/google_drive.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

final _backupDateFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');

class LibraDatabase {
  //-------------------------------------------------------------------------------------
  // Singleton setup (is this even needed? everything is static)
  //-------------------------------------------------------------------------------------
  LibraDatabase._internal();
  static final LibraDatabase _instance = LibraDatabase._internal();
  factory LibraDatabase() {
    return _instance;
  }

  //-------------------------------------------------------------------------------------
  // Members
  //-------------------------------------------------------------------------------------
  static late String databasePath;
  static Database? _db;
  static Function(dynamic)? errorCallback;

  static Future<bool> isEmpty() async {
    if (_db == null) return true;
    return await _db!.countAccounts() == 0;
  }

  //-------------------------------------------------------------------------------------
  // Database setup
  //-------------------------------------------------------------------------------------
  static Future<String> _getDatabasePath() async {
    if (_db != null) return _db!.path;

    /// Windows: C:\Users\riley\Documents\Projects\libra_sheet\.dart_tool\sqflite_common_ffi\databases\libra_sheet.db
    /// Windows exe: C:\Users\riley\Documents\Projects\libra_sheet\build\windows\runner\Release\.dart_tool\sqflite_common_ffi\databases\libra_sheet.db
    /// Mac: /Users/riley/Library/Containers/com.example.libraSheet/Data/Documents/libra_sheet.db
    // final path = join(await getDatabasesPath(), 'libra_sheet.db');

    final appDocumentsDir = await getApplicationDocumentsDirectory();
    if (kDebugMode) {
      return join(appDocumentsDir.path, "Libra Sheet", "Debug", "libra_sheet.db");
    } else {
      return join(appDocumentsDir.path, "Libra Sheet", "libra_sheet.db");
    }
  }

  static Future<void> open() async {
    _db = await openDatabase(
      databasePath,
      version: 16,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    databasePath = await _getDatabasePath();
    debugPrint('LibraDatabase::init() path=$databasePath');
    await open();
  }

  static Future<void> close() async {
    _db?.close();
    _db = null;
  }

  //-------------------------------------------------------------------------------------
  // Actions
  //-------------------------------------------------------------------------------------

  static Future<void> sync() async {
    try {
      await GoogleDrive().logLocalUpdate();
    } catch (e) {
      debugPrint("LibraDatabase::sync() caught $e");
      errorCallback?.call(e);
    }
  }

  static Future<T?> read<T>(Future<T> Function(Database db) callback) async {
    try {
      if (_db == null) throw StateError("Database not initialized");
      return callback(_db!);
    } catch (e) {
      debugPrint("LibraDatabase::read() caught $e");
      errorCallback?.call(e);
      return null;
    }
  }

  /// Like [read] but will not catch any errors, instead passing them up to the caller.
  static Future<T> readThrow<T>(Future<T> Function(Database db) callback) async {
    if (_db == null) throw StateError("Database not initialized");
    return callback(_db!);
  }

  static Future<void> readTransaction(Future Function(Transaction txn) callback) async {
    try {
      if (_db == null) throw StateError("Database not initialized");
      await _db!.transaction(callback);
    } catch (e) {
      debugPrint("LibraDatabase::readTransaction() caught $e");
      errorCallback?.call(e);
    }
  }

  static Future<T?> update<T>(Future<T> Function(Database db) callback) async {
    try {
      if (_db == null) throw StateError("Database not initialized");
      final out = await callback(_db!);
      sync();
      return out;
    } catch (e) {
      debugPrint("LibraDatabase::update() caught $e");
      errorCallback?.call(e);
      return null;
    }
  }

  static Future<void> updateTransaction(Future Function(Transaction txn) callback) async {
    try {
      if (_db == null) throw StateError("Database not initialized");
      await _db!.transaction(callback);
      sync();
    } catch (e) {
      debugPrint("LibraDatabase::updateTransaction() caught $e");
      errorCallback?.call(e);
    }
  }

  //-------------------------------------------------------------------------------------
  // Backup
  //-------------------------------------------------------------------------------------
  static DateTime _lastBackupTime = DateTime.now();
  // DateTime.now().difference(_lastBackupTime).inSeconds > 10) backup();

  static Future<void> backup({String? tag}) async {
    _lastBackupTime = DateTime.now();
    final timestamp = _backupDateFormat.format(_lastBackupTime);

    String newPath;
    if (databasePath.endsWith('.db')) {
      newPath = "${databasePath.substring(0, databasePath.length - 3)}_$timestamp$tag.db";
    } else {
      newPath = "${databasePath}_$timestamp$tag";
    }
    await File(databasePath).copy(newPath);
    debugPrint("LibraDatabase::backup() Backed up to $newPath");
  }

  //-------------------------------------------------------------------------------------
  // Create
  //-------------------------------------------------------------------------------------
  static Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    await backup(tag: '_upgrade$oldVersion-$newVersion');
    if (oldVersion <= 14 && newVersion >= 15) {
      await _upgrade14_15(db, oldVersion, newVersion);
    }

    if (oldVersion <= 15 && newVersion >= 16) {
      await _upgrade15_16(db);
    }
  }
}

FutureOr<void> _createDatabase(Database db, int version) async {
  await db.execute(createAccountsTableSql);
  await db.execute(upgradeAccountsTableSql_15_16);
  await db.execute(createCategoryTableSql);
  await db.execute(createCategoryHistoryTableSql);
  await db.execute(createRulesTableSql);
  await db.execute(createTagsTableSql);
  await db.execute(createTransactionsTableSql);
  await db.execute(createAllocationsTableSql);
  await db.execute(createReimbursementsTableSql);
  await db.execute(createTagJoinTableSql);
  await db.execute(createDefaultCategories);
  if (kDebugMode) {
    // await db.execute(createTestAccountsSql);
    // await db.execute(createTestTagsSql);
  }
}

Future<void> _upgrade14_15(Database db, int oldVersion, int newVersion) async {
  await db.execute("ALTER TABLE $tagsTable DROP COLUMN list_index;");
  await db.execute("ALTER TABLE $tagsTable ADD listIndex INTEGER NULL;");
  await db.execute("""
    WITH cte AS (
      SELECT 
        id, ROW_NUMBER() OVER(ORDER BY id) AS newIndex 
      FROM $tagsTable
    )
    UPDATE $tagsTable SET listIndex = cte.newIndex - 1
    FROM cte
    WHERE $tagsTable.id = cte.id
  """);
}

Future<void> _upgrade15_16(Database db) async {
  await db.execute(upgradeAccountsTableSql_15_16);
}
