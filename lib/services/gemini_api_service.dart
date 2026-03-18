import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'google_auth_service.dart';

class GeminiApiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  static GeminiApiService? _instance;

  /// [model] 사용할 Gemini 모델명 (예: gemini-2.5-flash)
  static void configure({String model = 'gemini-2.5-flash'}) {
    _instance = GeminiApiService._internal(model: model);
  }

  factory GeminiApiService() {
    _instance ??= GeminiApiService._internal(model: 'gemini-2.5-flash');
    return _instance!;
  }

  GeminiApiService._internal({required String model}) : _model = model;

  final String _model;

  String get _apiUrl => '$_baseUrl/$_model:generateContent';

  /// 프롬프트를 받아 Gemini API를 호출하고 결과 텍스트를 반환합니다.
  Future<String> generateContent({
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

      if (responseMimeType == "application/json") {
        responseText =
            responseText.replaceAll(RegExp(r'```json|```'), "").trim();
      }

      return responseText;
    } else {
      debugPrint("API Error: ${response.statusCode} - ${response.body}");
      throw Exception("API_ERROR_${response.statusCode}");
    }
  }
}
