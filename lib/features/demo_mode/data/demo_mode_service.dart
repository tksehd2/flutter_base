import 'package:http/http.dart' as http;

class DemoModeService {
  DemoModeService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri buildCheckUri({
    required String baseUrl,
    required String bundleId,
    required String buildNumber,
    required String platform,
  }) {
    final normalizedBaseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final fileName = '$bundleId.$buildNumber.$platform';
    return Uri.parse(normalizedBaseUrl).resolve(fileName);
  }

  Future<bool> isDemoModeActive({
    required String baseUrl,
    required String bundleId,
    required String buildNumber,
    required String platform,
  }) async {
    if (baseUrl.trim().isEmpty ||
        bundleId.trim().isEmpty ||
        buildNumber.trim().isEmpty ||
        platform.trim().isEmpty) {
      return false;
    }

    try {
      final response = await _client.get(
        buildCheckUri(
          baseUrl: baseUrl.trim(),
          bundleId: bundleId.trim(),
          buildNumber: buildNumber.trim(),
          platform: platform.trim(),
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}
