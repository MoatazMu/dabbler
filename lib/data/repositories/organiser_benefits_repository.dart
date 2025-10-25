import '../../core/types/result.dart';
import '../models/benefit.dart';

abstract class OrganiserBenefitsRepository {
  /// Benefits available/applicable to the current user (organiser).
  Future<Result<List<Benefit>>> listMyBenefits();

  /// Fetch a single benefit by slug (RLS may still restrict).
  Future<Result<Benefit>> getBenefitBySlug(String slug);

  /// Admin-only: list all benefits (may return unauthorized for non-admins).
  Future<Result<List<Benefit>>> listAllBenefits({
    int limit = 100,
    int offset = 0,
  });
}
