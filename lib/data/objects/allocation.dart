import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/objects/category.dart';

class Allocation {
  int key;
  String name;
  Category? category;
  int value;
  DateTime? timestamp;

  Allocation({
    this.key = 0,
    required this.name,
    required this.category,
    required this.value,
    this.timestamp,
  });

  @override
  String toString() {
    return "Allocation($key, $name: $value ${category?.name})";
  }

  Allocation copy({int? key}) {
    return Allocation(
      key: key ?? this.key,
      name: name,
      category: category,
      value: value,
      timestamp: timestamp,
    );
  }

  int get signedValue => switch (category?.type) {
    ExpenseFilterType.income => value,
    ExpenseFilterType.expense => -value,
    _ => value,
  };
}
