import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dabbler/core/fp/failure.dart';
import 'package:dabbler/core/fp/result.dart';
import '../../services/supabase/supabase_service.dart';
import '../models/profile.dart';
import 'bench_mode_repository.dart';

class BenchModeRepositoryImpl implements BenchModeRepository {
  final SupabaseService svc;
  BenchModeRepositoryImpl(this.svc);

  SupabaseClient get _db => svc.client;

  Future<Map<String, dynamic>?> _findMyProfileRow(
    String uid,
    String type,
  ) async {
    final row = await _db
        .from('profiles')
        .select()
        .eq('user_id', uid)
        .eq('profile_type', type)
        .maybeSingle();

    if (row == null) {
      return null;
    }

    return Map<String, dynamic>.from(row);
  }

  @override
  Future<Result<Profile>> getMyProfileByType(String profileType) async {
    try {
      final uid = svc.authUserId();
      if (uid == null) {
        return left(const AuthFailure(message: 'Not signed in'));
      }

      final row = await _findMyProfileRow(uid, profileType);
      if (row == null) {
        return left(
          NotFoundFailure(
            message: 'Profile ($profileType) not found for current user',
          ),
        );
      }
      return right(Profile.fromJson(row));
    } catch (e) {
      return left(svc.mapPostgrestError(e));
    }
  }

  @override
  Future<Result<bool>> isMyProfileActive(String profileType) async {
    try {
      final uid = svc.authUserId();
      if (uid == null) {
        return left(const AuthFailure(message: 'Not signed in'));
      }
      final row = await _db
          .from('profiles')
          .select('is_active')
          .eq('user_id', uid)
          .eq('profile_type', profileType)
          .maybeSingle();
      if (row == null) {
        return left(
          NotFoundFailure(
            message: 'Profile ($profileType) not found for current user',
          ),
        );
      }
      return right((row['is_active'] as bool?) ?? false);
    } catch (e) {
      return left(svc.mapPostgrestError(e));
    }
  }

  @override
  Future<Result<Profile>> benchMyProfile(String profileType) async {
    try {
      final uid = svc.authUserId();
      if (uid == null) {
        return left(const AuthFailure(message: 'Not signed in'));
      }
      final now = DateTime.now().toIso8601String();
      final row = await _db
          .from('profiles')
          .update({'is_active': false, 'updated_at': now})
          .eq('user_id', uid)
          .eq('profile_type', profileType)
          .select()
          .maybeSingle();
      if (row == null) {
        return left(
          NotFoundFailure(
            message: 'Profile ($profileType) not found or not owned',
          ),
        );
      }
      return right(Profile.fromJson(Map<String, dynamic>.from(row)));
    } catch (e) {
      return left(svc.mapPostgrestError(e));
    }
  }

  @override
  Future<Result<Profile>> unbenchMyProfile(String profileType) async {
    try {
      final uid = svc.authUserId();
      if (uid == null) {
        return left(const AuthFailure(message: 'Not signed in'));
      }
      final now = DateTime.now().toIso8601String();
      final row = await _db
          .from('profiles')
          .update({'is_active': true, 'updated_at': now})
          .eq('user_id', uid)
          .eq('profile_type', profileType)
          .select()
          .maybeSingle();
      if (row == null) {
        return left(
          NotFoundFailure(
            message: 'Profile ($profileType) not found or not owned',
          ),
        );
      }
      return right(Profile.fromJson(Map<String, dynamic>.from(row)));
    } catch (e) {
      return left(svc.mapPostgrestError(e));
    }
  }

  @override
  Stream<Result<Profile>> myProfileStream(String profileType) async* {
    try {
      final uid = svc.authUserId();
      if (uid == null) {
        yield left(const AuthFailure(message: 'Not signed in'));
        return;
      }

      Future<Result<Profile>> fetch() async {
        try {
          final row = await _findMyProfileRow(uid, profileType);
          if (row == null) {
            return left(
              NotFoundFailure(message: 'Profile ($profileType) not found'),
            );
          }
          return right(Profile.fromJson(row));
        } catch (e) {
          return left(svc.mapPostgrestError(e));
        }
      }

      // Initial emit
      yield await fetch();

      // Realtime stream, scoped to my profile/type
      final stream = _db.from('profiles').stream(primaryKey: ['id']);

      await for (final _ in stream) {
        yield await fetch();
      }
    } catch (e) {
      yield left(svc.mapPostgrest(e as PostgrestException));
    }
  }
}
