/// TAN SDK - A Flutter SDK package.
///
/// This package provides a Software Development Kit for Flutter applications.
library tan_sdk;

// Export Core package (using main export file for better IDE navigation)
export 'package:core/core.dart';

// Export data models
export 'data/models/loan_application.dart';

// Export domain repositories
export 'domain/repos/loan_repo.dart';

// Export repository implementations
export 'data/repo_imp/loan_repo_imp.dart';

// Export use cases
export 'domain/use_cases/create_loan_use_case.dart';

// Export services (backward compatibility)
export 'services/loan_service.dart';
export 'services/sdk_service.dart';

// Export SDK public entry point
export 'tan_sdk_entry.dart';
export 'utils/http_logger.dart';