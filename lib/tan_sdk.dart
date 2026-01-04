/// TAN SDK - A Flutter SDK package.
///
/// This package provides a Software Development Kit for Flutter applications.
library tan_sdk;

// Export Core package files directly
export 'package:core/main.dart';
export 'package:core/bases/base_client.dart';
export 'package:core/bases/data/api/exceptions/error.dart';
export 'package:core/keys/constants.dart';
export 'package:core/keys/sdk_config.dart';

// Export Core components
export 'package:core/components/button/app_button.dart';
export 'package:core/components/text/app_text.dart';
export 'package:core/components/loading/loading_widget.dart';
export 'package:core/components/card/card_widget.dart';

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

// Export presenter/scenes
export 'presenter/loan_conditions/scene/loan_conditions_screen.dart';
