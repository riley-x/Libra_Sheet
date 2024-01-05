import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart';

import 'dart:io' as io;

/// FYI can't use GoogleSignIn package, at least on Macs because it requires using an entitlement
/// that can only be used by code-signed apps.
class GoogleDrive {
  static ClientId clientId = _desktopClientId;
  static AccessCredentials? credentials;
  static Future<bool> Function()? userConfirmOverwrite;

  static Client? _baseClient;
  static AutoRefreshingAuthClient? _httpClient;
  static DriveApi? _api;

  static Future<void> init() async {
    if (credentials != null) {
      _baseClient ??= Client(); // this needs to be closed by us
      _httpClient = autoRefreshingClient(clientId, credentials!, _baseClient!);
      _httpClient!.credentialUpdates.listen(saveCredentials);
      _api = DriveApi(_httpClient!);
    }
  }

  static Future<void> saveCredentials(AccessCredentials newCredentials) async {
    credentials = newCredentials;
    debugPrint("saveCredentials() ${credentials!.toJson()}");
    // TODO
  }

  static Future<void> promptUserConsent() async {
    _httpClient = await clientViaUserConsent(_desktopClientId, [DriveApi.driveFileScope], _prompt);
    saveCredentials(_httpClient!.credentials);
    _httpClient!.credentialUpdates.listen(saveCredentials);
    _api = DriveApi(_httpClient!);
  }

  /// This is the last update time of the local database. It set by [LibraDatabase] everytime the
  /// database is accessed using [logLocalUpdate], and is used to debounce revision pushes when the
  /// user is actively doing things.
  static DateTime? lastLocalUpdateTime;

  /// GoogleDrive file pointer to the latest database file on Google Drive. If null, assume one
  /// doesn't exist yet.
  /// TODO do we use this? because right now [sync] just resets it right away
  static File? driveFile;

  /// WARNING! we have no way to check for divergent updates; the newer update will win and will
  /// replace the other, which may delete some changes if the history has diverged.
  static Future<void> sync() async {
    if (_api == null) return;

    /// Check the cloud for any update
    final newFile = await getMostRecentFile(_api!);
    if (driveFile?.modifiedTime != null &&
        newFile?.modifiedTime?.isBefore(driveFile!.modifiedTime!) == true) {
      debugPrint("WARNING GoogleDrive::sync() somehow cloud file (${newFile?.modifiedTime}) "
          "is older than in-memory pointer ${driveFile?.modifiedTime}");
    } else {
      driveFile = newFile;
    }

    /// Initialize local update time with local file OS last modified time
    final localPath = await LibraDatabase.getDatabasePath();
    lastLocalUpdateTime ??= await io.File(localPath).lastModified();
    debugPrint("GoogleDrive::sync()\n"
        "\tdrive:${driveFile?.id} @ ${driveFile?.modifiedTime}\n"
        "\tmemory:$lastLocalUpdateTime");

    /// Drive file doesn't exist, upload current database
    if (driveFile == null || driveFile!.id == null) {
      driveFile = await createFile(_api!, localPath, "libra_sheet.db");
    }

    /// Replace local file with cloud file after user confirmation.
    else if (driveFile!.modifiedTime?.isAfter(lastLocalUpdateTime!) == true) {
      if (await userConfirmOverwrite?.call() ?? false) {
        await downloadFile(_api!, driveFile!.id!, localPath);
      }
    }

    /// In all other cases, mostly when the drive file is behind the local file but also if for
    /// some reason [driveFile.modifiedTime] is null, replace the drive file with the local file.
    else {
      driveFile = await updateFile(_api!, localPath, driveFile!.id!);
    }
  }

  static Future<void> initializeSyncOnUserInput() async {
    await promptUserConsent();
    LibraDatabase.syncGoogleDrive = true;
    // TODO save this to persistent storage or something
    debugPrint("initializeSyncOnUserInput() ${_httpClient?.credentials.toJson()}");
  }

  /// Calls [sync] but with a short delay to debounce back-to-back updates. This function uses
  /// [lastLocalUpdateTime] to check if the current call stack has been superceded.
  static void logLocalUpdate() async {
    final now = DateTime.now();
    lastLocalUpdateTime = now;
    await Future.delayed(const Duration(seconds: 10));
    if (lastLocalUpdateTime == now) {
      lastLocalUpdateTime = null;
      await sync();
    } else {
      // superceded, do nothing
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

/// This uploads a local [localPath] to Google Drive with a new [name]. Note that this function will
/// not replace any older file, since Google Drive doesn't use [name] as an identifier. It will
/// just create a new file with a new id.
Future<File> createFile(DriveApi api, String localPath, String name) async {
  final localFile = io.File(localPath);
  final media = Media(localFile.openRead(), localFile.lengthSync());
  final driveFile = File()..name = name;
  final now = DateTime.now();
  final out = await api.files.create(driveFile, uploadMedia: media);
  out.modifiedTime = now;
  debugPrint('createFile() uploaded $localPath to id: ${out.id}');
  return out;
}

/// Updates the drive file with id [objectId], replacing the content with the file at [localPath].
///
/// https://pub.dev/documentation/googleapis/12.0.0/drive_v3/FilesResource/update.html
/// https://developers.google.com/drive/api/reference/rest/v3/files/update
Future<File> updateFile(DriveApi api, String localPath, String objectId) async {
  final localFile = io.File(localPath);
  final media = Media(localFile.openRead(), localFile.lengthSync());
  final driveFile = File();
  final now = DateTime.now();
  final out = await api.files.update(driveFile, objectId, uploadMedia: media);
  out.modifiedTime = now;
  debugPrint('updateFile() uploaded $localPath to id: ${out.id}');
  return out;
}

/// This will replace the local file at [filename] with the downloaded file. Pass the Google Drive
/// [objectId] to identify the file.
Future<void> downloadFile(DriveApi api, String objectId, String filename) async {
  final file = await api.files.get(objectId, downloadOptions: DownloadOptions.fullMedia) as Media;
  final stream = io.File(filename).openWrite();
  await stream.addStream(file.stream);
  stream.close();
  debugPrint("downloadFile() downloaded $objectId to $filename");
}

/// Returns a drive file pointer for the most recent file on the drive. Since we use the
/// DriveApi.driveFileScope scope, this only lists the files that are created by Libra Sheet.
///
/// See also:
/// https://developers.google.com/drive/api/guides/search-files
/// https://pub.dev/documentation/googleapis/12.0.0/drive_v3/FilesResource/list.html
Future<File?> getMostRecentFile(DriveApi api) async {
  final response = await api.files.list($fields: "files(id, name, size, modifiedTime)");
  if (response.files == null || response.files!.isEmpty) return null;

  /// Assume we don't need to do any paging, because we should only ever have one file on drive.
  if (response.nextPageToken != null) {
    debugPrint("WARNING listFiles() non-null next page token");
  }
  if (response.files!.length != 1) {
    debugPrint("WARNING listFiles() more than one drive file");
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
