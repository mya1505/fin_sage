import 'dart:convert';
import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

class GoogleDriveDataSource {
  GoogleDriveDataSource(this._googleSignIn, {this.allowInteractiveSignIn = true});

  final GoogleSignIn _googleSignIn;
  final bool allowInteractiveSignIn;

  Future<drive.DriveApi> _driveApi() async {
    final silentAccount = await _googleSignIn.signInSilently();
    final account = silentAccount ?? (allowInteractiveSignIn ? await _googleSignIn.signIn() : null);
    final headers = await account?.authHeaders;
    if (headers == null) {
      throw StateError('Google auth headers unavailable');
    }

    final client = _GoogleAuthClient(headers);
    return drive.DriveApi(client);
  }

  Future<void> uploadBackup(List<int> bytes, String filename) async {
    final api = await _driveApi();
    final media = drive.Media(Stream<List<int>>.fromIterable([bytes]), bytes.length);
    final file = drive.File()
      ..name = filename
      ..mimeType = 'application/octet-stream'
      ..parents = ['appDataFolder'];

    await api.files.create(file, uploadMedia: media);
  }

  Future<void> uploadBackupChecksum(String filename, String checksum) async {
    final api = await _driveApi();
    final payload = utf8.encode('$checksum\n');
    final media = drive.Media(Stream<List<int>>.fromIterable([payload]), payload.length);
    final file = drive.File()
      ..name = filename
      ..mimeType = 'text/plain'
      ..parents = ['appDataFolder'];
    await api.files.create(file, uploadMedia: media);
  }

  Future<List<drive.File>> listBackups() async {
    final api = await _driveApi();
    final result = await api.files.list(
      spaces: 'appDataFolder',
      q: "name contains 'finsage-backup'",
      $fields: 'files(id,name,createdTime,size)',
    );
    return result.files ?? <drive.File>[];
  }

  Future<List<int>> downloadBackup(String fileId) async {
    final api = await _driveApi();
    final response = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final chunks = await response.stream.toList();
    return chunks.expand((e) => e).toList();
  }

  Future<void> deleteBackup(String fileId) async {
    final api = await _driveApi();
    await api.files.delete(fileId);
  }

  Future<drive.File> getBackupMetadata(String fileId) async {
    final api = await _driveApi();
    final file = await api.files.get(fileId, $fields: 'id,name') as drive.File;
    return file;
  }

  Future<String?> downloadBackupChecksumByName(String checksumFilename) async {
    final api = await _driveApi();
    final escaped = _escapeDriveQueryValue(checksumFilename);
    final result = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$escaped'",
      pageSize: 1,
      $fields: 'files(id,name)',
    );
    final files = result.files ?? <drive.File>[];
    final fileId = files.isEmpty ? null : files.first.id;
    if (fileId == null || fileId.isEmpty) {
      return null;
    }
    final text = await _downloadFileAsStringById(fileId);
    final normalized = text.trim();
    return normalized.isEmpty ? null : normalized;
  }

  Future<String> _downloadFileAsStringById(String fileId) async {
    final api = await _driveApi();
    final response = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    final chunks = await response.stream.toList();
    final bytes = chunks.expand((e) => e).toList(growable: false);
    return utf8.decode(bytes);
  }

  String _escapeDriveQueryValue(String value) {
    return value.replaceAll("'", "\\'");
  }
}

class _GoogleAuthClient extends http.BaseClient {
  _GoogleAuthClient(this._headers);

  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
