import 'package:flutter_test/flutter_test.dart';
import 'package:tan_sdk/tan_sdk.dart';

void main() {
  group('SDKConfig Tests', () {
    test('creates config with default values', () {
      const config = SDKConfig();
      expect(config.apiKey, isNull);
      expect(config.baseUrl, isNull);
      expect(config.timeout, 30);
      expect(config.debug, false);
    });

    test('creates config with custom values', () {
      const config = SDKConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com',
        timeout: 60,
        debug: true,
      );
      expect(config.apiKey, 'test-key');
      expect(config.baseUrl, 'https://api.example.com');
      expect(config.timeout, 60);
      expect(config.debug, true);
    });

    test('creates config from map', () {
      final config = SDKConfig.fromMap({
        'apiKey': 'test-key',
        'baseUrl': 'https://api.example.com',
        'timeout': 45,
        'debug': true,
      });
      expect(config.apiKey, 'test-key');
      expect(config.baseUrl, 'https://api.example.com');
      expect(config.timeout, 45);
      expect(config.debug, true);
    });

    test('validates config successfully', () {
      const config = SDKConfig(timeout: 30);
      expect(() => config.validate(), returnsNormally);
    });

    test('throws exception for invalid timeout', () {
      const config = SDKConfig(timeout: 0);
      expect(() => config.validate(), throwsA(isA<ConfigurationException>()));
    });
  });

  group('SDKService Tests', () {
    test('initializes successfully with valid config', () {
      final service = SDKService(
        config: const SDKConfig(debug: false),
      );
      expect(service.isInitialized, false);
      service.initialize();
      expect(service.isInitialized, true);
      service.dispose();
    });

    test('can be disposed', () {
      final service = SDKService(
        config: const SDKConfig(),
      );
      service.initialize();
      expect(service.isInitialized, true);
      service.dispose();
      expect(service.isInitialized, false);
    });
  });

  group('SDKException Tests', () {
    test('creates exception with message', () {
      const exception = SDKException('Test error');
      expect(exception.message, 'Test error');
      expect(exception.toString(), 'SDKException: Test error');
    });

    test('creates exception with code', () {
      const exception = SDKException('Test error', code: 'ERR001');
      expect(exception.code, 'ERR001');
      expect(exception.toString(), 'SDKException [ERR001]: Test error');
    });
  });

  group('SDKConstants Tests', () {
    test('has correct version', () {
      expect(SDKConstants.version, '0.0.1');
    });

    test('has correct name', () {
      expect(SDKConstants.name, 'tan_sdk');
    });

    test('has default timeout', () {
      expect(SDKConstants.defaultTimeout, 30);
    });
  });
}
