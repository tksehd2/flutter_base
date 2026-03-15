import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_base/services/google_auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// 구글 API 통신 시 토큰을 주입해 주는 커스텀 HTTP 클라이언트
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  factory GoogleDriveService() => _instance;
  GoogleDriveService._internal();

  // 1️⃣ 구글 드라이브(appDataFolder)에 저장될 백업 파일 이름
  final String _backupFileName = 'seesaw_diary_backup.sqlite';

  // 2️⃣ native.dart에서 명시한 실제 로컬 DB 파일 이름
  final String _localDbFileName = 'diary_db.sqlite';

  // 드라이브 API 클라이언트 초기화 헬퍼
  Future<drive.DriveApi?> _getDriveApi() async {
    final token = await GoogleAuthService().getAccessToken();
    if (token == null) {
      debugPrint('구글 드라이브 API 초기화 실패: 액세스 토큰이 없습니다.');
      return null;
    }

    final authClient = _GoogleAuthClient({'Authorization': 'Bearer $token'});

    return drive.DriveApi(authClient);
  }

  /// ⬆️ [백업] 로컬 DB -> 구글 드라이브 업로드
  Future<bool> backupDatabase() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      // 1. 로컬 DB 파일 경로 확보
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dbFolder.path, _localDbFileName);
      final file = File(dbPath);

      if (!await file.exists()) {
        debugPrint('백업 실패: 로컬 DB 파일이 존재하지 않습니다. ($dbPath)');
        return false;
      }

      // 2. 드라이브(appDataFolder)에서 기존 백업 파일 검색
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_backupFileName'",
      );

      final existingFileId = fileList.files?.isNotEmpty == true
          ? fileList.files!.first.id
          : null;

      // 3. 파일 업로드 준비
      final media = drive.Media(file.openRead(), file.lengthSync());

      if (existingFileId != null) {
        // 기존 파일 덮어쓰기 (Update)
        await driveApi.files.update(
          drive.File(),
          existingFileId,
          uploadMedia: media,
        );
        debugPrint('백업 완료: 기존 파일 업데이트됨');
      } else {
        // 새 파일 생성 (Create)
        final driveFile = drive.File()
          ..name = _backupFileName
          ..parents = ["appDataFolder"];

        await driveApi.files.create(driveFile, uploadMedia: media);
        debugPrint('백업 완료: 새 파일 생성됨');
      }
      return true;
    } catch (e) {
      debugPrint('백업 중 에러 발생: $e');
      return false;
    }
  }

  /// 🗑️ [삭제] 구글 드라이브의 백업 파일 영구 삭제
  Future<bool> deleteBackup() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      // 1. 드라이브에서 백업 파일 검색
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_backupFileName'",
      );

      // 2. 파일이 존재하면 삭제 (delete)
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        final fileId = fileList.files!.first.id!;

        // 💡 휴지통으로 가는 게 아니라 영구 삭제됩니다.
        await driveApi.files.delete(fileId);
        debugPrint('드라이브 백업 파일 삭제 완료');
        return true;
      }

      debugPrint('삭제할 백업 파일이 없습니다.');
      return true; // 지울 게 없으니 결과적으로는 성공 상태
    } catch (e) {
      debugPrint('드라이브 백업 파일 삭제 중 에러 발생: $e');
      return false;
    }
  }

  /// 💡 구글 드라이브(appDataFolder)에 백업 파일이 존재하는지 가볍게 확인
  Future<bool> hasBackupFile() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      // appDataFolder에서 백업 파일 이름으로 검색
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_backupFileName'",
      );

      // 파일 목록이 null이 아니고, 비어있지 않다면 파일이 존재하는 것
      return fileList.files != null && fileList.files!.isNotEmpty;
    } catch (e) {
      debugPrint('백업 파일 확인 중 에러 발생: $e');
      return false;
    }
  }

  /// ⬇️ [복구] 구글 드라이브 -> 로컬 DB 덮어쓰기
  Future<bool> restoreDatabase() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      // 1. 드라이브에서 백업 파일 검색
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_backupFileName'",
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        debugPrint('복구 실패: 드라이브에 백업 파일이 없습니다.');
        return false;
      }

      final fileId = fileList.files!.first.id!;

      // 2. [매우 중요] 기존 DB 연결 해제 (파일 Lock 풀기)
      // 이 작업을 하지 않으면 OS 단에서 덮어쓰기가 거부될 수 있습니다.
      debugPrint('복구 진행: 기존 DB 연결 해제 중...');
      // TODO: Close database

      // 3. 백업 파일 다운로드 스트림 요청
      final response =
          await driveApi.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      // 4. 로컬 DB 경로 확보
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dbFolder.path, _localDbFileName);
      final file = File(dbPath);

      // 5. 다운로드한 데이터를 로컬 파일에 덮어쓰기
      debugPrint('복구 진행: 파일 덮어쓰기 중...');
      final sink = file.openWrite();
      await response.stream.pipe(sink);
      await sink.flush();
      await sink.close();

      // 6. [매우 중요] DB 재연결
      debugPrint('복구 진행: DB 재연결 중...');
      // TODO: Reopen databsse

      debugPrint('복구 완료: 성공적으로 데이터를 복원했습니다.');
      return true;
    } catch (e) {
      debugPrint('복구 중 에러 발생: $e');
      // 에러 발생 시에도 안전을 위해 DB 재연결 시도
      // TODO: Reopen databsse
      return false;
    }
  }
}
