import 'package:libra_sheet/data/category.dart';

class Allocation {
  final int key;
  final String name;
  final Category? category;
  final int value;

  const Allocation({
    this.key = 0,
    required this.name,
    required this.category,
    required this.value,
  });
}
