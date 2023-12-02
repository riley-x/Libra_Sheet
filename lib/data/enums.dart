enum ExpenseType {
  income,
  expense;

  factory ExpenseType.from(int value) {
    if (value > 0) {
      return ExpenseType.income;
    } else {
      return ExpenseType.expense;
    }
  }

  ExpenseFilterType toFilterType() {
    if (this == ExpenseType.income) {
      return ExpenseFilterType.income;
    } else {
      return ExpenseFilterType.expense;
    }
  }
}

enum ExpenseFilterType {
  income,
  expense,
  all;

  bool inclusiveEqual(ExpenseFilterType other) {
    if (other == ExpenseFilterType.all || this == ExpenseFilterType.all) return true;
    return other == this;
  }

  bool inclusiveOpposite(ExpenseFilterType other) {
    if (other == ExpenseFilterType.all || this == ExpenseFilterType.all) return true;
    return other != this;
  }
}

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

bool sameType(ExpenseFilterType t1, ExpenseType t2) {
  if (t1 == ExpenseFilterType.income && t2 == ExpenseType.income) return true;
  if (t1 == ExpenseFilterType.expense && t2 == ExpenseType.expense) return true;
  return false;
}

bool inclusive(ExpenseType t1, ExpenseFilterType t2) {
  if (t2 == ExpenseFilterType.all) return true;
  if (t2 == ExpenseFilterType.income && t1 == ExpenseType.income) return true;
  if (t2 == ExpenseFilterType.expense && t1 == ExpenseType.expense) return true;
  return false;
}

bool oppositeType(ExpenseFilterType t1, ExpenseType t2) {
  if (t1 == ExpenseFilterType.income && t2 == ExpenseType.expense) return true;
  if (t1 == ExpenseFilterType.expense && t2 == ExpenseType.income) return true;
  return false;
}
