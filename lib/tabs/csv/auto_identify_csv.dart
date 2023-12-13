import 'package:libra_sheet/tabs/csv/csv_field.dart';

List<CsvField>? autoIdentifyCsv(List<List<String>> lines, int nCols) {
  return _tryBofA(lines, nCols) ?? _tryChaseCreditCard(lines, nCols);
}

List<CsvField>? _tryBofA(List<List<String>> lines, int nCols) {
  if (nCols != 4) return null;
  if (lines.length < 7) return null;
  if (lines[6].length < 4) return null;
  if (lines[6][0] != "Date") return null;
  if (lines[6][1] != "Description") return null;
  if (lines[6][2] != "Amount") return null;
  if (lines[6][3] != "Running Bal.") return null;

  return [CsvDate(), CsvName(), CsvAmount(), CsvNone()];
}

List<CsvField>? _tryChaseCreditCard(List<List<String>> lines, int nCols) {
  if (nCols != 7) return null;
  if (lines.isEmpty) return null;
  if (lines[0].length < 7) return null;

  const header = [
    "Transaction Date",
    "Post Date",
    "Description",
    "Category",
    "Type",
    "Amount",
    "Memo"
  ];
  for (int i = 0; i < header.length; i++) {
    if (lines[0][i] != header[i]) return null;
  }

  return [CsvDate(), CsvNone(), CsvName(), CsvNone(), CsvNone(), CsvAmount(), CsvNote()];
}
