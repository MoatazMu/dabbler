import 'package:fpdart/fpdart.dart';
import 'package:riverpod/riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/types/result.dart';
import '../../services/supabase/supabase_service.dart';
import 'base_repository.dart';
import 'visibility_repository.dart';

final visibilityRepositoryProvider = Provider<VisibilityRepository>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return VisibilityRepositoryImpl(service);
});

class VisibilityRepositoryImpl extends BaseRepository
    implements VisibilityRepository {
  VisibilityRepositoryImpl(super.svc);

  @override
  Future<Result<bool>> canViewOwner({
    required String ownerId,
    required String visibility,
  }) async {
    final viewer = svc.authUserId();
    if (viewer == null) {
      return right(false);
    }

    if (viewer == ownerId) {
      return right(true);
    }

    final adminResult = await isAdmin();
    final isViewerAdmin = adminResult.fold((_) => false, (value) => value);
    if (isViewerAdmin) {
      return right(true);
    }

    switch (visibility) {
      case 'public':
        return right(true);
      case 'hidden':
        return right(false);
      case 'circle':
        final syncedResult = await areSynced(ownerId);
        return syncedResult.fold(
          (_) => right(false),
          (isSynced) => right(isSynced),
        );
      default:
        return right(false);
    }
  }

  @override
  Future<Result<bool>> canReadRow({
    required String ownerId,
    required String visibility,
  }) {
    return canViewOwner(ownerId: ownerId, visibility: visibility);
  }

  @override
  Future<Result<bool>> areSynced(String otherUserId) async {
    final viewer = svc.authUserId();
    if (viewer == null) {
      return right(false);
    }

    try {
      final response = await svc.client
          .from('friendships')
          .select('status')
          .or(
            'and(user_id.eq.$viewer,peer_user_id.eq.$otherUserId),'
            'and(user_id.eq.$otherUserId,peer_user_id.eq.$viewer)',
          )
          .in_('status', ['accepted', 'pending'])
          .limit(1)
          .maybeSingle();

      return right(response != null);
    } on PostgrestException {
      return right(false);
    } catch (_) {
      return right(false);
    }
  }

  @override
  Future<Result<bool>> isAdmin() async {
    final userId = svc.authUserId();
    if (userId == null) {
      return right(false);
    }

    try {
      final response = await svc.client
          .from('app_admins')
          .select('user_id')
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();

      return right(response != null);
    } on PostgrestException {
      return right(false);
    } catch (_) {
      return right(false);
    }
  }
}
