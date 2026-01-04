import '../exceptions/sdk_exception.dart';

/// Configuration class for SDK initialization.
class SDKConfig {
  /// API key or token (optional).
  final String? apiKey;

  /// Base URL for API calls (optional).
  final String? baseUrl;

  /// Timeout duration in seconds.
  final int timeout;

  /// Enable debug mode.
  final bool debug;

  /// Creates a new [SDKConfig].
  const SDKConfig({
    this.apiKey,
    this.baseUrl,
    this.timeout = 30,
    this.debug = false,
  });

  /// Creates a [SDKConfig] from a map.
  factory SDKConfig.fromMap(Map<String, dynamic> map) {
    return SDKConfig(
      apiKey: map['apiKey'] as String?,
      baseUrl: map['baseUrl'] as String?,
      timeout: map['timeout'] as int? ?? 30,
      debug: map['debug'] as bool? ?? false,
    );
  }

  /// Validates the configuration.
  void validate() {
    if (timeout <= 0) {
      throw const ConfigurationException('Timeout must be greater than 0');
    }
  }

  /// Converts the configuration to a map.
  Map<String, dynamic> toMap() {
    return {
      'apiKey': apiKey,
      'baseUrl': baseUrl,
      'timeout': timeout,
      'debug': debug,
    };
  }
}
