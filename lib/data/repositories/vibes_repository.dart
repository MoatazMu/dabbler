import '../../core/types/result.dart';
import '../models/vibe.dart';

abstract class VibesRepository {
  /// Read vibes configured for a post (RLS ensures the viewer can see the post).
  Future<Result<List<Vibe>>> getVibesForPost(String postId);

  /// Upsert a vibe for a post.
  /// RLS: only post author (or admin) can write.
  Future<Result<Vibe>> upsertVibe(Vibe vibe);

  /// Delete a vibe by id (RLS enforced).
  Future<Result<void>> deleteVibe(String id);

  /// Optional: update multiple sort orders atomically when supported.
  Future<Result<void>> reorder(String postId, List<Vibe> ordered);
}
