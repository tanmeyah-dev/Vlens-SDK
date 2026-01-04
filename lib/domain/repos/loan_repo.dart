import '../../data/models/loan_application.dart';

/// Repository interface for loan operations.
abstract class LoanRepo {
  /// Creates a new loan application.
  Future<LoanApplication> createLoanApplication(LoanApplication application);

  /// Fetches loan application status by ID.
  Future<LoanApplication> getLoanStatus(String loanId);

  /// Validates loan application eligibility.
  Future<bool> validateEligibility({
    required int age,
    required bool hasExistingProject,
    required int projectMonths,
  });
}

