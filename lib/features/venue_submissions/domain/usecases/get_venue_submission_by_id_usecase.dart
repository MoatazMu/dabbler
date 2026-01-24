import 'package:dabbler/core/fp/failure.dart';
import 'package:dabbler/core/fp/result.dart';
import 'package:dabbler/data/models/venue_submission_model.dart';
import 'package:dabbler/data/repositories/venue_submission_repository.dart';

class GetVenueSubmissionByIdUseCase {
  final VenueSubmissionRepository _repository;

  const GetVenueSubmissionByIdUseCase(this._repository);

  Future<Result<VenueSubmissionModel, Failure>> call(String id) {
    return _repository.getById(id);
  }
}
