import 'package:dabbler/core/fp/failure.dart';
import 'package:dabbler/core/fp/result.dart';
import 'package:dabbler/data/models/venue_submission_model.dart';
import 'package:dabbler/data/repositories/venue_submission_repository.dart';

class SubmitVenueForReviewUseCase {
  final VenueSubmissionRepository _repository;

  const SubmitVenueForReviewUseCase(this._repository);

  Future<Result<VenueSubmissionModel, Failure>> call({
    required String submissionId,
  }) {
    return _repository.submitForReview(submissionId: submissionId);
  }
}
