import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failure.dart';
import '../../core/types/result.dart';
import '../../services/supabase/supabase_service.dart';
import '../models/profile.dart';
import 'base_repository.dart';
import 'profiles_repository.dart';

class ProfilesRepositoryImpl extends BaseRepository
    implements ProfilesRepository {
  ProfilesRepositoryImpl(super.svc);

  static const String _table = 'profiles';

  @override
  Future<Result<Profile>> getMyProfile() async {
    final uid = svc.authUserId();
    if (uid == null) {
      return failure(const AuthFailure(message: 'Not signed in'));
    }

    final result = await _fetchProfileOptional(uid);
    return result.fold(
      failure,
      (profile) => profile != null
          ? success(profile)
          : failure(const NotFoundFailure(message: 'Profile not found')),
    );
  }

  @override
  Future<Result<Profile>> getByUserId(String userId) async {
    final result = await _fetchProfileOptional(userId);
    return result.fold(
      failure,
      (profile) => profile != null
          ? success(profile)
          : failure(const NotFoundFailure(message: 'Profile not found')),
    );
  }

  @override
  Future<Result<Profile?>> getPublicByUsername(String username) {
    return guard(() async {
      final response = await svc.client
          .from(_table)
          .select()
          .eq('username', username)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Profile.fromJson(Map<String, dynamic>.from(response));
    });
  }

  @override
  Future<Result<void>> upsert(Profile profile) async {
    final uid = svc.authUserId();
    if (uid == null) {
      return failure(const AuthFailure(message: 'Not signed in'));
    }
    if (profile.userId != uid) {
      return failure(
        const PermissionFailure(
          message: "Cannot upsert another user's profile",
        ),
      );
    }

    return guard(() async {
      await svc.client.from(_table).upsert(profile.toJson()).eq('user_id', uid);
    });
  }

  @override
  Future<Result<void>> deactivateMe() async {
    final uid = svc.authUserId();
    if (uid == null) {
      return failure(const AuthFailure(message: 'Not signed in'));
    }

    return guard(() async {
      await svc.client
          .from(_table)
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', uid);
    });
  }

  @override
  Future<Result<void>> reactivateMe() async {
    final uid = svc.authUserId();
    if (uid == null) {
      return failure(const AuthFailure(message: 'Not signed in'));
    }

    return guard(() async {
      await svc.client
          .from(_table)
          .update({
            'is_active': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', uid);
    });
  }

  @override
  Stream<Result<Profile?>> watchMyProfile() {
    final uid = svc.authUserId();
    if (uid == null) {
      return Stream.value(failure(const AuthFailure(message: 'Not signed in')));
    }

    final controller = StreamController<Result<Profile?>>();
    final channel = svc.client.channel('public:$_table');

    void emit(Result<Profile?> result) {
      if (!controller.isClosed) {
        controller.add(result);
      }
    }

    Future<void> emitCurrentProfile() async {
      final result = await _fetchProfileOptional(uid);
      emit(result);
    }

    controller.onListen = () async {
      final initial = await getMyProfile();
      emit(initial.map((profile) => profile));

      channel.on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: '*',
          schema: 'public',
          table: _table,
          filter: 'user_id=eq.$uid',
        ),
        (payload, [ref]) async {
          await emitCurrentProfile();
        },
      );

      try {
        channel.subscribe();
      } catch (error) {
        emit(failure(svc.mapPostgrestError(error)));
      }
    };

    controller.onCancel = () async {
      await channel.unsubscribe();
      await svc.client.removeChannel(channel);
      await controller.close();
    };

    return controller.stream;
  }

  Future<Result<Profile?>> _fetchProfileOptional(String userId) {
    return guard(() async {
      final response = await svc.client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Profile.fromJson(Map<String, dynamic>.from(response));
    });
  }
}
