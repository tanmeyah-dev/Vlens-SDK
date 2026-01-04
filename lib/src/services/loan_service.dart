import '../config/sdk_config.dart';
import '../core/base_client.dart';
import '../exceptions/sdk_exception.dart';
import '../models/loan_application.dart';

/// Service for handling loan application operations and API calls.
///
/// This service handles all loan-related API calls including:
/// - Creating loan applications
/// - Fetching loan status
/// - Updating loan information
class LoanService extends BaseClient {
  final SDKConfig config;
  bool _isInitialized = false;

  LoanService({required this.config});

  @override
  void initialize() {
    if (_isInitialized) {
      return;
    }

    if (config.baseUrl == null || config.baseUrl!.isEmpty) {
      throw const ConfigurationException(
          'Base URL is required for LoanService');
    }

    _isInitialized = true;

    if (config.debug) {
      print('LoanService initialized successfully');
    }
  }

  @override
  void dispose() {
    _isInitialized = false;
    if (config.debug) {
      print('LoanService disposed');
    }
  }

  /// Checks if the service is initialized.
  bool get isInitialized => _isInitialized;

  /// Creates a new loan application.
  ///
  /// [application] - The loan application data to submit
  ///
  /// Returns the created [LoanApplication] with server-assigned ID
  ///
  /// Throws [OperationException] if the API call fails
  Future<LoanApplication> createLoanApplication(
      LoanApplication application) async {
    _ensureInitialized();

    try {
      // TODO: Replace with actual API call
      // Example API call structure:
      /*
      final response = await http.post(
        Uri.parse('${config.baseUrl}/api/loans'),
        headers: {
          'Content-Type': 'application/json',
          if (config.apiKey != null) 'Authorization': 'Bearer ${config.apiKey}',
        },
        body: jsonEncode(application.toJson()),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return LoanApplication.fromJson(jsonDecode(response.body));
      } else {
        throw OperationException(
          'Failed to create loan application: ${response.statusCode}',
          code: 'LOAN_CREATE_FAILED',
        );
      }
      */

      // Mock implementation for now
      if (config.debug) {
        print('Creating loan application: ${application.toJson()}');
      }

      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));

      // Return mock response
      return application.copyWith(
        id: 'loan_${DateTime.now().millisecondsSinceEpoch}',
        status: 'submitted',
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw OperationException(
        'Failed to create loan application: $e',
        code: 'LOAN_CREATE_ERROR',
        originalError: e,
      );
    }
  }

  /// Fetches loan application status by ID.
  ///
  /// [loanId] - The ID of the loan application
  ///
  /// Returns the [LoanApplication] with current status
  ///
  /// Throws [OperationException] if the API call fails
  Future<LoanApplication> getLoanStatus(String loanId) async {
    _ensureInitialized();

    try {
      // TODO: Replace with actual API call
      /*
      final response = await http.get(
        Uri.parse('${config.baseUrl}/api/loans/$loanId'),
        headers: {
          if (config.apiKey != null) 'Authorization': 'Bearer ${config.apiKey}',
        },
      );
      
      if (response.statusCode == 200) {
        return LoanApplication.fromJson(jsonDecode(response.body));
      } else {
        throw OperationException(
          'Failed to fetch loan status: ${response.statusCode}',
          code: 'LOAN_FETCH_FAILED',
        );
      }
      */

      // Mock implementation
      if (config.debug) {
        print('Fetching loan status for: $loanId');
      }

      await Future.delayed(const Duration(milliseconds: 500));

      throw const OperationException(
        'Loan not found',
        code: 'LOAN_NOT_FOUND',
      );
    } catch (e) {
      if (e is OperationException) {
        rethrow;
      }
      throw OperationException(
        'Failed to fetch loan status: $e',
        code: 'LOAN_FETCH_ERROR',
        originalError: e,
      );
    }
  }

  /// Validates loan application eligibility.
  ///
  /// [age] - Applicant's age
  /// [hasExistingProject] - Whether applicant has existing project
  /// [projectMonths] - Number of months project has been running
  ///
  /// Returns true if eligible, false otherwise
  Future<bool> validateEligibility({
    required int age,
    required bool hasExistingProject,
    required int projectMonths,
  }) async {
    _ensureInitialized();

    // Business logic validation
    if (age < 21 || age > 65) {
      return false;
    }

    if (!hasExistingProject) {
      return false;
    }

    if (projectMonths < 6) {
      return false;
    }

    return true;
  }

  /// Ensures the service is initialized before use.
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw const OperationException(
        'LoanService is not initialized. Call initialize() first.',
        code: 'SERVICE_NOT_INITIALIZED',
      );
    }
  }
}
