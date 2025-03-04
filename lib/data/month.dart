class Month {
  final int year;

  /// [1..12]
  final int index;

  Month({required this.year, required this.index});

  @override
  bool operator ==(Object other) => other is Month && year == other.year && index == other.index;

  @override
  int get hashCode => Object.hash(year, index);

  @override
  String toString() => "$year-$index";
}
