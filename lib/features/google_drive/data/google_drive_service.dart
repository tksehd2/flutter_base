import 'dart:io';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../../app/config/app_features.dart';

class _GoogleAuthClient extends http.BaseClient {
  _GoogleAuthClient(this._headers);

  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

class GoogleDriveFileMetadata {
  const GoogleDriveFileMetadata({
    required this.id,
    required this.name,
    this.mimeType,
    this.size,
    this.parents,
    this.webViewLink,
    this.webContentLink,
    this.createdTime,
    this.modifiedTime,
  });

  factory GoogleDriveFileMetadata.fromDriveFile(drive.File file) {
    return GoogleDriveFileMetadata(
      id: file.id ?? '',
      name: file.name ?? '',
      mimeType: file.mimeType,
      size: int.tryParse(file.size ?? ''),
      parents: file.parents,
      webViewLink: file.webViewLink,
      webContentLink: file.webContentLink,
      createdTime: file.createdTime,
      modifiedTime: file.modifiedTime,
    );
  }

  final String id;
  final String name;
  final String? mimeType;
  final int? size;
  final List<String>? parents;
  final String? webViewLink;
  final String? webContentLink;
  final DateTime? createdTime;
  final DateTime? modifiedTime;
}

class GoogleDriveUploadResult {
  const GoogleDriveUploadResult({
    required this.fileId,
    required this.name,
    this.parentId,
    this.webViewLink,
    this.webContentLink,
  });

  final String fileId;
  final String name;
  final String? parentId;
  final String? webViewLink;
  final String? webContentLink;
}

class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();

  factory GoogleDriveService() => _instance;

  GoogleDriveService._internal();

  void _ensureFeatureEnabled() {
    if (!AppFeatures.googleDriveEnabled) {
      throw UnsupportedError('Google Drive feature is disabled.');
    }
  }

  Future<drive.DriveApi> _getDriveApi(String accessToken) async {
    _ensureFeatureEnabled();
    if (accessToken.isEmpty) {
      throw Exception('GOOGLE_DRIVE_ACCESS_TOKEN_MISSING');
    }

    final authClient = _GoogleAuthClient({
      'Authorization': 'Bearer $accessToken',
    });
    return drive.DriveApi(authClient);
  }

  String buildPublicFileUrl(String fileId) {
    _ensureFeatureEnabled();
    return 'https://drive.google.com/uc?id=$fileId';
  }

  String? extractFileId(String fileRef) {
    _ensureFeatureEnabled();
    final trimmed = fileRef.trim();
    if (trimmed.isEmpty) return null;

    final idQueryMatch = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)').firstMatch(trimmed);
    if (idQueryMatch != null) return idQueryMatch.group(1);

    final filePathMatch = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(trimmed);
    if (filePathMatch != null) return filePathMatch.group(1);

