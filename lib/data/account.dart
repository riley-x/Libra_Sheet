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
}

class Account {
  final AccountType type;
  final String name;
  final int balance;
  final int listIndex;
  final String description;
  final DateTime? lastUpdated;
  final Color? color;

  final int key;
  final String csvFormat;

  const Account({
    this.type = AccountType.bank,
    this.name = '',
    this.balance = 0,
    this.description = '',
    this.lastUpdated,
    this.color,
    this.key = 0,
    this.listIndex = -1,
    this.csvFormat = '',
  });

  Account copyWith(
      {AccountType? type,
      String? name,
      int? balance,
      String? description,
      DateTime? lastUpdated,
      Color? color,
      int? key,
      int? listIndex,
      String? csvFormat}) {
    return Account(
      type: type ?? this.type,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      description: description ?? this.description,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      color: color ?? this.color,
      key: key ?? this.key,
      listIndex: listIndex ?? this.listIndex,
      csvFormat: csvFormat ?? this.csvFormat,
    );
  }

  @override
  String toString() {
    return "Account($key: $name $type $color)";
  }

  Map<String, dynamic> toMap() {
    final out = {
      'name': name,
      'description': description,
      'type': type.label,
      'csvPattern': csvFormat,
      'colorLong': color?.value ?? 0,
      'listIndex': listIndex,
      'balance': balance,
    };

    /// For auto-incrementing keys, make sure they are NOT in the map supplied to sqflite.
    if (key != 0) {
      out['key'] = key;
    }
    return out;
  }
}

class MutableAccount {
  MutableAccount({
    this.type = AccountType.bank,
    this.name = '',
    this.balance = 0,
    this.description = '',
    this.lastUpdated,
    this.color,
    this.key = 0,
    this.listIndex = -1,
    this.csvFormat = '',
  });

  MutableAccount.copy(Account other)
      : type = other.type,
        name = other.name,
        balance = other.balance,
        description = other.description,
        lastUpdated = other.lastUpdated,
        color = other.color,
        key = other.key,
        listIndex = other.listIndex,
        csvFormat = other.csvFormat;

  AccountType type;
  String name;
  int balance;
  String description;
  DateTime? lastUpdated;
  Color? color;
  int key;
  int listIndex;
  String csvFormat;

  @override
  String toString() {
    return "MAccount($key: $name $type $color)";
  }

  Account freeze() {
    return Account(
      type: type,
      name: name,
      balance: balance,
      description: description,
      lastUpdated: lastUpdated,
      color: color,
      key: key,
      listIndex: listIndex,
      csvFormat: csvFormat,
    );
  }
}
