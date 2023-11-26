import 'package:flutter/material.dart';

class Tag {
  final int key;
  String name;
  Color color;

  Tag({
    this.key = 0,
    required this.name,
    required this.color,
  });

  static final empty = Tag(name: '', color: Colors.transparent);
}
