import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final List<String> _scopes = [
    'https://www.googleapis.com/auth/generative-language.peruserquota',
    'https://www.googleapis.com/auth/generative-language.tuning.readonly',
    'https://www.googleapis.com/auth/drive.appdata', // 👈 [추가] 숨겨진 백업 폴더 접근 권한
  ];

  final String _serverClientId =
      '417933943985-0ovk3hsmsn5fpog3719n3r21i0dlvl7f.apps.googleusercontent.com';

  bool _isInitialized = false;

  // ⭐️ [핵심] 로그인 성공 시 계정 정보를 메모리에 상주시켜서 돌려쓰기
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
