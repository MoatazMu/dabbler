import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/failure.dart';
import '../../core/types/result.dart';
import '../../services/supabase_service.dart';
import '../models/vibe.dart';
import 'base_repository.dart';
import 'vibes_repository.dart';

class VibesRepositoryImpl extends BaseRepository implements VibesRepository {
  VibesRepositoryImpl(SupabaseService service) : super(service);

  SupabaseClient get _client => svc.client;

  static const _table = 'post_vibes';

  @override
  Future<Result<List<Vibe>>> getVibesForPost(String postId) {
    return guard(() async {
      _assertSignedIn();

      final response = await _client
          .from(_table)
          .select(
              'id, post_id, key, label, emoji, sort_order, created_at')
          .eq('post_id', postId)
          .order('sort_order', ascending: true)
          .order('id', ascending: true);

      final data = response as List<dynamic>;

      return data
          .map((dynamic row) => Vibe.fromJson(
                Map<String, dynamic>.from(row as Map<String, dynamic>),
              ))
          .toList();
    });
  }

  @override
  Future<Result<Vibe>> upsertVibe(Vibe vibe) {
    return guard(() async {
      _assertSignedIn();

      final payload = <String, dynamic>{
        'id': vibe.id,
        'post_id': vibe.postId,
        if (vibe.key != null) 'key': vibe.key,
        if (vibe.label != null) 'label': vibe.label,
        if (vibe.emoji != null) 'emoji': vibe.emoji,
        'sort_order': vibe.sortOrder,
      };

      final result = await _client
          .from(_table)
          .upsert(payload, onConflict: 'id')
          .select(
              'id, post_id, key, label, emoji, sort_order, created_at')
          .single();

      return Vibe.fromJson(
          Map<String, dynamic>.from(result as Map<String, dynamic>));
    });
  }

  @override
  Future<Result<void>> deleteVibe(String id) {
    return guard(() async {
      _assertSignedIn();
      await _client.from(_table).delete().eq('id', id);
      return null;
    });
  }

  @override
  Future<Result<void>> reorder(String postId, List<Vibe> ordered) {
    return guard(() async {
      _assertSignedIn();

      for (var i = 0; i < ordered.length; i++) {
        final vibe = ordered[i];
        await _client
            .from(_table)
            .update({'sort_order': i})
            .eq('id', vibe.id)
            .eq('post_id', postId);
      }

      return null;
    });
  }

  void _assertSignedIn() {
    if (_client.auth.currentUser?.id == null) {
      throw const AuthFailure('Not signed in');
    }
  }
}
