import 'package:dabbler/data/models/games/game.dart';

class GameModel extends Game {
  const GameModel({
    required super.id,
    required super.title,
    required super.description,
    required super.sport,
    super.venueId,
    super.venueName,
    required super.scheduledDate,
    required super.startTime,
    required super.endTime,
    required super.minPlayers,
    required super.maxPlayers,
    required super.currentPlayers,
    required super.organizerId,
    required super.skillLevel,
    required super.pricePerPlayer,
    super.currency,
    required super.status,
    required super.isPublic,
    required super.allowsWaitlist,
    required super.checkInEnabled,
    super.cancellationDeadline,
    required super.createdAt,
    required super.updatedAt,
  });

  factory GameModel.fromJson(Map<String, dynamic> json) {
    try {
      return GameModel(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Untitled Game',
        description: json['description'] as String? ?? '',
        sport: json['sport'] as String? ?? 'football',
        venueId: json['venue_id'] as String?,
        venueName: _parseVenueName(json), // Parse from JOIN or direct field
        scheduledDate: _parseDate(
          json['start_at'],
        ), // Changed from scheduled_date to start_at
        startTime: json['start_time'] as String? ?? '09:00',
        endTime: json['end_time'] as String? ?? '10:00',
        minPlayers: json['min_players'] as int? ?? 2,
        maxPlayers:
            json['max_players'] as int? ?? 10, // Added default for null safety
        currentPlayers: json['current_players'] as int? ?? 0,
        organizerId:
            json['host_user_id'] as String? ??
                '', // Changed from organizer_id to host_user_id
        skillLevel: json['skill_level'] as String? ?? 'beginner',
        pricePerPlayer: (json['price_per_player'] as num?)?.toDouble() ?? 0.0,
        currency: json['currency'] as String? ?? 'USD',
        status: _parseGameStatusFromIsCancelled(
          json,
        ), // Changed to parse from is_cancelled
        isPublic: json['is_public'] as bool? ?? true,
        allowsWaitlist: json['allows_waitlist'] as bool? ?? false,
        checkInEnabled: json['check_in_enabled'] as bool? ?? false,
        cancellationDeadline: json['cancellation_deadline'] != null
            ? _parseDate(json['cancellation_deadline'])
            : null,
        createdAt: _parseDate(json['created_at'] ?? DateTime.now().toIso8601String()),
        updatedAt: _parseDate(json['updated_at'] ?? DateTime.now().toIso8601String()),
      );
    } catch (e, stackTrace) {
      print('❌ [GameModel] fromJson: Failed to parse game data. Error: $e');
      print('Stack trace: $stackTrace');
      print('JSON data: $json');
      rethrow; // Re-throw after logging for debugging
    }
  }

  static DateTime _parseDate(dynamic dateData) {
    if (dateData == null) {
      print('⚠️ [GameModel] _parseDate: null date, defaulting to DateTime.now()');
      return DateTime.now();
    }

    if (dateData is String) {
      try {
        // Handle different date formats
        if (dateData.contains('T') || dateData.contains(' ')) {
          // Full datetime string
          return DateTime.parse(dateData);
        } else {
          // Date only string (YYYY-MM-DD)
          return DateTime.parse('${dateData}T00:00:00.000Z');
        }
      } catch (e) {
        print('⚠️ [GameModel] _parseDate: failed to parse "$dateData", error: $e. Defaulting to DateTime.now()');
        return DateTime.now();
      }
    }

    if (dateData is DateTime) {
      return dateData;
    }

    print('⚠️ [GameModel] _parseDate: unexpected type ${dateData.runtimeType}, defaulting to DateTime.now()');
    return DateTime.now();
  }

  static GameStatus _parseGameStatusFromIsCancelled(Map<String, dynamic> json) {
    // Database uses is_cancelled boolean instead of status enum
    try {
      final isCancelled = json['is_cancelled'] as bool?;

      if (isCancelled == true) {
        return GameStatus.cancelled;
      }

      // If not cancelled, determine status from start_at datetime
      final startAt = json['start_at'];
      if (startAt != null) {
        try {
          final startDate = DateTime.parse(startAt as String);
          final now = DateTime.now();

          if (startDate.isBefore(now)) {
            return GameStatus.completed;
          }
        } catch (e) {
          print('⚠️ [GameModel] _parseGameStatusFromIsCancelled: failed to parse start_at "$startAt", error: $e');
          // If parsing fails, default to upcoming
        }
      }

      return GameStatus.upcoming;
    } catch (e) {
      print('⚠️ [GameModel] _parseGameStatusFromIsCancelled: unexpected error: $e. Defaulting to upcoming');
      return GameStatus.upcoming;
    }
  }

