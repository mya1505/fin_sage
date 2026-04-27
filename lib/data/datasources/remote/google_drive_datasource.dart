import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

class GoogleDriveDataSource {
  GoogleDriveDataSource(this._googleSignIn);

  final GoogleSignIn _googleSignIn;

  Future<drive.DriveApi> _driveApi() async {
    final account = await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
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
