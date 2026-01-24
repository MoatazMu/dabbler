import 'package:dabbler/core/fp/failure.dart';
import 'package:dabbler/core/fp/result.dart';
import 'package:dabbler/data/models/venue_submission_model.dart';

abstract class VenueSubmissionRepository {
  /// Creates a new submission in `draft` state, or updates an existing draft/returned.
  Future<Result<VenueSubmissionModel, Failure>> upsertDraft({
    required String organiserProfileId,
    required VenueSubmissionDraft draft,
  });

  /// Moves a submission from `draft/returned` to `pending`.
  Future<Result<VenueSubmissionModel, Failure>> submitForReview({
    required String submissionId,
  });

  /// Lists the current organiser's submissions.
  Future<Result<List<VenueSubmissionModel>, Failure>> listMine({
    required String organiserProfileId,
    int limit = 200,
  });

  /// Fetch a submission by id.
  Future<Result<VenueSubmissionModel, Failure>> getById(String id);
}
