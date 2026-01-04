import '../config/sdk_config.dart';
import '../core/base_client.dart';

/// Main SDK service class.
/// 
/// This is the primary entry point for SDK operations.
class SDKService extends BaseClient {
  /// SDK configuration.
  final SDKConfig config;
  
  /// Whether the service is initialized.
  bool _isInitialized = false;
  
  /// Creates a new [SDKService] instance.
  SDKService({required this.config});
  
  /// Initialize the SDK service.
  @override
  void initialize() {
    if (_isInitialized) {
      return;
    }
    
    config.validate();
    _isInitialized = true;
    
    if (config.debug) {
      print('TAN SDK initialized successfully');
    }
  }
  
  /// Check if the service is initialized.
  bool get isInitialized => _isInitialized;
  
  /// Dispose resources.
  @override
  void dispose() {
    _isInitialized = false;
    if (config.debug) {
      print('TAN SDK disposed');
    }
  }
}
