import 'package:core/bases/base_client.dart';
import 'package:core/keys/sdk_config.dart';
import '../data/repo_imp/loan_repo_imp.dart';
import '../domain/repos/loan_repo.dart';
import '../data/models/loan_application.dart';

/// Service for handling loan application operations.
///
/// This is a convenience wrapper around LoanRepo that maintains backward compatibility.
class LoanService extends BaseClient {
  late final LoanRepo _loanRepo;
  final SDKConfig config;

  LoanService({required this.config}) {
    _loanRepo = LoanRepoImp(config: config);
  }

  @override
  void initialize() {
    if (_loanRepo is LoanRepoImp) {
      (_loanRepo as LoanRepoImp).initialize();
    }
  }

  @override
  void dispose() {
    if (_loanRepo is LoanRepoImp) {
      (_loanRepo as LoanRepoImp).dispose();
    }
  }

  /// Gets the loan repository.
  LoanRepo get loanRepo => _loanRepo;

  /// Creates a new loan application.
  Future<LoanApplication> createLoanApplication(LoanApplication application) async {
    return await _loanRepo.createLoanApplication(application);
  }

  /// Fetches loan application status by ID.
  Future<LoanApplication> getLoanStatus(String loanId) async {
    return await _loanRepo.getLoanStatus(loanId);
  }

  /// Validates loan application eligibility.
  Future<bool> validateEligibility({
    required int age,
    required bool hasExistingProject,
    required int projectMonths,
  }) async {
    return await _loanRepo.validateEligibility(
      age: age,
      hasExistingProject: hasExistingProject,
      projectMonths: projectMonths,
    );
  }
}

