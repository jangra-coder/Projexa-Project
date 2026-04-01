import 'dart:io';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// An HTTP client that adds Google auth headers to every request.
class _AuthenticatedClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  final Map<String, String> _headers;

  _AuthenticatedClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}

/// Manages file uploads to the user's Google Drive.
///
/// Files are stored inside a dedicated "Warranty Vault" folder so the
/// user can easily find them and the app only touches its own data.
class DriveService {
  drive.DriveApi? _driveApi;
  String? _appFolderId;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Initialize Drive API using an access token from Google Sign-In authorization.
  Future<void> initialize(String accessToken) async {
    try {
      final client = _AuthenticatedClient({
        'Authorization': 'Bearer $accessToken',
        'X-Goog-Api-Client': 'flutter',
      });

      _driveApi = drive.DriveApi(client);
      _appFolderId = await _getOrCreateAppFolder();
      _initialized = true;
    } catch (e) {
      _initialized = false;
      rethrow;
    }
  }

  /// Finds or creates the "Warranty Vault" folder in the user's Drive root.
  Future<String> _getOrCreateAppFolder() async {
    const folderName = 'Warranty Vault';
    const mimeType = 'application/vnd.google-apps.folder';

    // Search for existing folder
    final result = await _driveApi!.files.list(
      q: "name = '$folderName' and mimeType = '$mimeType' and trashed = false",
      spaces: 'drive',
      $fields: 'files(id, name)',
    );

    if (result.files != null && result.files!.isNotEmpty) {
      return result.files!.first.id!;
    }

    // Create the folder
    final folder = drive.File()
      ..name = folderName
      ..mimeType = mimeType;

    final created = await _driveApi!.files.create(folder);
    return created.id!;
  }

  /// Upload an image file to the app's Drive folder.
  ///
  /// Returns a map with `fileId` and `webViewLink`.
  Future<Map<String, String>> uploadImage(
    File file,
    String warrantyId,
    String imageType, // 'product' or 'receipt'
  ) async {
    if (!_initialized || _driveApi == null) {
      throw Exception('Drive service not initialized');
    }

    final fileName =
        '${warrantyId}_$imageType${_getExtension(file.path)}';

    final driveFile = drive.File()
      ..name = fileName
      ..parents = [_appFolderId!];

    final media = drive.Media(
      file.openRead(),
      file.lengthSync(),
    );

    final uploaded = await _driveApi!.files.create(
      driveFile,
      uploadMedia: media,
      $fields: 'id, webViewLink, thumbnailLink',
    );

    return {
      'fileId': uploaded.id ?? '',
      'webViewLink': uploaded.webViewLink ?? '',
    };
  }

  /// Get a direct content download URL for a Drive file.
  String getDownloadUrl(String fileId) {
    return 'https://drive.google.com/uc?export=view&id=$fileId';
  }

  /// Delete a file from Google Drive.
  Future<void> deleteImage(String fileId) async {
    if (!_initialized || _driveApi == null) return;
    try {
      await _driveApi!.files.delete(fileId);
    } catch (_) {
      // File may already be deleted – ignore
    }
  }

  /// Dispose / reset the service (e.g. on logout).
  void dispose() {
    _driveApi = null;
    _appFolderId = null;
    _initialized = false;
  }

  String _getExtension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1) return '.jpg';
    return path.substring(dot);
  }
}
