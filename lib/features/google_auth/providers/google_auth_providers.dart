import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../app/config/app_features.dart';
import '../data/google_auth_service.dart';

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  if (!AppFeatures.googleAuthEnabled) {
    throw UnsupportedError('Google auth feature is disabled.');
  }

  return GoogleAuthService();
});

final googleAccessTokenProvider = FutureProvider<String?>((ref) async {
  final authService = ref.watch(googleAuthServiceProvider);
  return authService.getAccessToken();
});

final googleAuthStateProvider =
    AsyncNotifierProvider<GoogleAuthController, GoogleSignInAccount?>(
      GoogleAuthController.new,
    );

class GoogleAuthController extends AsyncNotifier<GoogleSignInAccount?> {
  @override
  Future<GoogleSignInAccount?> build() async {
    if (!AppFeatures.googleAuthEnabled) {
      return null;
    }

    final authService = ref.watch(googleAuthServiceProvider);
    return authService.signInSilently();
  }

  Future<GoogleSignInAccount?> signIn() async {
    final authService = ref.read(googleAuthServiceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(authService.signIn);
    return state.valueOrNull;
  }

  Future<void> signOut() async {
    final authService = ref.read(googleAuthServiceProvider);
    await authService.signOut();
    state = const AsyncData(null);
  }
}
