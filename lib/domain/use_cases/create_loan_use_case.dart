import '../../data/models/loan_application.dart';
import '../repos/loan_repo.dart';

/// Use case for creating a loan application.
class CreateLoanUseCase {
  final LoanRepo loanRepo;

  CreateLoanUseCase(this.loanRepo);

  Future<LoanApplication> call(LoanApplication application) async {
    return await loanRepo.createLoanApplication(application);
  }
}

