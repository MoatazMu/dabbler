import 'package:dabbler/core/fp/failure.dart';
import 'package:dabbler/core/fp/result.dart';
import 'package:dabbler/data/models/venue_submission_model.dart';
import 'package:dabbler/data/repositories/venue_submission_repository.dart';

class CreateVenueSubmissionUseCase {
  final VenueSubmissionRepository _repository;

  const CreateVenueSubmissionUseCase(this._repository);

  Future<Result<VenueSubmissionModel, Failure>> call({
    required String organiserProfileId,
    required VenueSubmissionDraft draft,
  }) {
    return _repository.upsertDraft(
      organiserProfileId: organiserProfileId,
      draft: draft,
    );
  }
}
