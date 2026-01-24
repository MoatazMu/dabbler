import 'package:dabbler/core/fp/failure.dart';
import 'package:dabbler/core/fp/result.dart';
import 'package:dabbler/data/models/venue_submission_model.dart';
import 'package:dabbler/data/repositories/venue_submission_repository.dart';

class GetMyVenueSubmissionsUseCase {
  final VenueSubmissionRepository _repository;

  const GetMyVenueSubmissionsUseCase(this._repository);

  Future<Result<List<VenueSubmissionModel>, Failure>> call({
    required String organiserProfileId,
    int limit = 200,
  }) {
    return _repository.listMine(
      organiserProfileId: organiserProfileId,
      limit: limit,
    );
  }
}
