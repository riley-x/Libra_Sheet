import 'package:libra_sheet/data/database/database_setup.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/time_value.dart';

const String categoryHistoryTable = "`category_history`";

const String _accountKey = "`accountKey`";
const String _date = "`date`";
const String _value = "`value`";

const String createCategoryHistoryTableSql = "CREATE TABLE IF NOT EXISTS $categoryHistoryTable ("
    "$_accountKey INTEGER NOT NULL, "
    "`categoryKey` INTEGER NOT NULL, "
    "$_date INTEGER NOT NULL, "
    "$_value INTEGER NOT NULL, "
    "PRIMARY KEY($_accountKey, `categoryKey`, $_date))";

Future<List<TimeValue>> getNetWorth() async {
  final List<Map<String, dynamic>> maps = await libraDatabase!.query(
    categoryHistoryTable,
    columns: [_date, "SUM($_value) as $_value"],
    where: "$_value != 0",
    groupBy: _date,
    orderBy: _date,
  );

  return List.generate(
    maps.length,
    (i) => TimeValue(
      time: DateTime.fromMillisecondsSinceEpoch(maps[i][_date], isUtc: true),
      value: (maps[i][_value] as int).asDollarDouble(),
    ),
  );
}
