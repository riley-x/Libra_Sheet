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
  AccountType type;
  String name;
  int balance;
  String description;
  DateTime? lastUpdated;
  Color color;

  int key;
  String csvFormat;

  Account({
    this.type = AccountType.bank,
    this.name = '',
    this.balance = 0,
    this.description = '',
    this.lastUpdated,
    required this.color,
    this.key = 0,
    this.csvFormat = '',
  });

  // Avoid copying! For each account there should only ever be a single instance.
  // Account copyWith(
  //     {AccountType? type,
  //     String? name,
  //     int? balance,
  //     String? description,
  //     DateTime? lastUpdated,
  //     Color? color,
  //     int? key,
  //     int? listIndex,
  //     String? csvFormat}) {
  //   return Account(
  //     type: type ?? this.type,
  //     name: name ?? this.name,
  //     balance: balance ?? this.balance,
  //     description: description ?? this.description,
  //     lastUpdated: lastUpdated ?? this.lastUpdated,
  //     color: color ?? this.color,
  //     key: key ?? this.key,
  //     csvFormat: csvFormat ?? this.csvFormat,
  //   );
  // }

  @override
  String toString() {
    return "Account($key: $name $type $color)";
  }
}
