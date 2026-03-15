// lib/services/gemini_api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ⭐️ GoogleAuthService 임포트 경로 확인 필요
import '../services/google_auth_service.dart';

class GeminiApiService {
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  /// 프롬프트를 받아 Gemini API를 호출하고 결과 텍스트를 반환합니다.
  static Future<String> generateContent({
    required String prompt,
    double temperature = 0.7,
    String responseMimeType = "application/json",
  }) async {
    final String? accessToken = await GoogleAuthService().getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception("ACCESS_TOKEN_MISSING");
    }

    final url = Uri.parse(_apiUrl);
    final requestBody = {
      "contents": [
        {
          "parts": [
            {"text": prompt},
          ],
        },
      ],
      "generationConfig": {
        "temperature": temperature,
        "responseMimeType": responseMimeType,
      },
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      String responseText =
          responseData['candidates'][0]['content']['parts'][0]['text'] ?? "{}";

      // JSON 포맷을 요청했을 경우 마크다운 백틱(```) 찌꺼기 제거 전처리
      if (responseMimeType == "application/json") {
        responseText = responseText
            .replaceAll(RegExp(r'```json|```'), "")
            .trim();
      }

      return responseText;
    } else {
      debugPrint("API Error: ${response.statusCode} - ${response.body}");
      throw Exception("API_ERROR_${response.statusCode}");
    }
  }
}
