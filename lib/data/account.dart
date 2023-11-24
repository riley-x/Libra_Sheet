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

  final AccountType type;
  final String name;
  final int balance;
  final int listIndex;
  final String description;
  final DateTime? lastUpdated;
  final Color? color;

  final int key;
  final String csvFormat;

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
    if (key != 0) {
      out['key'] = key;
    }
    return out;
  }
}

class MutableAccount implements Account {
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

  @override
  AccountType type;
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
  int listIndex;
  @override
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

  @override
  Map<String, dynamic> toMap() {
    return freeze().toMap();
  }
}
