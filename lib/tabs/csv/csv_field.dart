sealed class CsvField {
  abstract final String title;
  abstract final String saveName;
  abstract final String baseName;

  const CsvField();

  factory CsvField.fromName(String? name) {
    if (name == null) return CsvNone();
    switch (name) {
      case CsvDate.name:
        return CsvDate();
      case CsvName.name:
        return CsvName();
      case CsvAmount.name:
        return CsvAmount();
      case CsvNote.name:
        return CsvNote();
      case CsvNone.name:
        return CsvNone();
      case CsvDebit.name:
        return CsvDebit();
    }
    if (name.startsWith(CsvMatch.name)) {
      return CsvMatch(name.substring(CsvMatch.name.length));
    }
    return CsvNone();
  }

  static final List<String> fieldBaseNames = [
    CsvName.name,
    CsvDate.name,
    CsvAmount.name,
    CsvNote.name,
    CsvMatch.name,
    CsvDebit.name,
    CsvNone.name,
  ];
}

class CsvDate extends CsvField {
  static const String name = "date";
  @override
  String get baseName => name;
  @override
  String get saveName => name;
  @override
  String get title => "Date";
}

class CsvName extends CsvField {
  static const String name = "name";
  @override
  String get baseName => name;
  @override
  String get saveName => name;
  @override
  String get title => "Name";
}

class CsvAmount extends CsvField {
  static const String name = "value";
  @override
  String get baseName => name;
  @override
  String get saveName => name;
  @override
  String get title => "Amount";
}

class CsvNote extends CsvField {
  static const String name = "note";
  @override
  String get baseName => name;
  @override
  String get saveName => name;
  @override
  String get title => "Note";
}

class CsvNone extends CsvField {
  static const String name = "none";
  @override
  String get baseName => name;
  @override
  String get saveName => name;
  @override
  String get title => "None";
}

class CsvDebit extends CsvField {
  static const String name = "debit";
  @override
  String get baseName => name;
  @override
  String get saveName => name;
  @override
  String get title => "Debit/Credit";
}

class CsvMatch extends CsvField {
  static const String name = "match";
  @override
  String get baseName => name;
  @override
  String get saveName => "$name$match";
  @override
  String get title {
    if (match.isEmpty) return "Match";
    return "Match: $match";
  }

  final String match;
  const CsvMatch(this.match);
}
