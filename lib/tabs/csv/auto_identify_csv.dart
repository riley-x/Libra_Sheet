import 'package:libra_sheet/tabs/csv/csv_field.dart';

List<CsvField>? autoIdentifyCsv(List<List<String>> lines, int nCols) {
  return _tryBofA(lines, nCols) ??
      _tryChaseCreditCard(lines, nCols) ??
      _tryBofACreditCard(lines, nCols) ??
      _tryCapitalOneCreditCard(lines, nCols) ??
      _tryVenmo(lines, nCols);
}

List<CsvField>? _tryBofA(List<List<String>> lines, int nCols) {
  if (nCols != 4) return null;
  if (lines.length < 7) return null;

  final headerLine = lines[6];
  if (headerLine.length < 4) return null;

  const header = ["Date", "Description", "Amount", "Running Bal."];
  for (int i = 0; i < header.length; i++) {
    if (headerLine[i] != header[i]) return null;
  }

  return [CsvDate(), CsvName(), CsvAmount(), CsvNone()];
}

List<CsvField>? _tryChaseCreditCard(List<List<String>> lines, int nCols) {
  if (nCols != 7) return null;
  if (lines.isEmpty) return null;

  final headerLine = lines[0];
  if (headerLine.length < 7) return null;

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
    if (headerLine[i] != header[i]) return null;
  }

  return [CsvDate(), CsvNone(), CsvName(), CsvNone(), CsvNone(), CsvAmount(), CsvNote()];
}

List<CsvField>? _tryBofACreditCard(List<List<String>> lines, int nCols) {
  if (nCols != 5) return null;
  if (lines.isEmpty) return null;

  final headerLine = lines[0];
  if (headerLine.length < 5) return null;

  const header = ["Posted Date", "Reference Number", "Payee", "Address", "Amount"];
  for (int i = 0; i < header.length; i++) {
    if (headerLine[i] != header[i]) return null;
  }

  return [CsvDate(), CsvNone(), CsvName(), CsvNone(), CsvAmount()];
}

List<CsvField>? _tryCapitalOneCreditCard(List<List<String>> lines, int nCols) {
  if (nCols != 7) return null;
  if (lines.isEmpty) return null;

  final headerLine = lines[0];
  if (headerLine.length < 7) return null;

  const header = [
    "Transaction Date",
    "Posted Date",
    "Card No.",
    "Description",
    "Category",
    "Debit",
    "Credit"
  ];
  for (int i = 0; i < header.length; i++) {
    if (headerLine[i] != header[i]) return null;
  }

  return [CsvDate(), CsvNone(), CsvNone(), CsvName(), CsvNone(), CsvNegAmount(), CsvAmount()];
}

List<CsvField>? _tryVenmo(List<List<String>> lines, int nCols) {
  if (nCols != 22) return null;
  if (lines.length < 3) return null;

  final headerLine = lines[2];
  if (headerLine.length < 22) return null;

  const header = [
    "",
    "ID",
    "Datetime",
    "Type",
    "Status",
    "Note",
    "From",
    "To",
    "Amount (total)",
    "Amount (tip)",
    "Amount (tax)",
    "Amount (fee)",
    "Tax Rate",
    "Tax Exempt",
    "Funding Source",
    "Destination",
    "Beginning Balance",
    "Ending Balance",
    "Statement Period Venmo Fees",
    "Terminal Location",
    "Year to Date Venmo Fees",
    "Disclaimer"
  ];
  for (int i = 0; i < header.length; i++) {
    if (headerLine[i] != header[i]) return null;
  }

  return [
    CsvNone(),
    CsvNone(),
    CsvDate(),
    CsvNone(),
    const CsvMatch('Complete'),
    CsvName(),
    CsvName(),
    CsvName(),
    CsvAmount(),
    CsvNone(),
    CsvNone(),
    CsvNone(),
    CsvNone(),
    CsvNone(),
    const CsvMatch('Venmo balance'),
    const CsvMatch('Venmo balance'),
    CsvNone(),
    CsvNone(),
    CsvNone(),
    CsvNone(),
    CsvNone(),
    CsvNone()
  ];
}
