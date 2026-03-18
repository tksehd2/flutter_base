import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static GoogleAuthService? _instance;

  /// 앱 시작 시 반드시 1회 호출하여 초기화해야 합니다.
  /// [serverClientId] Google Cloud Console에서 발급받은 OAuth 클라이언트 ID
  /// [scopes] 요청할 OAuth 스코프 목록
  static void configure({
    required String serverClientId,
    required List<String> scopes,
  }) {
    _instance = GoogleAuthService._internal(
      serverClientId: serverClientId,
      scopes: scopes,
    );
  }

  factory GoogleAuthService() {
    assert(_instance != null, 'GoogleAuthService.configure()를 먼저 호출하세요.');
    return _instance!;
  }

  GoogleAuthService._internal({
    required String serverClientId,
    required List<String> scopes,
  })  : _serverClientId = serverClientId,
        _scopes = scopes;

  final List<String> _scopes;
  final String _serverClientId;
  bool _isInitialized = false;
  GoogleSignInAccount? _currentUser;

  Future<void> _init() async {
    if (!_isInitialized) {
      await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);
      _isInitialized = true;
    }
  }

  // 자동 로그인 (앱 진입 시 1회 호출)
  Future<GoogleSignInAccount?> signInSilently() async {
    await _init();
    try {
      // 💡 이미 로그인된 상태라면 팝업 없이 계정 정보를 가져옴
      _currentUser = await GoogleSignIn.instance
          .attemptLightweightAuthentication();
      return _currentUser;
    } catch (e) {
      debugPrint("자동 로그인 실패: $e");
      return null;
    }
  }

  // 명시적 로그인 (최초 1회 또는 로그아웃 후 재로그인 시)
  Future<GoogleSignInAccount?> signIn() async {
    await _init();
    try {
      _currentUser = await GoogleSignIn.instance.authenticate();

      return _currentUser;
    } catch (e) {
      debugPrint("로그인 에러: $e");
      return null;
    }
  }

  // ⭐️ [핵심] 팝업 절대 안 뜨고 메모리 세션에서 토큰만 조용히 갱신
  Future<String?> getAccessToken() async {
    // 1. 메모리에 저장된 유저 정보가 있는지 확인
    // 만약 메모리가 날아갔다면 조용히 다시 채워넣기 시도 (팝업 X)
    _currentUser ??= await signInSilently();

    if (_currentUser == null) {
      debugPrint("인증 세션이 없습니다. 로그인이 필요합니다.");
      return null;
    }

    try {
      // 2. 💡 이미 인증된 객체에서 인가(Authorization) 절차만 진행
      //    이 과정에서 스코프가 이미 승인되어 있다면 팝업 없이 토큰만 쏙 나옴
      final authorizedUser = await _currentUser!.authorizationClient
          .authorizeScopes(_scopes);
      return authorizedUser.accessToken;
    } catch (e) {
      debugPrint("토큰 획득 에러: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _init();
    await GoogleSignIn.instance.signOut();
    _currentUser = null; // 메모리 비우기
  }
}
