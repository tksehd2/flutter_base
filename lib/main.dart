import 'package:flutter/material.dart';
// import 'package:flutter_base/services/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 서비스 초기화 (필요한 것만 주석 해제하여 사용) ──────────────
  //
  // [Google 로그인] Google Cloud Console에서 발급받은 Client ID로 교체
  // GoogleAuthService.configure(
  //   serverClientId: 'YOUR_SERVER_CLIENT_ID.apps.googleusercontent.com',
  //   scopes: [
  //     'https://www.googleapis.com/auth/generative-language.peruserquota',
  //     'https://www.googleapis.com/auth/drive.appdata',
  //   ],
  // );
  //
  // [Gemini API] 모델 설정 (기본값: gemini-2.5-flash)
  // GeminiApiService.configure(model: 'gemini-2.5-flash');
  //
  // [Google Drive 백업] GoogleAuthService 설정 필요
  // GoogleDriveService.configure(
  //   backupFileName: 'app_backup.sqlite',
  //   localDbFileName: 'app_db.sqlite',
  //   onBeforeRestore: () async => db.close(),
  //   onAfterRestore: () async => db.reopen(),
  // );
  // ─────────────────────────────────────────────────────────────

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Base',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Flutter Base'),
      ),
      body: const Center(
        child: Text('Base project ready.'),
      ),
    );
  }
}
