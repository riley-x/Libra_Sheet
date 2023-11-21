import 'dart:ui';

class Tag {
  final int key;
  final String name;
  final Color? color;

  const Tag({
    this.key = 0,
    required this.name,
    this.color,
  });
}
