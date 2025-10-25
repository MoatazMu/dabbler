import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';
import '../../core/types/result.dart';
import '../../core/error/failure.dart';
import 'base_repository.dart';
import 'organiser_benefits_repository.dart';
import '../models/benefit.dart';

class OrganiserBenefitsRepositoryImpl extends BaseRepository
    implements OrganiserBenefitsRepository {
  final SupabaseService service;
  OrganiserBenefitsRepositoryImpl(this.service);

  SupabaseClient get client => service.client;

  void _assertSignedIn() {
    if (client.auth.currentUser?.id == null) {
      throw Failure.unauthorized(message: 'Not signed in');
    }
  }

  @override
  Future<Result<List<Benefit>>> listMyBenefits() {
    return guard(() async {
      _assertSignedIn();
      final res = await client.rpc('organiser_benefits_for_me');
      final list = (res as List<dynamic>? ?? const []);
      return list
          .map((e) => Benefit.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    });
  }

  @override
  Future<Result<Benefit>> getBenefitBySlug(String slug) {
    return guard(() async {
      _assertSignedIn();
      if (slug.trim().isEmpty) {
        throw Failure.unknown(message: 'Empty benefit slug');
      }
      final res = await client.rpc(
        'organiser_benefit_by_slug',
        params: {'slug': slug},
      );
      if (res == null) {
        throw Failure.notFound(message: 'Benefit not found');
      }
      return Benefit.fromJson(Map<String, dynamic>.from(res as Map));
    });
  }

  @override
  Future<Result<List<Benefit>>> listAllBenefits({
    int limit = 100,
    int offset = 0,
  }) {
    return guard(() async {
      _assertSignedIn();
      final res = await client.rpc(
        'organiser_benefits_all',
        params: {'limit': limit, 'offset': offset},
      );
      final list = (res as List<dynamic>? ?? const []);
      return list
          .map((e) => Benefit.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    });
  }
}
