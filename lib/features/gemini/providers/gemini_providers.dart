import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_features.dart';
import '../data/gemini_api_service.dart';

final geminiApiServiceProvider = Provider<GeminiApiService>((ref) {
  if (!AppFeatures.geminiEnabled) {
    throw UnsupportedError('Gemini feature is disabled.');
  }

  return GeminiApiService();
});
