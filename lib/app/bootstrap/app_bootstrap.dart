import '../../features/gemini/gemini.dart';
import '../../features/google_auth/google_auth.dart';
import '../config/app_features.dart';

class AppBootstrap {
  const AppBootstrap._();

  static void initialize() {
    const googleServerClientId = String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
      defaultValue: '',
    );

    if (AppFeatures.googleAuthEnabled && googleServerClientId.isNotEmpty) {
      GoogleAuthService.configure(
        serverClientId: googleServerClientId,
        scopes: [
          if (AppFeatures.geminiEnabled)
            'https://www.googleapis.com/auth/generative-language.peruserquota',
          if (AppFeatures.googleDriveEnabled)
            'https://www.googleapis.com/auth/drive.file',
        ],
      );
    }

    if (AppFeatures.geminiEnabled) {
      GeminiApiService.configure(model: 'gemini-2.5-flash');
    }
  }
}
