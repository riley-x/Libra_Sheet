import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/objects/tag.dart';

class TransactionFilters {
  String? name;
  int? minValue;
  int? maxValue;
  DateTime? startTime;
  DateTime? endTime;
  Set<Account> accounts;
  CategoryTristateMap categories;
  Set<Tag> tags;
  int? limit;

  TransactionFilters({
    this.name,
    this.minValue,
    this.maxValue,
    this.startTime,
    this.endTime,
    Set<Account>? accounts,
    Set<Tag>? tags,
    CategoryTristateMap? categories,
    this.limit = 300,
  })  : accounts = accounts ?? {},
        tags = tags ?? {},
        categories = categories ?? CategoryTristateMap();

  TransactionFilters copy() {
    return TransactionFilters(
      name: name,
      minValue: minValue,
      maxValue: maxValue,
      startTime: startTime,
      endTime: endTime,
      accounts: Set.from(accounts),
      categories: categories.copy(),
      limit: limit,
    );
  }
}
