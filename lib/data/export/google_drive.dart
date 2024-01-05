import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart';

import 'dart:io' as io;

final _desktopClientId = ClientId(
  "84362049176-bvmte8gqbds7jethkd25bfehnhc3vdj8.apps.googleusercontent.com",
  "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",
);

/// Can't use google sign in on Macs because it requires using an entitlement that can only be used
/// by code-signed apps.
// final _googleSignIn = GoogleSignIn(
//   scopes: [DriveApi.driveAppdataScope],
// );

AutoRefreshingAuthClient? httpClient;

// Upload a file to Google Drive.
Future uploadFile(DriveApi api, String file, String name) async {
  // We create a `Media` object with a `Stream` of bytes and the length of the
  // file. This media object is passed to the API call via `uploadMedia`.
  // We pass a partially filled-in `drive.File` object with the title we want
  // to give our newly created file.
  final localFile = io.File(file);
  final media = Media(localFile.openRead(), localFile.lengthSync());
  final driveFile = File()..name = name;
  final out = await api.files.create(driveFile, uploadMedia: media);
  print('Uploaded $file. Id: ${out.id}');
}

// Download a file from Google Drive.
Future downloadFile(DriveApi api, AuthClient client, String objectId, String filename) async {
  debugPrint("downloadFile() $objectId => $filename");
  final file = await api.files.get(objectId, downloadOptions: DownloadOptions.fullMedia) as Media;
  final stream = io.File(filename).openWrite();
  await stream.addStream(file.stream);
  stream.close();
}

Future<void> handleSignIn() async {
  httpClient ??= await clientViaUserConsent(
    _desktopClientId,
    // [DriveApi.driveAppdataScope],
    [DriveApi.driveFileScope],
    prompt,
  );
  try {
    final api = DriveApi(httpClient!);
    // uploadFile(api, LibraDatabase.db.path, "libra_sheet.db");
    downloadFile(api, httpClient!, "1kEHztKG5Ex6cWb-7mT1B42Qx5lKFs-ZS",
        "/Users/riley/Downloads/libra_sheet_download.db");
  } catch (e) {
    debugPrint("Caught exception: $e");
  } finally {
    // httpClient!.close();
  }
}

Future<void> prompt(String url) async {
  debugPrint("prompt() $url");
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    throw 'Could not launch $url';
  }
}
