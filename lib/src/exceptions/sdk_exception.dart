/// Base exception class for SDK errors.
class SDKException implements Exception {
  /// Error message.
  final String message;
  
  /// Error code (optional).
  final String? code;
  
  /// Original exception (optional).
  final dynamic originalError;
  
  /// Creates a new [SDKException].
  const SDKException(
    this.message, {
    this.code,
    this.originalError,
  });
  
  @override
  String toString() {
    if (code != null) {
      return 'SDKException [$code]: $message';
    }
    return 'SDKException: $message';
  }
}

/// Exception thrown when configuration is invalid.
class ConfigurationException extends SDKException {
  const ConfigurationException(super.message, {super.code, super.originalError});
}

/// Exception thrown when an operation fails.
class OperationException extends SDKException {
  const OperationException(super.message, {super.code, super.originalError});
}




