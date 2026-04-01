import 'package:flutter_base/features/demo_mode/demo_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('DemoModeService', () {
    test('builds the expected GitHub Pages URL', () {
      final service = DemoModeService();

      final uri = service.buildCheckUri(
        baseUrl: 'https://example.github.io/demo',
        bundleId: 'com.example.app',
        buildNumber: '123',
        platform: 'android',
      );

      expect(
        uri.toString(),
        'https://example.github.io/demo/com.example.app.123.android',
      );

      service.dispose();
    });

    test('returns true when the marker file exists', () async {
      final service = DemoModeService(
        client: MockClient((request) async {
          return http.Response('', 200);
        }),
      );

      final isActive = await service.isDemoModeActive(
        baseUrl: 'https://example.github.io/demo',
        bundleId: 'com.example.app',
        buildNumber: '123',
        platform: 'ios',
      );

      expect(isActive, isTrue);
      service.dispose();
    });

    test('returns false when the marker file does not exist', () async {
      final service = DemoModeService(
        client: MockClient((request) async {
          return http.Response('', 404);
        }),
      );

      final isActive = await service.isDemoModeActive(
        baseUrl: 'https://example.github.io/demo',
        bundleId: 'com.example.app',
        buildNumber: '123',
        platform: 'ios',
      );

      expect(isActive, isFalse);
      service.dispose();
    });
  });
}
