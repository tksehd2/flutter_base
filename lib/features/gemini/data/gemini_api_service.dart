import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../../../app/config/app_features.dart';

class GeminiApiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  static GeminiApiService? _instance;

  /// [model] 사용할 Gemini 모델명 (예: gemini-2.5-flash)
  static void configure({String model = 'gemini-2.5-flash'}) {
    _ensureFeatureEnabled();
    _instance = GeminiApiService._internal(model: model);
  }

  factory GeminiApiService() {
    _ensureFeatureEnabled();
    _instance ??= GeminiApiService._internal(model: 'gemini-2.5-flash');
    return _instance!;
  }

  static void _ensureFeatureEnabled() {
    if (!AppFeatures.geminiEnabled) {
      throw UnsupportedError('Gemini feature is disabled.');
    }
  }

  GeminiApiService._internal({required String model}) : _model = model;

  final String _model;

  String get _apiUrl => '$_baseUrl/$_model:generateContent';

  /// 이미지를 Gemini 전송에 적합한 JPEG로 압축합니다.
  Future<Uint8List> compressImage(Uint8List bytes) {
    _ensureFeatureEnabled();
    return compute(_compressImageSync, bytes);
  }

  static Uint8List _compressImageSync(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    const maxDim = 1280;
    img.Image resized;
    if (decoded.width > maxDim || decoded.height > maxDim) {
      if (decoded.width >= decoded.height) {
        resized = img.copyResize(decoded, width: maxDim);
      } else {
        resized = img.copyResize(decoded, height: maxDim);
      }
    } else {
      resized = decoded;
    }

    return Uint8List.fromList(img.encodeJpg(resized, quality: 75));
  }

  Future<String> generateText({
    required String prompt,
    required String accessToken,
    double temperature = 0.7,
    String responseMimeType = 'application/json',
  }) async {
    _ensureFeatureEnabled();
    return _generate(
      accessToken: accessToken,
      parts: [
        {'text': prompt},
      ],
      temperature: temperature,
      responseMimeType: responseMimeType,
    );
  }

  Future<String> generateTextWithImage({
    required String prompt,
    required File imageFile,
    required String accessToken,
    String mimeType = 'image/jpeg',
    double temperature = 0.7,
    String responseMimeType = 'application/json',
  }) async {
    _ensureFeatureEnabled();
    if (!await imageFile.exists()) {
      throw Exception('IMAGE_FILE_NOT_FOUND: ${imageFile.path}');
    }

    final originalBytes = await imageFile.readAsBytes();
    final uploadBytes = mimeType == 'image/jpeg'
        ? await compressImage(originalBytes)
        : originalBytes;

    return _generate(
      accessToken: accessToken,
      parts: [
        {'text': prompt},
        {
          'inlineData': {
            'mimeType': mimeType,
            'data': base64Encode(uploadBytes),
          },
        },
      ],
      temperature: temperature,
      responseMimeType: responseMimeType,
    );
  }

  /// 이전 템플릿 호환용 진입점입니다.
  Future<String> generateContent({
    required String prompt,
    required String accessToken,
    double temperature = 0.7,
    String responseMimeType = 'application/json',
  }) {
    _ensureFeatureEnabled();
    return generateText(
      prompt: prompt,
      accessToken: accessToken,
      temperature: temperature,
      responseMimeType: responseMimeType,
    );
  }

  Future<String> _generate({
    required String accessToken,
    required List<Map<String, dynamic>> parts,
    required double temperature,
    required String responseMimeType,
  }) async {
    _ensureFeatureEnabled();
    if (accessToken.isEmpty) {
      throw Exception('ACCESS_TOKEN_MISSING');
    }

    final url = Uri.parse(_apiUrl);
    final requestBody = {
      'contents': [
        {'parts': parts},
      ],
      'generationConfig': {
        'temperature': temperature,
        'responseMimeType': responseMimeType,
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
          responseData['candidates'][0]['content']['parts'][0]['text'] ?? '{}';

      if (responseMimeType == 'application/json') {
        responseText = responseText
            .replaceAll(RegExp(r'```json|```'), '')
            .trim();
      }

      return responseText;
    } else {
      debugPrint("API Error: ${response.statusCode} - ${response.body}");
      throw Exception("API_ERROR_${response.statusCode}");
    }
  }
}
