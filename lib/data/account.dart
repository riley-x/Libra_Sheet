class Account {
  const Account(
      {required this.name,
      this.balance = 0,
      required this.number,
      this.lastUpdated});

  final String name;
  final int balance;
  final String number;
  final DateTime? lastUpdated;
}