    final bareIdMatch = RegExp(r'^[a-zA-Z0-9_-]+$').firstMatch(trimmed);
    return bareIdMatch?.group(0);
  }

  Future<void> _ensureLinkPermission(
    drive.DriveApi driveApi,
    String fileId, {
    String role = 'reader',
  }) async {
    _ensureFeatureEnabled();
    final permissions = await driveApi.permissions.list(fileId);
    final alreadyExists = (permissions.permissions ?? []).any(
      (permission) => permission.type == 'anyone' && permission.role == role,
    );
    if (alreadyExists) return;

    await driveApi.permissions.create(
      drive.Permission()
        ..type = 'anyone'
        ..role = role,
      fileId,
    );
  }

  Future<String> getOrCreateFolder({
    required String accessToken,
    required String folderName,
    String? parentFolderId,
  }) async {
    _ensureFeatureEnabled();
    final driveApi = await _getDriveApi(accessToken);

    final parentQuery = parentFolderId == null
        ? ''
        : " and '$parentFolderId' in parents";
    final result = await driveApi.files.list(
      q:
          "name = '$folderName' and "
          "mimeType = 'application/vnd.google-apps.folder' and "
          "trashed = false$parentQuery",
      $fields: 'files(id, name)',
    );

    if (result.files != null && result.files!.isNotEmpty) {
      return result.files!.first.id!;
    }

    final folder = drive.File()
      ..name = folderName
      ..mimeType = 'application/vnd.google-apps.folder'
      ..parents = parentFolderId == null ? null : [parentFolderId];

    final created = await driveApi.files.create(folder, $fields: 'id, name');

    if (created.id == null) {
      throw Exception('GOOGLE_DRIVE_FOLDER_CREATE_FAILED');
    }

    return created.id!;
  }

  Future<GoogleDriveUploadResult> uploadFile({
    required String accessToken,
    required File file,
    String? fileName,
    String? parentFolderId,
    String? mimeType,
    bool makePublic = false,
  }) async {
    _ensureFeatureEnabled();
    final driveApi = await _getDriveApi(accessToken);

    if (!await file.exists()) {
      throw Exception('LOCAL_FILE_NOT_FOUND: ${file.path}');
    }

    final uploadName = fileName ?? p.basename(file.path);
    final driveFile = drive.File()
      ..name = uploadName
      ..mimeType = mimeType
      ..parents = parentFolderId == null ? null : [parentFolderId];

    final media = drive.Media(file.openRead(), file.lengthSync());
    final created = await driveApi.files.create(
      driveFile,
      uploadMedia: media,
      $fields: 'id, name, webViewLink, webContentLink, parents',
    );

    final fileId = created.id;
    if (fileId == null) {
      throw Exception('GOOGLE_DRIVE_UPLOAD_FAILED');
    }

    if (makePublic) {
      await _ensureLinkPermission(driveApi, fileId);
    }

    final metadata = await getFileMetadata(
      accessToken: accessToken,
      fileRef: fileId,
    );
    return GoogleDriveUploadResult(
      fileId: fileId,
      name: metadata.name,
      parentId: metadata.parents?.isNotEmpty == true
          ? metadata.parents!.first
          : null,
      webViewLink: metadata.webViewLink,
      webContentLink: metadata.webContentLink,
    );
  }

  Future<GoogleDriveFileMetadata> getFileMetadata({
    required String accessToken,
    required String fileRef,
  }) async {
    _ensureFeatureEnabled();
    final fileId = extractFileId(fileRef);
    if (fileId == null) {
      throw Exception('INVALID_GOOGLE_DRIVE_FILE_REF');
    }

    final driveApi = await _getDriveApi(accessToken);
    final file =
        await driveApi.files.get(
              fileId,
              $fields:
                  'id, name, mimeType, size, parents, webViewLink, webContentLink, createdTime, modifiedTime',
            )
            as drive.File;

    return GoogleDriveFileMetadata.fromDriveFile(file);
  }

  Future<File> downloadFile({
    required String accessToken,
    required String fileRef,
    required String savePath,
    bool createDirectories = true,
  }) async {
    _ensureFeatureEnabled();
    final fileId = extractFileId(fileRef);
    if (fileId == null) {
      throw Exception('INVALID_GOOGLE_DRIVE_FILE_REF');
    }

    final driveApi = await _getDriveApi(accessToken);
    final response =
        await driveApi.files.get(
              fileId,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;

    final file = File(savePath);
    if (createDirectories) {
      await file.parent.create(recursive: true);
    }

    final sink = file.openWrite();
    await response.stream.pipe(sink);
    await sink.flush();
    await sink.close();

    return file;
  }

  Future<void> deleteFile({
    required String accessToken,
    required String fileRef,
  }) async {
    _ensureFeatureEnabled();
    final fileId = extractFileId(fileRef);
    if (fileId == null) {
      throw Exception('INVALID_GOOGLE_DRIVE_FILE_REF');
    }

    final driveApi = await _getDriveApi(accessToken);
    await driveApi.files.delete(fileId);
  }
}
