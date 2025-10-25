import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/failures.dart';
import '../../core/result.dart';
import '../../services/supabase_service.dart';
import '../models/profile.dart';
import 'username_repository.dart';

class UsernameRepositoryImpl implements UsernameRepository {
  UsernameRepositoryImpl(this.svc);

  final SupabaseService svc;

  PostgrestClient get _db => svc.client;

  @override
  Future<Result<bool>> isAvailable(String username) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      return right(true);
    }
    try {
      final row = await _db
          .from('profiles')
          .select('id')
          .eq('username', trimmed)
          .maybeSingle();
      return right(row == null);
    } catch (error) {
      return left(svc.mapPostgrestError(error));
    }
  }

  @override
  Future<Result<Profile>> getByUsername(String username) async {
    try {
      final row = await _db
          .from('profiles')
          .select()
          .eq('username', username.trim())
          .maybeSingle();
      if (row == null) {
        return left(
          const NotFoundFailure(message: 'Username not found'),
        );
      }
      return right(
        Profile.fromJson(
          Map<String, dynamic>.from(row as Map<String, dynamic>),
        ),
      );
    } catch (error) {
      return left(svc.mapPostgrestError(error));
    }
  }

  @override
  Future<Result<List<Profile>>> search({
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var builder = _db.from('profiles').select();
      final trimmed = query.trim();
      if (trimmed.isNotEmpty) {
        builder = builder.ilike('username', '%$trimmed%');
      }
      builder = builder
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      final data = await builder;
      final rows = (data as List<dynamic>)
          .map(
            (row) => Profile.fromJson(
              Map<String, dynamic>.from(row as Map<String, dynamic>),
            ),
          )
          .toList(growable: false);
      return right(rows);
    } catch (error) {
      return left(svc.mapPostgrestError(error));
    }
  }

  @override
  Future<Result<Profile>> setUsernameForProfile({
    required String profileId,
    required String username,
  }) async {
    final trimmed = username.trim();
    try {
      final row = await _db
          .from('profiles')
          .update({'username': trimmed})
          .eq('id', profileId)
          .select()
          .maybeSingle();
      if (row == null) {
        return left(
          const NotFoundFailure(
            message: 'Profile not found or not owned',
          ),
        );
      }
      return right(
        Profile.fromJson(
          Map<String, dynamic>.from(row as Map<String, dynamic>),
        ),
      );
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        return left(
          const ConflictFailure(message: 'Username already taken'),
        );
      }
      return left(svc.mapPostgrestError(error));
    } catch (error) {
      return left(svc.mapPostgrestError(error));
    }
  }

  @override
  Future<Result<Profile>> setMyUsernameForType({
    required String profileType,
    required String username,
  }) async {
    final uid = svc.authUserId();
    if (uid == null) {
      return left(
        const AuthFailure(message: 'Not authenticated'),
      );
    }
    final trimmed = username.trim();
    try {
      final profileRow = await _db
          .from('profiles')
          .select('id')
          .eq('user_id', uid)
          .eq('profile_type', profileType)
          .maybeSingle();
      if (profileRow == null) {
        return left(
          NotFoundFailure(
            message: 'Profile of type $profileType not found for current user',
          ),
        );
      }
      final profileMap = Map<String, dynamic>.from(
        profileRow as Map<String, dynamic>,
      );
      final profileId = profileMap['id'] as String;
      final row = await _db
          .from('profiles')
          .update({'username': trimmed})
          .eq('id', profileId)
          .select()
          .maybeSingle();
      if (row == null) {
        return left(
          const NotFoundFailure(message: 'Profile not found after update'),
        );
      }
      return right(
        Profile.fromJson(
          Map<String, dynamic>.from(row as Map<String, dynamic>),
        ),
      );
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        return left(
          const ConflictFailure(message: 'Username already taken'),
        );
      }
      return left(svc.mapPostgrestError(error));
    } catch (error) {
      return left(svc.mapPostgrestError(error));
    }
  }

  @override
  Stream<Result<Profile>> myProfileTypeStream(String profileType) async* {
    final uid = svc.authUserId();
    if (uid == null) {
      yield left(const AuthFailure(message: 'Not authenticated'));
      return;
    }
    try {
      final stream = _db
          .from('profiles')
          .stream(primaryKey: ['id'])
          .eq('user_id', uid)
          .eq('profile_type', profileType);

      await for (final rows in stream) {
        if (rows.isEmpty) {
          yield left(const NotFoundFailure(message: 'Profile not found'));
          continue;
        }
        final map = Map<String, dynamic>.from(
          rows.first as Map<String, dynamic>,
        );
        yield right(Profile.fromJson(map));
      }
    } catch (error) {
      yield left(svc.mapPostgrestError(error));
    }
  }
}
