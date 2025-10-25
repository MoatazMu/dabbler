import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/failures.dart';
import '../../core/types/result.dart';
import '../../services/supabase/supabase_service.dart';
import '../models/venue_space.dart';
import 'base_repository.dart';
import 'venue_config_repository.dart';

class VenueConfigRepositoryImpl extends BaseRepository
    implements VenueConfigRepository {
  VenueConfigRepositoryImpl(SupabaseService service) : super(service);

  static const String _spacesTable = 'venue_spaces';
  static const String _hoursTable = 'opening_hours';
  static const String _pricesTable = 'space_prices';

  @override
  Future<Result<List<VenueSpace>>> listSpaces({
    required String venueId,
    bool onlyActive = true,
    int limit = 100,
    String? nameLike,
  }) async {
    try {
      PostgrestFilterBuilder<Map<String, dynamic>> query = svc
          .from(_spacesTable)
          .select('id,venue_id,name,description,is_active,created_at')
          .eq('venue_id', venueId);

      if (onlyActive) {
        query = query.eq('is_active', true);
      }

      final trimmed = nameLike?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        query = query.ilike('name', '%$trimmed%');
      }

      query = query.order('name', ascending: true).limit(limit);

      final rows = await svc.getList(query);
      final spaces = rows
          .map((row) => VenueSpace.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false);
      return right(spaces);
    } catch (error, stackTrace) {
      return left(_mapError(error, stackTrace: stackTrace));
    }
  }

  @override
  Future<Result<VenueSpace>> getSpace(String id) async {
    try {
      final data = await svc.maybeSingle(
        svc
            .from(_spacesTable)
            .select('id,venue_id,name,description,is_active,created_at')
            .eq('id', id)
            .single(),
      );

      if (data == null) {
        return left(NotFoundFailure(message: 'Venue space $id not found'));
      }

      return right(VenueSpace.fromJson(data));
    } catch (error, stackTrace) {
      return left(_mapError(error, stackTrace: stackTrace));
    }
  }

  @override
  Future<Result<VenueSpace>> upsertSpace({
    String? id,
    required String venueId,
    required String name,
    String? description,
    bool? isActive,
  }) async {
    final payload = <String, dynamic>{
      'venue_id': venueId,
      'name': name,
      if (description != null) 'description': description,
      if (isActive != null) 'is_active': isActive,
    };

    try {
      if (id == null) {
        final data = await svc.maybeSingle(
          svc
              .from(_spacesTable)
              .insert(payload)
              .select('id,venue_id,name,description,is_active,created_at')
              .single(),
        );

        if (data == null) {
          return left(
            const UnknownFailure(message: 'Failed to insert venue space'),
          );
        }

        return right(VenueSpace.fromJson(data));
      }

      final updatePayload = Map<String, dynamic>.from(payload)
        ..remove('venue_id');

      final data = await svc.maybeSingle(
        svc
            .from(_spacesTable)
            .update(updatePayload)
            .eq('id', id)
            .select('id,venue_id,name,description,is_active,created_at')
            .single(),
      );

      if (data == null) {
        return left(NotFoundFailure(message: 'Venue space $id not found'));
      }

      return right(VenueSpace.fromJson(data));
    } catch (error, stackTrace) {
      return left(_mapError(error, stackTrace: stackTrace));
    }
  }

  @override
  Future<Result<void>> archiveOrDeleteSpace(String id) async {
    try {
      final response = await svc
          .from(_spacesTable)
          .update({'is_active': false})
          .eq('id', id);

      if (response is List && response.isEmpty) {
        return left(NotFoundFailure(message: 'Venue space $id not found'));
      }

      return right(null);
    } on PostgrestException catch (error, stackTrace) {
      if (_isMissingIsActiveColumn(error)) {
        try {
          final deleted = await svc.from(_spacesTable).delete().eq('id', id);
          if (deleted is List && deleted.isEmpty) {
            return left(NotFoundFailure(message: 'Venue space $id not found'));
          }
          return right(null);
        } catch (deleteError, deleteStack) {
          return left(_mapError(deleteError, stackTrace: deleteStack));
        }
      }
      return left(_mapError(error, stackTrace: stackTrace));
    } catch (error, stackTrace) {
      return left(_mapError(error, stackTrace: stackTrace));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> listOpeningHours({
    required String venueSpaceId,
  }) async {
    try {
      final rows = await svc.getList(
        svc
            .from(_hoursTable)
            .select('id,venue_space_id,day_of_week,opens_at,closes_at')
            .eq('venue_space_id', venueSpaceId)
            .order('day_of_week', ascending: true),
      );

      final hours = rows
          .map((row) => _OpeningHour.fromJson(row).toMap())
          .toList(growable: false);
      return right(hours);
    } catch (error, stackTrace) {
      return left(_mapError(error, stackTrace: stackTrace));
    }
  }

  @override
  Future<Result<void>> replaceOpeningHours({
    required String venueSpaceId,
    required List<Map<String, dynamic>> hours,
  }) async {
    try {
      await svc
          .from(_hoursTable)
          .delete()
          .eq('venue_space_id', venueSpaceId);

      if (hours.isEmpty) {
        return right(null);
      }

      final payload = hours
          .map((hour) => _OpeningHour.fromMap(venueSpaceId, hour).toJson())
          .toList(growable: false);

      await svc.from(_hoursTable).insert(payload);

      return right(null);
    } catch (error, stackTrace) {
      return left(_mapError(error, stackTrace: stackTrace));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> listPrices({
    required String venueSpaceId,
    bool onlyActive = true,
    int? limit,
  }) async {
    try {
      PostgrestFilterBuilder<Map<String, dynamic>> query = svc
          .from(_pricesTable)
          .select(
            'id,venue_space_id,label,amount_cents,currency,unit,is_active,created_at',
          )
          .eq('venue_space_id', venueSpaceId)
          .order('amount_cents', ascending: true);

      if (onlyActive) {
        query = query.eq('is_active', true);
      }
      if (limit != null) {
        query = query.limit(limit);
      }

      final rows = await svc.getList(query);
      final prices = rows
          .map((row) => _SpacePrice.fromJson(row).toMap())
          .toList(growable: false);
      return right(prices);
    } catch (error, stackTrace) {
      return left(_mapError(error, stackTrace: stackTrace));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> upsertPrice({
    String? id,
    required String venueSpaceId,
    required String label,
    required int amountCents,
    required String currency,
    required String unit,
    bool? isActive,
  }) async {
    final payload = <String, dynamic>{
      'venue_space_id': venueSpaceId,
      'label': label,
      'amount_cents': amountCents,
      'currency': currency,
      'unit': unit,
      if (isActive != null) 'is_active': isActive,
    };

    try {
      final PostgrestFilterBuilder<Map<String, dynamic>> mutation;
      if (id == null) {
        mutation = svc
            .from(_pricesTable)
            .insert(payload)
            .select(
              'id,venue_space_id,label,amount_cents,currency,unit,is_active,created_at',
            )
            .single();
      } else {
        final updatePayload = Map<String, dynamic>.from(payload)
          ..remove('venue_space_id');
        mutation = svc
            .from(_pricesTable)
            .update(updatePayload)
            .eq('id', id)
            .select(
              'id,venue_space_id,label,amount_cents,currency,unit,is_active,created_at',
            )
            .single();
      }

      final data = await svc.maybeSingle(mutation);
      if (data == null) {
        return left(
          id == null
              ? const UnknownFailure(message: 'Failed to insert price')
              : NotFoundFailure(message: 'Price $id not found'),
        );
      }

      final price = _SpacePrice.fromJson(data).toMap();
      return right(price);
    } catch (error, stackTrace) {
      return left(_mapError(error, stackTrace: stackTrace));
    }
  }

  @override
  Future<Result<void>> deletePrice(String id) async {
    try {
      final response = await svc.from(_pricesTable).delete().eq('id', id);
      if (response is List && response.isEmpty) {
        return left(NotFoundFailure(message: 'Price $id not found'));
      }
      return right(null);
    } catch (error, stackTrace) {
      return left(_mapError(error, stackTrace: stackTrace));
    }
  }

  Failure _mapError(Object error, {StackTrace? stackTrace}) {
    return svc.mapPostgrestError(error, stackTrace: stackTrace);
  }

  bool _isMissingIsActiveColumn(PostgrestException error) {
    if (error.code == '42703') {
      return true;
    }
    final message = error.message?.toLowerCase() ?? '';
    return message.contains('is_active');
  }
}

class _OpeningHour {
  _OpeningHour({
    this.id,
    required this.venueSpaceId,
    required this.dayOfWeek,
    required this.opensAt,
    required this.closesAt,
  });

  factory _OpeningHour.fromJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    return _OpeningHour(
      id: map['id'] as String?,
      venueSpaceId: map['venue_space_id'] as String,
      dayOfWeek: map['day_of_week'] as int,
      opensAt: map['opens_at'] as String,
      closesAt: map['closes_at'] as String,
    );
  }

  factory _OpeningHour.fromMap(
    String venueSpaceId,
    Map<String, dynamic> data,
  ) {
    return _OpeningHour(
      id: data['id'] as String?,
      venueSpaceId: venueSpaceId,
      dayOfWeek: data['dayOfWeek'] as int,
      opensAt: data['opensAt'] as String,
      closesAt: data['closesAt'] as String,
    );
  }

  final String? id;
  final String venueSpaceId;
  final int dayOfWeek;
  final String opensAt;
  final String closesAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'venue_space_id': venueSpaceId,
      'day_of_week': dayOfWeek,
      'opens_at': opensAt,
      'closes_at': closesAt,
    };
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'venueSpaceId': venueSpaceId,
      'dayOfWeek': dayOfWeek,
      'opensAt': opensAt,
      'closesAt': closesAt,
    };
  }
}

class _SpacePrice {
  _SpacePrice({
    required this.id,
    required this.venueSpaceId,
    required this.label,
    required this.amountCents,
    required this.currency,
    required this.unit,
    required this.isActive,
    required this.createdAt,
  });

  factory _SpacePrice.fromJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    return _SpacePrice(
      id: map['id'] as String,
      venueSpaceId: map['venue_space_id'] as String,
      label: map['label'] as String,
      amountCents: map['amount_cents'] as int,
      currency: map['currency'] as String,
      unit: map['unit'] as String,
      isActive: map['is_active'] as bool,
      createdAt: _parseDateTime(map['created_at']),
    );
  }

  final String id;
  final String venueSpaceId;
  final String label;
  final int amountCents;
  final String currency;
  final String unit;
  final bool isActive;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'venue_space_id': venueSpaceId,
      'label': label,
      'amount_cents': amountCents,
      'currency': currency,
      'unit': unit,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'venueSpaceId': venueSpaceId,
      'label': label,
      'amountCents': amountCents,
      'currency': currency,
      'unit': unit,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
}

DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.parse(value);
  }
  throw ArgumentError('Unsupported date value: $value');
}
