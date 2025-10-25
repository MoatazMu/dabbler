import 'package:dabbler/core/result.dart';
import 'package:dabbler/data/models/sport_profile.dart';

/// Repository contract for managing sport profile preferences for the
/// currently authenticated user. Even though RLS is off, every operation
/// scopes queries to the active `auth.uid()` to remain future-proof once
/// policies are enforced.
abstract class SportProfilesRepository {
  /// List my sport preferences ordered by sport_key.
  Future<Result<List<SportProfile>>> getMySports();

  /// Get a single sport preference for me by sport_key.
  Future<Result<SportProfile?>> getMySportByKey(String sportKey);

  /// Add a sport preference for me. skillLevel must be 1..10 (constraint).
  Future<Result<void>> addMySport({
    required String sportKey,
    required int skillLevel,
  });

  /// Update my skillLevel for an existing sport_key.
  Future<Result<void>> updateMySport({
    required String sportKey,
    required int skillLevel,
  });

  /// Remove my sport preference (hard delete; no deleted_at column present).
  Future<Result<void>> removeMySport({
    required String sportKey,
  });

  /// Realtime stream of my preferences (composite PK uses user_id + sport_key).
  Stream<Result<List<SportProfile>>> watchMySports();
}
