import 'dart:js_interop';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:web/web.dart';

void triggerFileDownload(Uint8List data, String fileName) {
  // Create a blob from the Uint8List
  final blob = Blob([data.toJS].toJS);

  // Create a URL for the blob
  final url = URL.createObjectURL(blob);

  // Create an anchor element and trigger download
  HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..click();

  // Clean up the URL
  URL.revokeObjectURL(url);
}

Future<XFile?> pickFile() async {
  const XTypeGroup typeGroup = XTypeGroup(
    label: 'SQLite Files',
    extensions: <String>['db', 'sqlite', 'sqlite3', 's3db'],
  );
  return await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
}
