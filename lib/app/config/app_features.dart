class AppFeatures {
  const AppFeatures._();

  static const bool googleAuth = true;
  static const bool googleDrive = true;
  static const bool gemini = true;
  static const bool driftDb = true;
  static const bool dioNetwork = true;

  static bool get googleAuthEnabled => googleAuth;

  static bool get googleDriveEnabled => googleAuth && googleDrive;

  static bool get geminiEnabled => googleAuth && gemini;

  static bool get driftDbEnabled => driftDb;

  static bool get dioNetworkEnabled => dioNetwork;
}
