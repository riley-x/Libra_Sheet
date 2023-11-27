enum ExpenseType { income, expense }

enum ExpenseFilterType { income, expense, all }

ExpenseFilterType toFilterType(ExpenseType? e) {
  switch (e) {
    case null:
      return ExpenseFilterType.all;
    case ExpenseType.income:
      return ExpenseFilterType.income;
    case ExpenseType.expense:
      return ExpenseFilterType.expense;
  }
}