  static String? _parseVenueName(Map<String, dynamic> json) {
    // Handle direct venue_name field
    if (json['venue_name'] != null) {
      return json['venue_name'] as String;
    }

    // Handle JOIN result: venues: {name: "Venue Name"}
    if (json['venues'] != null && json['venues'] is Map) {
      final venueData = json['venues'] as Map<String, dynamic>;
      return venueData['name'] as String?;
    }

    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'sport': sport,
      'venue_id': venueId,
      'start_at': scheduledDate
          .toIso8601String(), // Changed from scheduled_date to start_at, full datetime
      'start_time': startTime,
      'end_time': endTime,
      'min_players': minPlayers,
      'max_players': maxPlayers,
      'current_players': currentPlayers,
      'host_user_id': organizerId, // Changed from organizer_id to host_user_id
      'skill_level': skillLevel,
      'price_per_player': pricePerPlayer,
      'currency': currency,
      'is_cancelled':
          status ==
          GameStatus
              .cancelled, // Changed from status enum to is_cancelled boolean
      'is_public': isPublic,
      'allows_waitlist': allowsWaitlist,
      'check_in_enabled': checkInEnabled,
      'cancellation_deadline': cancellationDeadline?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    // Simplified JSON for creating new games (excludes computed fields)
    return {
      'title': title,
      'description': description,
      'sport': sport,
      if (venueId != null) 'venue_id': venueId,
      'start_at': scheduledDate
          .toIso8601String(), // Changed from scheduled_date to start_at
      'start_time': startTime,
      'end_time': endTime,
      'min_players': minPlayers,
      'max_players': maxPlayers,
      'host_user_id': organizerId, // Changed from organizer_id to host_user_id
      'skill_level': skillLevel,
      'price_per_player': pricePerPlayer,
      'currency': currency,
      'is_cancelled':
          status == GameStatus.cancelled, // Changed from status to is_cancelled
      'is_public': isPublic,
      'allows_waitlist': allowsWaitlist,
      'check_in_enabled': checkInEnabled,
      if (cancellationDeadline != null)
        'cancellation_deadline': cancellationDeadline!.toIso8601String(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    // JSON for updates (excludes immutable fields like id, host_user_id, created_at)
    return {
      'title': title,
      'description': description,
      'sport': sport,
      if (venueId != null) 'venue_id': venueId,
      'start_at': scheduledDate
          .toIso8601String(), // Changed from scheduled_date to start_at
      'start_time': startTime,
      'end_time': endTime,
      'min_players': minPlayers,
      'max_players': maxPlayers,
      'skill_level': skillLevel,
      'price_per_player': pricePerPlayer,
      'currency': currency,
      'is_cancelled':
          status == GameStatus.cancelled, // Changed from status to is_cancelled
      'is_public': isPublic,
      'allows_waitlist': allowsWaitlist,
      'check_in_enabled': checkInEnabled,
      if (cancellationDeadline != null)
        'cancellation_deadline': cancellationDeadline!.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory GameModel.fromGame(Game game) {
    return GameModel(
      id: game.id,
      title: game.title,
      description: game.description,
      sport: game.sport,
      venueId: game.venueId,
      scheduledDate: game.scheduledDate,
      startTime: game.startTime,
      endTime: game.endTime,
      minPlayers: game.minPlayers,
      maxPlayers: game.maxPlayers,
      currentPlayers: game.currentPlayers,
      organizerId: game.organizerId,
      skillLevel: game.skillLevel,
      pricePerPlayer: game.pricePerPlayer,
      currency: game.currency,
      status: game.status,
      isPublic: game.isPublic,
      allowsWaitlist: game.allowsWaitlist,
      checkInEnabled: game.checkInEnabled,
      cancellationDeadline: game.cancellationDeadline,
      createdAt: game.createdAt,
      updatedAt: game.updatedAt,
    );
  }

  @override
  GameModel copyWith({
    String? id,
    String? title,
    String? description,
    String? sport,
    String? venueId,
    String? venueName,
    DateTime? scheduledDate,
    String? startTime,
    String? endTime,
    int? minPlayers,
    int? maxPlayers,
    int? currentPlayers,
    String? organizerId,
    String? skillLevel,
    double? pricePerPlayer,
    String? currency,
    GameStatus? status,
    bool? isPublic,
    bool? allowsWaitlist,
    bool? checkInEnabled,
    DateTime? cancellationDeadline,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GameModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      sport: sport ?? this.sport,
      venueId: venueId ?? this.venueId,
      venueName: venueName ?? this.venueName,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      minPlayers: minPlayers ?? this.minPlayers,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      currentPlayers: currentPlayers ?? this.currentPlayers,
      organizerId: organizerId ?? this.organizerId,
      skillLevel: skillLevel ?? this.skillLevel,
      pricePerPlayer: pricePerPlayer ?? this.pricePerPlayer,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      isPublic: isPublic ?? this.isPublic,
      allowsWaitlist: allowsWaitlist ?? this.allowsWaitlist,
      checkInEnabled: checkInEnabled ?? this.checkInEnabled,
      cancellationDeadline: cancellationDeadline ?? this.cancellationDeadline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
