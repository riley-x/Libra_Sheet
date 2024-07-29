import 'package:flutter/material.dart';

enum AccountType {
  cash("Cash"),
  bank("Bank"),
  investment("Investment"),
  liability("Liability");

  const AccountType(this.label);

  final String label;

  @override
  String toString() {
    return label;
  }

  static AccountType fromString(String text) {
    for (final t in AccountType.values) {
      if (t.label == text) return t;
    }
    return AccountType.cash;
  }
}

class Account {
  int key;
  AccountType type;
  String name;
  String description;
  Color color;
  String csvFormat;

  /// This field stores the last time that a user manually marks an account as up-to-date. We also
  /// fetch the latest transaction date, and set [lastUpdated] to the max of these two.
  DateTime? lastUserUpdate;

  /// Calculated fields
  DateTime? lastUpdated;
  int balance;

  Account({
    this.type = AccountType.bank,
    this.name = '',
    this.balance = 0,
    this.description = '',
    this.lastUserUpdate,
    this.lastUpdated,
    required this.color,
    this.key = 0,
    this.csvFormat = '',
  });

  @override
  String toString() {
    return "Account($key: $name)";
  }

  String dump() {
    return "Account($key: $name $description $type\n"
        "\t$color $csvFormat\n"
        "\t$lastUpdated $balance)";
  }
}
