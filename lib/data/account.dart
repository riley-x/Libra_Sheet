import 'package:flutter/material.dart';

class Account {
  const Account({
    required this.name,
    this.balance = 0,
    required this.description,
    this.lastUpdated,
    this.color,
    this.key = -1,
    this.csvFormat = "",
  });

  final String name;
  final int balance;
  final String description;
  final DateTime? lastUpdated;
  final Color? color;

  final int key;
  final String csvFormat;

  @override
  String toString() {
    return "Account($key: $name)";
  }
}

class MutableAccount implements Account {
  MutableAccount({
    this.name = '',
    this.balance = 0,
    this.description = '',
    this.lastUpdated,
    this.color,
    this.key = -1,
    this.csvFormat = '',
  });

  @override
  String name;
  @override
  int balance;
  @override
  String description;
  @override
  DateTime? lastUpdated;
  @override
  Color? color;
  @override
  int key;
  @override
  String csvFormat;

  @override
  String toString() {
    return "MAccount($key: $name)";
  }
}
