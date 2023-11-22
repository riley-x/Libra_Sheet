import 'package:flutter/material.dart';

class Account {
  const Account({
    required this.name,
    this.balance = 0,
    required this.number,
    this.lastUpdated,
    this.color,
    this.key = -1,
    this.csvFormat = "",
  });

  final String name;
  final int balance;
  final String number;
  final DateTime? lastUpdated;
  final Color? color;

  final int key;
  final String csvFormat;

  @override
  String toString() {
    return "Account($key: $name)";
  }
}
