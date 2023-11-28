import 'package:libra_sheet/data/objects/category.dart';

class Allocation {
  int key;
  String name;
  Category? category;
  int value;

  Allocation({
    this.key = 0,
    required this.name,
    required this.category,
    required this.value,
  });

  @override
  String toString() {
    return "Allocation($key, $name: $value ${category?.name})";
  }
}

class MutableAllocation implements Allocation {
  @override
  int key;

  @override
  String name;

  @override
  Category? category;

  @override
  int value;

  MutableAllocation({
    this.key = 0,
    this.name = '',
    this.category,
    this.value = 0,
  });

  @override
  String toString() {
    return "MAllocation($key, $name, $value, ${category?.name})";
  }

  Allocation freeze([int? key]) {
    return Allocation(key: key ?? this.key, name: name, category: category, value: value);
  }
}
