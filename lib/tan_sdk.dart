/// TAN SDK - A Flutter SDK package.
///
/// This package provides a Software Development Kit for Flutter applications.
library tan_sdk;

// Export Core package (using main export file for better IDE navigation)
export 'package:core/core.dart';

// Export services (backward compatibility)
export 'services/sdk_service.dart';

// Export SDK public entry point
export 'tan_sdk_entry.dart';
export 'utils/http_logger.dart';