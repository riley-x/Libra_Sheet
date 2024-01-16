import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart';

import 'dart:io' as io;

const _gdriveCredentialsReleasePrefKey = 'gdrive_credentials';
const _gdriveCredentialsDebugPrefKey = 'gdrive_cred_debug';
const _gdriveSyncActivePrefKey = 'gdrive_sync_active';

const _gdriveCredentialsPrefKey =
    (kDebugMode) ? _gdriveCredentialsDebugPrefKey : _gdriveCredentialsReleasePrefKey;

// ignore: constant_identifier_names
const _driveFileProperty_lastModified = 'dbTime';

enum GoogleDriveSyncStatus {
  disabled,
  noConnection,
  localAhead,
  driveAhead,
  upToDate,
}

/// Specifies behavior when a drive file is ahead of the local file.
///
/// [confirmOverwrite] should return true if the overwrite should proceed. This is a useful time to
/// ask for user confirmation.
///
/// [onReplaced] is called after the database file has been replaced, and the database reopened.
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
  // Members
  //-------------------------------------------------------------------------------------
  ClientId clientId = _desktopClientId;
  AccessCredentials? credentials;

  /// When the drive file is ahead of the local file, this field determines the behavior. The
  /// [OverwriteFileCallback.confirmOverwrite] field is a useful place to ask for a user confirmation.
  /// Will default to false, so the local file will never be overwritten.
  OverwriteFileCallback? overwriteFileCallback;

  Client? _baseClient;
  AutoRefreshingAuthClient? _httpClient;
  DriveApi? _api;

  bool active = false;
  bool get isAuthorized => _httpClient != null;

  /// This is the last update time of the local database. It set by [LibraDatabase] everytime the
  /// database is accessed using [logLocalUpdate], and is used to debounce revision pushes when the
  /// user is actively doing things.
  DateTime lastLocalUpdateTime = DateTime.fromMillisecondsSinceEpoch(0);

  /// GoogleDrive file pointer to the latest database file on Google Drive. If null, assume one
  /// doesn't exist yet. This is set from [fetchDriveFile], and is used for both UI and determining
  /// the sync status.
  File? driveFile;
  DateTime? getDriveTime() {
    final time = driveFile?.appProperties?[_driveFileProperty_lastModified];
    if (time != null) return DateTime.tryParse(time);
    return null;
  }

  //-------------------------------------------------------------------------------------
  // Init and enable
  //-------------------------------------------------------------------------------------

  /// Initializes the service, loading credentials from persistent storage if needed. This should be
  /// called after [LibraDatabase.init].
  ///
  /// [overwriteFileCallback] should be set to confirm overwriting the local database file with one
  /// from the cloud.
  Future<void> init({required OverwriteFileCallback? overwriteFileCallback}) async {
    this.overwriteFileCallback = overwriteFileCallback;

    /// Initialize local update time with local file OS last modified time.
    /// Keep the default (1970) time when the database is empty (newly created) to always allow
    /// drive sync to override a new database file.
    final localPath = LibraDatabase.databasePath;
    if (!await LibraDatabase.isEmpty()) {
      lastLocalUpdateTime = await io.File(localPath).lastModified();
    }

    /// Load saved credentials
    final prefs = await SharedPreferences.getInstance();
    active = prefs.getBool(_gdriveSyncActivePrefKey) ?? false;

    final json = prefs.getString(_gdriveCredentialsPrefKey);
    if (json != null) {
      debugPrint('GoogleDrive::init() loaded credentials: $json');
      credentials = AccessCredentials.fromJson(jsonDecode(json));
      _baseClient ??= Client(); // this needs to be closed by us
      _httpClient = autoRefreshingClient(clientId, credentials!, _baseClient!);
      _httpClient!.credentialUpdates.listen(_saveCredentials);
      _api = DriveApi(_httpClient!);
    }
    sync();
  }

  Future<void> _saveActive(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_gdriveSyncActivePrefKey, value);
  }

  /// Cancel syncing. We don't remove the credentials so that we can easily re-enable syncing without
  /// going through the user consent flow again.
  void disable() {
    active = false;
    _saveActive(false);
    notifyListeners();
  }

  /// Enable or re-enable syncing. If an active authorized client exists, will continue using that.
  /// Otherwise prompts for user consent.
  Future<void> enable() async {
    active = true;
    _saveActive(true);
    if (_api == null) await promptUserConsent();
    notifyListeners(); // so UI is responsive before the async functions
    await sync();
  }

  //-------------------------------------------------------------------------------------
  // Status
  //-------------------------------------------------------------------------------------

  /// Compares the timestamps between the local state [lastLocalUpdateTime] and the cloud state
  /// [driveFile] via [getDriveTime].
  ///
  /// This does not refresh [driveFile], call [fetchDriveFile] if needed.
  GoogleDriveSyncStatus status() {
    final driveTime = getDriveTime();
    if (!active) {
      return GoogleDriveSyncStatus.disabled;
    } else if (_httpClient == null) {
      return GoogleDriveSyncStatus.noConnection;
    } else if (driveTime == null || lastLocalUpdateTime.isAfter(driveTime)) {
      return GoogleDriveSyncStatus.localAhead;
    } else if (driveTime.isAfter(lastLocalUpdateTime.add(const Duration(seconds: 30)))) {
      return GoogleDriveSyncStatus.driveAhead;
    } else {
      return GoogleDriveSyncStatus.upToDate;
    }
  }

  /// Queries GoogleDrive to retrieve the file metadata, setting [driveFile].
  Future<void> fetchDriveFile() async {
    if (_api == null) return;
    try {
      driveFile = await _getMostRecentFile(_api!);
      debugPrint("GoogleDrive::fetchDriveFile()\n"
          "\tdrive:${driveFile?.id} @ ${getDriveTime()?.toLocal()}\n"
          "\tlocal:${lastLocalUpdateTime.toLocal()}");
    } on ServerRequestFailedException catch (e) {
      debugPrint("GoogleDrive::fetchDriveFile() $e");
      driveFile = null;
      _httpClient = null;
      _api = null;
    }
    notifyListeners();
  }

  Future<void> retrieveLocalUpdateTime() async {
    if (!await LibraDatabase.isEmpty()) {
      final localPath = LibraDatabase.databasePath;
      lastLocalUpdateTime = await io.File(localPath).lastModified();
    } else {
      lastLocalUpdateTime = DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  //-------------------------------------------------------------------------------------
  // Authorization
  //-------------------------------------------------------------------------------------

  /// Launches the user consent prompt flow, retrieving an authorized [_httpClient].
  Future<void> promptUserConsent() async {
    try {
      _httpClient =
          await clientViaUserConsent(_desktopClientId, [DriveApi.driveFileScope], _prompt);
      _saveCredentials(_httpClient!.credentials);
      _httpClient!.credentialUpdates.listen(_saveCredentials);
      _api = DriveApi(_httpClient!);
    } catch (e) {
      debugPrint("GoogleDrive::promptUserConsent() caught $e");
      LibraDatabase.errorCallback?.call(e);
    }
  }

  /// We need to make sure new [AccessCredentials] are saved whenever they are generated by
  /// [AutoRefreshingAuthClient].
  Future<void> _saveCredentials(AccessCredentials newCredentials) async {
    credentials = newCredentials;
    debugPrint("_saveCredentials() ${credentials!.toJson()}");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gdriveCredentialsPrefKey, jsonEncode(credentials!.toJson()));
  }

  //-------------------------------------------------------------------------------------
  // Sync
  //-------------------------------------------------------------------------------------

  /// This function uploads the local database file or downloads the cloud file when either
  /// is ahead. Will call [fetchDriveFile] to get the most up-to-date file pointer.
  ///
  /// WARNING! we have no way to check for divergent updates; the newer update will win and will
  /// replace the other, which may delete some changes if the history has diverged.
  Future<void> sync() async {
    // await fetchDriveFile();
    // return;
    try {
      await _sync();
    } catch (e) {
      debugPrint("LibraDatabase::sync() caught $e");
      LibraDatabase.errorCallback?.call(e);
    }
  }

  Future<void> _sync() async {
    if (_api == null) return;

    /// Refresh both the drive and local times. This is important to overwrite the in-memory
    /// placeholder time set by [logLocalUpdate].
    await retrieveLocalUpdateTime();
    await fetchDriveFile();

    /// Case on the status
    final localPath = LibraDatabase.databasePath;
    switch (status()) {
      case GoogleDriveSyncStatus.localAhead:
        if (driveFile == null || driveFile!.id == null) {
          await createFile(_api!, localPath, "libra_sheet.db");
        } else {
          await updateFile(_api!, localPath, driveFile!.id!);
        }
        // the returned [File] objects from the above functions don't have a lot of the metadata set
        // (and the $fields parameter didn't seem to work the same as in api.files.list), so just
        // rerun the fetch.
        await fetchDriveFile();
      case GoogleDriveSyncStatus.driveAhead:
        // Replace local file with cloud file after user confirmation.
        if (await overwriteFileCallback?.confirmOverwrite?.call() ?? false) {
          final tempFile = await downloadFile(_api!, driveFile!.id!, "${localPath}_temp");

          /// Note that the downloaded file's last modified time will be ahead of the drive time and
          /// what is set here. The only problem this causes is that on the next app load, we will
          /// think that drive is behind and reupload (which serves to update the drive time to again
          /// match the local file's last modified time).
          lastLocalUpdateTime = getDriveTime() ?? DateTime.now();

          await LibraDatabase.close();
          await LibraDatabase.backup(tag: 'before_replace_from_cloud');
          await tempFile.copy(localPath);
          tempFile.delete(); // no await needed
          await LibraDatabase.open();
          await overwriteFileCallback?.onReplaced?.call();
        }
      default:
        return;
    }
    notifyListeners();
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
  final modifiedTime = await localFile.lastModified();
  final media = Media(localFile.openRead(), localFile.lengthSync());
  final driveFile = File()
    ..name = name
    ..appProperties = {_driveFileProperty_lastModified: modifiedTime.toUtc().toString()};
  final out = await api.files.create(driveFile, uploadMedia: media);
  debugPrint('createFile() uploaded $localPath to id: ${out.id}');
  return out;
}

/// Updates the drive file with id [objectId], replacing the content with the file at [localPath].
///
/// https://pub.dev/documentation/googleapis/12.0.0/drive_v3/FilesResource/update.html
/// https://developers.google.com/drive/api/reference/rest/v3/files/update
Future<File> updateFile(DriveApi api, String localPath, String objectId) async {
  final localFile = io.File(localPath);
  final modifiedTime = await localFile.lastModified();
  final media = Media(localFile.openRead(), localFile.lengthSync());
  final driveFile = File()
    ..appProperties = {_driveFileProperty_lastModified: modifiedTime.toUtc().toString()};
  final out = await api.files.update(driveFile, objectId, uploadMedia: media);
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

DateTime? _getAppPropertyTime(File file) {
  final time = file.appProperties?[_driveFileProperty_lastModified];
  if (time != null) return DateTime.tryParse(time);
  return null;
}

/// Returns a drive file pointer for the most recent file on the drive using the saved appProperty
/// [_driveFileProperty_lastModified]. Since we use the DriveApi.driveFileScope scope, this only
/// lists the files that are created by Libra Sheet.
///
/// See also:
/// https://developers.google.com/drive/api/guides/search-files
/// https://pub.dev/documentation/googleapis/12.0.0/drive_v3/FilesResource/list.html
Future<File?> _getMostRecentFile(DriveApi api) async {
  final response = await api.files.list(
    q: "trashed = false",
    $fields: "files(id, name, size, modifiedTime, webViewLink, appProperties)",
  );
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
  DateTime? mostRecentTime;

  if (response.files != null) {
    for (final file in response.files!) {
      final time = _getAppPropertyTime(file);
      debugPrint('GoogleDrive::getMostRecentFile()\n'
          '\t${file.id} @ ${file.modifiedTime}\n'
          '\t${file.appProperties}');
      if (mostRecentFile == null) {
        mostRecentFile = file;
        mostRecentTime = time;
      } else if (mostRecentTime != null && time != null && mostRecentTime.isBefore(time)) {
        mostRecentFile = file;
        mostRecentTime = time;
      }
    }
  }
  return mostRecentFile;
}
