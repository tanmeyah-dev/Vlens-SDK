import 'package:core/bases/base_client.dart';
import 'package:core/bases/data/api/exceptions/error.dart';
import 'package:core/keys/sdk_config.dart';
import '../../domain/repos/loan_repo.dart';
import '../models/loan_application.dart';

/// Repository implementation for loan operations.
class LoanRepoImp extends BaseClient implements LoanRepo {
  final SDKConfig config;
  bool _isInitialized = false;

  LoanRepoImp({required this.config});

  @override
  void initialize() {
    if (_isInitialized) {
      return;
    }

    if (config.baseUrl == null || config.baseUrl!.isEmpty) {
      throw const ConfigurationException('Base URL is required for LoanRepo');
    }

    _isInitialized = true;

    if (config.debug) {
      print('LoanRepo initialized successfully');
    }
  }

  @override
  void dispose() {
    _isInitialized = false;
    if (config.debug) {
      print('LoanRepo disposed');
    }
  }

  /// Checks if the service is initialized.
  bool get isInitialized => _isInitialized;

  @override
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

  @override
  Future<LoanApplication> getLoanStatus(String loanId) async {
    _ensureInitialized();

    try {
      // TODO: Replace with actual API call
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

  @override
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
        'LoanRepo is not initialized. Call initialize() first.',
        code: 'SERVICE_NOT_INITIALIZED',
      );
    }
  }
}

