import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart';

import 'dart:io' as io;

enum GoogleDriveSyncStatus {
  noAuthentication,
  localAhead,
  driveAhead,
  upToDate,
}

class OverwriteFileCallback {
  final FutureOr<bool> Function()? confirmOverwrite;
  final Function()? onReplaced;

  OverwriteFileCallback({
    required this.confirmOverwrite,
    required this.onReplaced,
  });
}

/// FYI can't use GoogleSignIn package, at least on Macs because it requires using an entitlement
/// that can only be used by code-signed apps.
class GoogleDrive extends ChangeNotifier {
  //-------------------------------------------------------------------------------------
  // Singleton setup
  //-------------------------------------------------------------------------------------
  GoogleDrive._internal();
  static final GoogleDrive _instance = GoogleDrive._internal();
  factory GoogleDrive() {
    return _instance;
  }

  //-------------------------------------------------------------------------------------
  static ClientId clientId = _desktopClientId;
  static AccessCredentials? credentials;
  static OverwriteFileCallback? overwriteFileCallback;

  static Client? _baseClient;
  static AutoRefreshingAuthClient? _httpClient;
  static DriveApi? _api;

  bool active = false;
  bool get isAuthorized => _httpClient != null;

  /// This is the last update time of the local database. It set by [LibraDatabase] everytime the
  /// database is accessed using [logLocalUpdate], and is used to debounce revision pushes when the
  /// user is actively doing things.
  static DateTime lastLocalUpdateTime = DateTime(1970);

  /// GoogleDrive file pointer to the latest database file on Google Drive. If null, assume one
  /// doesn't exist yet.
  /// TODO do we use this? because right now [sync] just resets it right away
  static File? driveFile;

  Future<void> init() async {
    /// Initialize local update time with local file OS last modified time
    final localPath = await LibraDatabase.getDatabasePath();
    if (!await LibraDatabase.isEmpty()) {
      lastLocalUpdateTime = await io.File(localPath).lastModified();
    }

    /// Load saved credentials
    if (credentials != null) {
      _baseClient ??= Client(); // this needs to be closed by us
      _httpClient = autoRefreshingClient(clientId, credentials!, _baseClient!);
      _httpClient!.credentialUpdates.listen(saveCredentials);
      _api = DriveApi(_httpClient!);
    }

    // TODO load this from persist
    active = false;

    sync();
  }

  void disable() {
    active = false;
    notifyListeners();
    // TODO save this to persist
  }

  void enable() {
    active = true;
    // TODO save this to persist
    sync();
  }

  GoogleDriveSyncStatus status() {
    if (_httpClient == null || !active) {
      return GoogleDriveSyncStatus.noAuthentication;
    } else if (driveFile == null ||
        driveFile!.modifiedTime == null ||
        lastLocalUpdateTime.isAfter(driveFile!.modifiedTime!)) {
      return GoogleDriveSyncStatus.localAhead;
    } else if (driveFile!.modifiedTime!
        .isAfter(lastLocalUpdateTime.add(const Duration(seconds: 30)))) {
      return GoogleDriveSyncStatus.driveAhead;
    } else {
      return GoogleDriveSyncStatus.upToDate;
    }
  }

  static Future<void> saveCredentials(AccessCredentials newCredentials) async {
    credentials = newCredentials;
    debugPrint("saveCredentials() ${credentials!.toJson()}");
    // TODO save this to persistent storage or something
  }

  Future<void> fetchDriveFile() async {
    if (_api == null) return;

    final newFile = await getMostRecentFile(_api!);
    if (driveFile?.modifiedTime != null &&
        newFile?.modifiedTime?.isBefore(driveFile!.modifiedTime!) == true) {
      debugPrint("WARNING GoogleDrive::sync() somehow cloud file (${newFile?.modifiedTime}) "
          "is older than in-memory pointer ${driveFile?.modifiedTime}");
    } else {
      driveFile = newFile;
    }

    debugPrint("GoogleDrive::fetchDriveFile()\n"
        "\tdrive:${driveFile?.id} @ ${driveFile?.modifiedTime}\n"
        "\tmemory:$lastLocalUpdateTime");
    notifyListeners();
  }

  /// WARNING! we have no way to check for divergent updates; the newer update will win and will
  /// replace the other, which may delete some changes if the history has diverged.
  Future<void> sync() async {
    try {
      await _sync();
    } catch (e) {
      debugPrint("LibraDatabase::update() caught $e");
      LibraDatabase.errorCallback?.call(e);
    }
  }

  Future<void> _sync() async {
    if (_api == null) return;
    await fetchDriveFile();

    final localPath = await LibraDatabase.getDatabasePath();
    switch (status()) {
      case GoogleDriveSyncStatus.localAhead:
        if (driveFile == null || driveFile!.id == null) {
          await createFile(_api!, localPath, "libra_sheet.db");
        } else {
          await updateFile(_api!, localPath, driveFile!.id!);
        }
        // the returned [File] objects from the above functions don't have
        // a lot of the metadata set (and the $fields parameter didn't seem to work the same as in
        // api.files.list), so just rerun the fetch.
        await fetchDriveFile();
      case GoogleDriveSyncStatus.driveAhead:
        // Replace local file with cloud file after user confirmation.
        if (await overwriteFileCallback?.confirmOverwrite?.call() ?? false) {
          final tempFile = await downloadFile(_api!, driveFile!.id!, "${localPath}_temp");
          lastLocalUpdateTime = driveFile!.modifiedTime!;
          await LibraDatabase.close();
          await tempFile.copy(localPath);
          tempFile.delete();
          await LibraDatabase.open();
          await overwriteFileCallback?.onReplaced?.call();
        }
      default:
    }

    notifyListeners();
  }

  Future<void> promptUserConsent() async {
    try {
      _httpClient =
          await clientViaUserConsent(_desktopClientId, [DriveApi.driveFileScope], _prompt);
      saveCredentials(_httpClient!.credentials);
      _httpClient!.credentialUpdates.listen(saveCredentials);
      _api = DriveApi(_httpClient!);

      // TODO save this to persistent
      active = true;

      await sync();
    } catch (e) {
      debugPrint("LibraDatabase::update() caught $e");
      LibraDatabase.errorCallback?.call(e);
    }
  }

  /// Calls [sync] but with a short delay to debounce back-to-back updates. This function uses
  /// [lastLocalUpdateTime] to check if the current call stack has been superceded.
  Future<void> logLocalUpdate() async {
    if (!active || !isAuthorized) return;

    final now = DateTime.now();
    lastLocalUpdateTime = now;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 10));
    if (lastLocalUpdateTime == now) {
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
Future<io.File> downloadFile(DriveApi api, String objectId, String filename) async {
  final media = await api.files.get(objectId, downloadOptions: DownloadOptions.fullMedia) as Media;
  final file = io.File(filename);
  final stream = file.openWrite();
  await stream.addStream(media.stream);
  stream.close();
  debugPrint("downloadFile() downloaded $objectId to $filename");
  return file;
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
