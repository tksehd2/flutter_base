import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_features.dart';
import '../data/google_drive_service.dart';

final googleDriveServiceProvider = Provider<GoogleDriveService>((ref) {
  if (!AppFeatures.googleDriveEnabled) {
    throw UnsupportedError('Google Drive feature is disabled.');
  }

  return GoogleDriveService();
});
