import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AppDio {
  AppDio._();

  static Dio create({
    String? baseUrl,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 20),
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? '',
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('[DIO] ${options.method} ${options.uri}');
          handler.next(options);
        },
        onError: (error, handler) {
          debugPrint(
            '[DIO][ERROR] ${error.requestOptions.uri} ${error.message}',
          );
          handler.next(error);
        },
      ),
    );

    return dio;
  }
}
