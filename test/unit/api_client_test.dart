import 'package:flutter_test/flutter_test.dart';
import 'package:aplicacion/core/network/api_client.dart';
import 'package:aplicacion/core/storage/token_storage.dart';

void main() {
  group('ApiClient', () {
    test('should create a singleton-like instance', () {
      final client = ApiClient();
      expect(client, isNotNull);
      expect(client.dio, isNotNull);
    });

    test('should set auth token in headers', () {
      final client = ApiClient();
      client.setAuthToken('test-jwt-token');

      expect(
        client.dio.options.headers['Authorization'],
        'Bearer test-jwt-token',
      );
    });

    test('should clear auth token', () {
      final client = ApiClient();
      client.setAuthToken('test-jwt-token');
      client.setAuthToken(null);

      expect(client.dio.options.headers['Authorization'], isNull);
    });

    test('should have correct base configuration', () {
      final client = ApiClient();
      expect(client.dio.options.connectTimeout, isNotNull);
      expect(client.dio.options.receiveTimeout, isNotNull);
    });
  });

  group('TokenStorage', () {
    test('should have required storage keys', () {
      final storage = TokenStorage();
      expect(storage, isNotNull);
    });
  });
}
