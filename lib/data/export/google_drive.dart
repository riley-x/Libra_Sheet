import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dart:io' as io;

/// FYI can't use GoogleSignIn package, at least on Macs because it requires using an entitlement
/// that can only be used by code-signed apps.
class GoogleDrive {
  static ClientId clientId = _desktopClientId;
  static AutoRefreshingAuthClient? httpClient;

  /// This is the last update time of the local database. It set by [LibraDatabase] everytime the
  /// database is accessed using [logLocalUpdate], and is used to debounce revision pushes when the
  /// user is actively doing things.
  static DateTime? lastLocalUpdateTime;

  /// This uploads a local [file] to Google Drive with a new [name]. Note that this function will
  /// not replace any older file, since Google Drive doesn't use [name] as an identifier. It will
  /// just create a new file with a new id.
  static Future<File> uploadFile(DriveApi api, String file, String name) async {
    final localFile = io.File(file);
    final media = Media(localFile.openRead(), localFile.lengthSync());
    final driveFile = File()..name = name;
    final out = await api.files.create(driveFile, uploadMedia: media);
    debugPrint('uploadFile() uploaded $file to id: ${out.id}');
    return out;
  }

  /// This will replace the local file at [filename] with the downloaded file. Pass the Google Drive
  /// [objectId] to identify the file.
  static Future<void> downloadFile(DriveApi api, String objectId, String filename) async {
    debugPrint("downloadFile() $objectId => $filename");
    final file = await api.files.get(objectId, downloadOptions: DownloadOptions.fullMedia) as Media;
    final stream = io.File(filename).openWrite();
    await stream.addStream(file.stream);
    stream.close();
  }

  /// Returns a drive file pointer for the most recent database file on the drive.
  static Future<File?> getDriveFile(DriveApi api) async {
    /// Since we use the DriveApi.driveFileScope scope, this only lists the files that are created by
    /// Libra Sheet.
    ///
    /// See also:
    /// https://developers.google.com/drive/api/guides/search-files
    /// https://pub.dev/documentation/googleapis/12.0.0/drive_v3/FilesResource/list.html
    final response = await api.files.list($fields: "files(id, name, size, modifiedTime)");
    if (response.files == null || response.files!.isEmpty) return null;

    /// Assume we don't need to do any paging, because we should only ever have one file on drive.
    if (response.nextPageToken != null) {
      debugPrint("WARNING listFiles() non-null next page token");
    }
    if (response.files!.length != 1) {
      debugPrint("WARNING listFiles() more than one drive file; will use first");
    }

    /// But we still do the loop formally
    File? mostRecentFile;
    if (response.files != null) {
      for (final file in response.files!) {
        if (mostRecentFile == null) {
          mostRecentFile = file;
        } else if (file.modifiedTime != null &&
            mostRecentFile.modifiedTime != null &&
            mostRecentFile.modifiedTime!.isBefore(file.modifiedTime!)) {
          mostRecentFile = file;
        }
      }
    }
    return mostRecentFile;
  }

  static Future<void> handleSignIn() async {
    try {
      httpClient ??=
          await clientViaUserConsent(_desktopClientId, [DriveApi.driveFileScope], _prompt);

      final api = DriveApi(httpClient!);
      // uploadFile(api, LibraDatabase.db.path, "libra_sheet.db");
      // downloadFile(api, "1kEHztKG5Ex6cWb-7mT1B42Qx5lKFs-ZS",
      //     "/Users/riley/Downloads/libra_sheet_download.db");
      // final cloudFile = getDriveFile(api);
      // if (cloudFile != null)
    } catch (e) {
      debugPrint("Caught exception: $e");
    } finally {
      // actually keep this alive
      // httpClient!.close();
    }
  }

  static void logLocalUpdate() async {
    final now = DateTime.now();
    lastLocalUpdateTime = now;
    await Future.delayed(const Duration(seconds: 20));
    if (lastLocalUpdateTime == now) {
      print('hi!!!');
      // uploadFile(api, file, name);
    } else {
      print('cancelled!');
    }
  }
}

// https://github.com/dart-archive/googleapis_examples/blob/master/drive_upload_download_console/bin/main.dart
final _desktopClientId = ClientId(
  "84362049176-bvmte8gqbds7jethkd25bfehnhc3vdj8.apps.googleusercontent.com",
  "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",
);

/// Prompt callback to open the OAuth2 authentication portal. Here, we just launch the supplied URL.
Future<void> _prompt(String url) async {
  debugPrint("_prompt() $url");
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    throw StateError('Could not launch $url');
  }
}
