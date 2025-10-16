import '../../domain/entities/game_session.dart';

class ScoreModel extends Score {
  const ScoreModel({
    required super.teamOrPlayerId,
    required super.teamOrPlayerName,
    required super.points,
    super.stats = const {},
  });

  factory ScoreModel.fromJson(Map<String, dynamic> json) {
    return ScoreModel(
      teamOrPlayerId: json['team_or_player_id'] as String,
      teamOrPlayerName: json['team_or_player_name'] as String,
      points: json['points'] as int,
      stats: json['stats'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'team_or_player_id': teamOrPlayerId,
      'team_or_player_name': teamOrPlayerName,
      'points': points,
      'stats': stats,
    };
  }

  factory ScoreModel.fromScore(Score score) {
    return ScoreModel(
      teamOrPlayerId: score.teamOrPlayerId,
      teamOrPlayerName: score.teamOrPlayerName,
      points: score.points,
      stats: score.stats,
    );
  }
}

class GameEventModel extends GameEvent {
  const GameEventModel({
    required super.id,
    required super.type,
    required super.timestamp,
    super.playerId,
    super.playerName,
    super.teamId,
    required super.description,
    super.metadata = const {},
  });

  factory GameEventModel.fromJson(Map<String, dynamic> json) {
    return GameEventModel(
      id: json['id'] as String,
      type: json['type'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      playerId: json['player_id'] as String?,
      playerName: json['player_name'] as String?,
      teamId: json['team_id'] as String?,
      description: json['description'] as String,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'player_id': playerId,
      'player_name': playerName,
      'team_id': teamId,
      'description': description,
      'metadata': metadata,
    };
  }

  factory GameEventModel.fromGameEvent(GameEvent event) {
    return GameEventModel(
      id: event.id,
      type: event.type,
      timestamp: event.timestamp,
      playerId: event.playerId,
      playerName: event.playerName,
      teamId: event.teamId,
      description: event.description,
      metadata: event.metadata,
    );
  }
}

class GameSessionModel extends GameSession {
  const GameSessionModel({
    required super.id,
    required super.gameId,
    required super.venueId,
    super.bookingId,
    required super.type,
    required super.status,
    super.description,
    super.rules,
    required super.scheduledStartTime,
    required super.scheduledEndTime,
    super.actualStartTime,
    super.actualEndTime,
    super.scheduledDurationMinutes,
    super.pausedTimes = const [],
    super.resumedTimes = const [],
    super.weatherCondition,
    super.temperature,
    super.humidity,
    super.windSpeed,
    super.surfaceCondition,
    super.scores = const [],
    super.winnerId,
    super.winnerName,
    super.isDraw = false,
    super.gameResult,
    super.events = const [],
    super.timeouts = const [],
    super.currentPeriod,
    super.totalPeriods,
    super.requiredEquipment = const [],
    super.providedEquipment = const [],
    super.equipmentNotes,
    super.setupNotes,
    super.refereeId,
    super.refereeName,
    super.officialIds = const [],
    super.supervisorId,
    super.photos = const [],
    super.videos = const [],
    super.streamingUrl,
    super.isLiveStreaming = false,
    super.checkedInPlayerIds = const [],
    super.noShowPlayerIds = const [],
    super.injuredPlayerIds = const [],
    super.playerCheckInTimes = const {},
    super.playerCheckOutTimes = const {},
    super.sessionRating,
    super.sessionFeedback,
    super.issues = const [],
    super.highlights = const [],
    super.cancellationReason,
    super.cancelledAt,
    super.cancelledBy,
    super.abandonmentReason,
    super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    super.lastUpdatedBy,
  });

  factory GameSessionModel.fromJson(Map<String, dynamic> json) {
    return GameSessionModel(
      id: json['id'] as String,
      gameId: json['game_id'] as String,
      venueId: json['venue_id'] as String,
      bookingId: json['booking_id'] as String?,
      type: _parseSessionType(json['type']),
      status: _parseSessionStatus(json['status']),
      description: json['description'] as String?,
      rules: json['rules'] as String?,
      scheduledStartTime: DateTime.parse(json['scheduled_start_time'] as String),
      scheduledEndTime: DateTime.parse(json['scheduled_end_time'] as String),
      actualStartTime: json['actual_start_time'] != null
          ? DateTime.parse(json['actual_start_time'] as String)
          : null,
      actualEndTime: json['actual_end_time'] != null
          ? DateTime.parse(json['actual_end_time'] as String)
          : null,
      scheduledDurationMinutes: json['scheduled_duration_minutes'] as int?,
      pausedTimes: _parseDateTimeList(json['paused_times']),
      resumedTimes: _parseDateTimeList(json['resumed_times']),
      weatherCondition: _parseWeatherCondition(json['weather_condition']),
      temperature: (json['temperature'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      windSpeed: json['wind_speed'] as String?,
      surfaceCondition: json['surface_condition'] as String?,
      scores: _parseScoresList(json['scores']),
      winnerId: json['winner_id'] as String?,
      winnerName: json['winner_name'] as String?,
      isDraw: json['is_draw'] as bool? ?? false,
      gameResult: json['game_result'] as String?,
      events: _parseEventsList(json['events']),
      timeouts: (json['timeouts'] as List?)?.cast<String>() ?? [],
      currentPeriod: json['current_period'] as int?,
      totalPeriods: json['total_periods'] as int?,
      requiredEquipment: (json['required_equipment'] as List?)?.cast<String>() ?? [],
      providedEquipment: (json['provided_equipment'] as List?)?.cast<String>() ?? [],
      equipmentNotes: json['equipment_notes'] as String?,
      setupNotes: json['setup_notes'] as String?,
      refereeId: json['referee_id'] as String?,
      refereeName: json['referee_name'] as String?,
      officialIds: (json['official_ids'] as List?)?.cast<String>() ?? [],
      supervisorId: json['supervisor_id'] as String?,
      photos: (json['photos'] as List?)?.cast<String>() ?? [],
      videos: (json['videos'] as List?)?.cast<String>() ?? [],
      streamingUrl: json['streaming_url'] as String?,
      isLiveStreaming: json['is_live_streaming'] as bool? ?? false,
      checkedInPlayerIds: (json['checked_in_player_ids'] as List?)?.cast<String>() ?? [],
      noShowPlayerIds: (json['no_show_player_ids'] as List?)?.cast<String>() ?? [],
      injuredPlayerIds: (json['injured_player_ids'] as List?)?.cast<String>() ?? [],
      playerCheckInTimes: _parsePlayerCheckInTimes(json['player_check_in_times']),
      playerCheckOutTimes: _parsePlayerCheckInTimes(json['player_check_out_times']),
      sessionRating: (json['session_rating'] as num?)?.toDouble(),
      sessionFeedback: json['session_feedback'] as String?,
      issues: (json['issues'] as List?)?.cast<String>() ?? [],
      highlights: (json['highlights'] as List?)?.cast<String>() ?? [],
      cancellationReason: json['cancellation_reason'] as String?,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      cancelledBy: json['cancelled_by'] as String?,
      abandonmentReason: json['abandonment_reason'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastUpdatedBy: json['last_updated_by'] as String?,
    );
  }

  static SessionType _parseSessionType(dynamic typeData) {
    if (typeData == null) return SessionType.regular;
    
    if (typeData is String) {
      try {
        return SessionType.values.firstWhere(
          (e) => e.toString().split('.').last.toLowerCase() == typeData.toLowerCase(),
          orElse: () => SessionType.regular,
        );
      } catch (e) {
        return SessionType.regular;
      }
    }
    
    return SessionType.regular;
  }

  static SessionStatus _parseSessionStatus(dynamic statusData) {
    if (statusData == null) return SessionStatus.scheduled;
    
    if (statusData is String) {
      try {
        return SessionStatus.values.firstWhere(
          (e) => e.toString().split('.').last.toLowerCase() == statusData.toLowerCase(),
          orElse: () => SessionStatus.scheduled,
        );
      } catch (e) {
        return SessionStatus.scheduled;
      }
    }
    
    return SessionStatus.scheduled;
  }

  static WeatherCondition? _parseWeatherCondition(dynamic weatherData) {
    if (weatherData == null) return null;
    
    if (weatherData is String) {
      try {
        return WeatherCondition.values.firstWhere(
          (e) => e.toString().split('.').last.toLowerCase() == weatherData.toLowerCase(),
          orElse: () => WeatherCondition.sunny,
        );
      } catch (e) {
        return null;
      }
    }
    
    return null;
  }

  static List<DateTime> _parseDateTimeList(dynamic listData) {
    if (listData == null) return [];
    
    if (listData is List) {
      return listData
          .map((item) {
            try {
              return DateTime.parse(item as String);
            } catch (e) {
              return null;
            }
          })
          .where((item) => item != null)
          .cast<DateTime>()
          .toList();
    }
    
    return [];
  }

  static List<Score> _parseScoresList(dynamic scoresData) {
    if (scoresData == null) return [];
    
    if (scoresData is List) {
      return scoresData
          .map((item) {
            try {
              return ScoreModel.fromJson(item as Map<String, dynamic>);
            } catch (e) {
              return null;
            }
          })
          .where((item) => item != null)
          .cast<Score>()
          .toList();
    }
    
    return [];
  }

  static List<GameEvent> _parseEventsList(dynamic eventsData) {
    if (eventsData == null) return [];
    
    if (eventsData is List) {
      return eventsData
          .map((item) {
            try {
              return GameEventModel.fromJson(item as Map<String, dynamic>);
            } catch (e) {
              return null;
            }
          })
          .where((item) => item != null)
          .cast<GameEvent>()
          .toList();
    }
    
    return [];
  }

  static Map<String, DateTime> _parsePlayerCheckInTimes(dynamic timesData) {
    if (timesData == null) return {};
    
    if (timesData is Map) {
      final result = <String, DateTime>{};
      for (final entry in timesData.entries) {
        try {
          result[entry.key as String] = DateTime.parse(entry.value as String);
        } catch (e) {
          // Skip invalid entries
        }
      }
      return result;
    }
    
    return {};
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'game_id': gameId,
      'venue_id': venueId,
      'booking_id': bookingId,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'description': description,
      'rules': rules,
      'scheduled_start_time': scheduledStartTime.toIso8601String(),
      'scheduled_end_time': scheduledEndTime.toIso8601String(),
      'actual_start_time': actualStartTime?.toIso8601String(),
      'actual_end_time': actualEndTime?.toIso8601String(),
      'scheduled_duration_minutes': scheduledDurationMinutes,
      'paused_times': pausedTimes.map((dt) => dt.toIso8601String()).toList(),
      'resumed_times': resumedTimes.map((dt) => dt.toIso8601String()).toList(),
      'weather_condition': weatherCondition?.toString().split('.').last,
      'temperature': temperature,
      'humidity': humidity,
      'wind_speed': windSpeed,
      'surface_condition': surfaceCondition,
      'scores': scores.map((score) => ScoreModel.fromScore(score).toJson()).toList(),
      'winner_id': winnerId,
      'winner_name': winnerName,
      'is_draw': isDraw,
      'game_result': gameResult,
      'events': events.map((event) => GameEventModel.fromGameEvent(event).toJson()).toList(),
      'timeouts': timeouts,
      'current_period': currentPeriod,
      'total_periods': totalPeriods,
      'required_equipment': requiredEquipment,
      'provided_equipment': providedEquipment,
      'equipment_notes': equipmentNotes,
      'setup_notes': setupNotes,
      'referee_id': refereeId,
      'referee_name': refereeName,
      'official_ids': officialIds,
      'supervisor_id': supervisorId,
      'photos': photos,
      'videos': videos,
      'streaming_url': streamingUrl,
      'is_live_streaming': isLiveStreaming,
      'checked_in_player_ids': checkedInPlayerIds,
      'no_show_player_ids': noShowPlayerIds,
      'injured_player_ids': injuredPlayerIds,
      'player_check_in_times': playerCheckInTimes.map((key, value) => MapEntry(key, value.toIso8601String())),
      'player_check_out_times': playerCheckOutTimes.map((key, value) => MapEntry(key, value.toIso8601String())),
      'session_rating': sessionRating,
      'session_feedback': sessionFeedback,
      'issues': issues,
      'highlights': highlights,
      'cancellation_reason': cancellationReason,
      'cancelled_at': cancelledAt?.toIso8601String(),
      'cancelled_by': cancelledBy,
      'abandonment_reason': abandonmentReason,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_updated_by': lastUpdatedBy,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'game_id': gameId,
      'venue_id': venueId,
      'booking_id': bookingId,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'description': description,
      'rules': rules,
      'scheduled_start_time': scheduledStartTime.toIso8601String(),
      'scheduled_end_time': scheduledEndTime.toIso8601String(),
      'scheduled_duration_minutes': scheduledDurationMinutes,
      'weather_condition': weatherCondition?.toString().split('.').last,
      'temperature': temperature,
      'humidity': humidity,
      'wind_speed': windSpeed,
      'surface_condition': surfaceCondition,
      'current_period': currentPeriod,
      'total_periods': totalPeriods,
      'required_equipment': requiredEquipment,
      'provided_equipment': providedEquipment,
      'equipment_notes': equipmentNotes,
      'setup_notes': setupNotes,
      'referee_id': refereeId,
      'referee_name': refereeName,
      'official_ids': officialIds,
      'supervisor_id': supervisorId,
      'created_by': createdBy,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'description': description,
      'rules': rules,
      'scheduled_start_time': scheduledStartTime.toIso8601String(),
      'scheduled_end_time': scheduledEndTime.toIso8601String(),
      'actual_start_time': actualStartTime?.toIso8601String(),
      'actual_end_time': actualEndTime?.toIso8601String(),
      'scheduled_duration_minutes': scheduledDurationMinutes,
      'paused_times': pausedTimes.map((dt) => dt.toIso8601String()).toList(),
      'resumed_times': resumedTimes.map((dt) => dt.toIso8601String()).toList(),
      'weather_condition': weatherCondition?.toString().split('.').last,
      'temperature': temperature,
      'humidity': humidity,
      'wind_speed': windSpeed,
      'surface_condition': surfaceCondition,
      'scores': scores.map((score) => ScoreModel.fromScore(score).toJson()).toList(),
      'winner_id': winnerId,
      'winner_name': winnerName,
      'is_draw': isDraw,
      'game_result': gameResult,
      'events': events.map((event) => GameEventModel.fromGameEvent(event).toJson()).toList(),
      'timeouts': timeouts,
      'current_period': currentPeriod,
      'total_periods': totalPeriods,
      'required_equipment': requiredEquipment,
      'provided_equipment': providedEquipment,
      'equipment_notes': equipmentNotes,
      'setup_notes': setupNotes,
      'referee_id': refereeId,
      'referee_name': refereeName,
      'official_ids': officialIds,
      'supervisor_id': supervisorId,
      'photos': photos,
      'videos': videos,
      'streaming_url': streamingUrl,
      'is_live_streaming': isLiveStreaming,
      'checked_in_player_ids': checkedInPlayerIds,
      'no_show_player_ids': noShowPlayerIds,
      'injured_player_ids': injuredPlayerIds,
      'player_check_in_times': playerCheckInTimes.map((key, value) => MapEntry(key, value.toIso8601String())),
      'player_check_out_times': playerCheckOutTimes.map((key, value) => MapEntry(key, value.toIso8601String())),
      'session_rating': sessionRating,
      'session_feedback': sessionFeedback,
      'issues': issues,
      'highlights': highlights,
      'cancellation_reason': cancellationReason,
      'cancelled_at': cancelledAt?.toIso8601String(),
      'cancelled_by': cancelledBy,
      'abandonment_reason': abandonmentReason,
      'updated_at': DateTime.now().toIso8601String(),
      'last_updated_by': lastUpdatedBy,
    };
  }

  // Get live session status display
  String get liveStatusDisplay {
    if (isLiveStreaming) {
      return 'LIVE • $statusText';
    }
    return statusText;
  }

  // Get weather summary display
  String get weatherSummaryDisplay {
    final buffer = StringBuffer();
    if (weatherCondition != null) {
      buffer.write(weatherText);
    }
    if (temperature != null) {
      if (buffer.isNotEmpty) buffer.write(' • ');
      buffer.write(temperatureText);
    }
    if (humidity != null) {
      if (buffer.isNotEmpty) buffer.write(' • ');
      buffer.write('${humidity!.round()}% humidity');
    }
    if (windSpeed != null) {
      if (buffer.isNotEmpty) buffer.write(' • ');
      buffer.write('Wind: $windSpeed');
    }
    return buffer.isEmpty ? 'Weather not recorded' : buffer.toString();
  }

  // Get equipment status display
  String get equipmentStatusDisplay {
    final required = requiredEquipment.length;
    final provided = providedEquipment.length;
    return 'Equipment: $provided/$required items provided';
  }

  // Get session duration status display
  String get durationStatusDisplay {
    if (actualDurationMinutes != null) {
      final hours = actualDurationMinutes! ~/ 60;
      final minutes = actualDurationMinutes! % 60;
      final scheduled = scheduledDurationMinutesCalculated;
      final scheduledHours = scheduled ~/ 60;
      final scheduledMins = scheduled % 60;
      
      return 'Actual: ${hours}h ${minutes}m (Scheduled: ${scheduledHours}h ${scheduledMins}m)';
    } else {
      final scheduled = scheduledDurationMinutesCalculated;
      final scheduledHours = scheduled ~/ 60;
      final scheduledMins = scheduled % 60;
      return 'Scheduled: ${scheduledHours}h ${scheduledMins}m';
    }
  }

  // Get player participation summary
  String get participationSummaryDisplay {
    final checkedIn = checkedInPlayerIds.length;
    final noShow = noShowPlayerIds.length;
    final injured = injuredPlayerIds.length;
    
    return 'Participation: $checkedIn checked in, $noShow no-show, $injured injured';
  }

  // Get session quality display
  String get qualityDisplay {
    if (sessionRating != null) {
      return '${sessionRating!.toStringAsFixed(1)}/5.0 stars';
    }
    return 'Not rated';
  }

  // Get issues and highlights summary
  String get issuesHighlightsSummary {
    final buffer = StringBuffer();
    if (issues.isNotEmpty) {
      buffer.write('${issues.length} issue${issues.length == 1 ? '' : 's'}');
    }
    if (highlights.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write(' • ');
      buffer.write('${highlights.length} highlight${highlights.length == 1 ? '' : 's'}');
    }
    return buffer.isEmpty ? 'No issues or highlights' : buffer.toString();
  }

  // Get streaming status display
  String get streamingStatusDisplay {
    if (streamingUrl != null && isLiveStreaming) {
      return 'Live streaming active';
    } else if (streamingUrl != null) {
      return 'Stream available (not live)';
    }
    return 'No streaming';
  }

  // Get media summary display
  String get mediaSummaryDisplay {
    final photoCount = photos.length;
    final videoCount = videos.length;
    return 'Media: $photoCount photo${photoCount == 1 ? '' : 's'}, $videoCount video${videoCount == 1 ? '' : 's'}';
  }

  factory GameSessionModel.fromGameSession(GameSession session) {
    return GameSessionModel(
      id: session.id,
      gameId: session.gameId,
      venueId: session.venueId,
      bookingId: session.bookingId,
      type: session.type,
      status: session.status,
      description: session.description,
      rules: session.rules,
      scheduledStartTime: session.scheduledStartTime,
      scheduledEndTime: session.scheduledEndTime,
      actualStartTime: session.actualStartTime,
      actualEndTime: session.actualEndTime,
      scheduledDurationMinutes: session.scheduledDurationMinutes,
      pausedTimes: session.pausedTimes,
      resumedTimes: session.resumedTimes,
      weatherCondition: session.weatherCondition,
      temperature: session.temperature,
      humidity: session.humidity,
      windSpeed: session.windSpeed,
      surfaceCondition: session.surfaceCondition,
      scores: session.scores,
      winnerId: session.winnerId,
      winnerName: session.winnerName,
      isDraw: session.isDraw,
      gameResult: session.gameResult,
      events: session.events,
      timeouts: session.timeouts,
      currentPeriod: session.currentPeriod,
      totalPeriods: session.totalPeriods,
      requiredEquipment: session.requiredEquipment,
      providedEquipment: session.providedEquipment,
      equipmentNotes: session.equipmentNotes,
      setupNotes: session.setupNotes,
      refereeId: session.refereeId,
      refereeName: session.refereeName,
      officialIds: session.officialIds,
      supervisorId: session.supervisorId,
      photos: session.photos,
      videos: session.videos,
      streamingUrl: session.streamingUrl,
      isLiveStreaming: session.isLiveStreaming,
      checkedInPlayerIds: session.checkedInPlayerIds,
      noShowPlayerIds: session.noShowPlayerIds,
      injuredPlayerIds: session.injuredPlayerIds,
      playerCheckInTimes: session.playerCheckInTimes,
      playerCheckOutTimes: session.playerCheckOutTimes,
      sessionRating: session.sessionRating,
      sessionFeedback: session.sessionFeedback,
      issues: session.issues,
      highlights: session.highlights,
      cancellationReason: session.cancellationReason,
      cancelledAt: session.cancelledAt,
      cancelledBy: session.cancelledBy,
      abandonmentReason: session.abandonmentReason,
      createdBy: session.createdBy,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
      lastUpdatedBy: session.lastUpdatedBy,
    );
  }

  @override
  GameSessionModel copyWith({
    String? id,
    String? gameId,
    String? venueId,
    String? bookingId,
    SessionType? type,
    SessionStatus? status,
    String? description,
    String? rules,
    DateTime? scheduledStartTime,
    DateTime? scheduledEndTime,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    int? scheduledDurationMinutes,
    List<DateTime>? pausedTimes,
    List<DateTime>? resumedTimes,
    WeatherCondition? weatherCondition,
    double? temperature,
    double? humidity,
    String? windSpeed,
    String? surfaceCondition,
    List<Score>? scores,
    String? winnerId,
    String? winnerName,
    bool? isDraw,
    String? gameResult,
    List<GameEvent>? events,
    List<String>? timeouts,
    int? currentPeriod,
    int? totalPeriods,
    List<String>? requiredEquipment,
    List<String>? providedEquipment,
    String? equipmentNotes,
    String? setupNotes,
    String? refereeId,
    String? refereeName,
    List<String>? officialIds,
    String? supervisorId,
    List<String>? photos,
    List<String>? videos,
    String? streamingUrl,
    bool? isLiveStreaming,
    List<String>? checkedInPlayerIds,
    List<String>? noShowPlayerIds,
    List<String>? injuredPlayerIds,
    Map<String, DateTime>? playerCheckInTimes,
    Map<String, DateTime>? playerCheckOutTimes,
    double? sessionRating,
    String? sessionFeedback,
    List<String>? issues,
    List<String>? highlights,
    String? cancellationReason,
    DateTime? cancelledAt,
    String? cancelledBy,
    String? abandonmentReason,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastUpdatedBy,
  }) {
    return GameSessionModel(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      venueId: venueId ?? this.venueId,
      bookingId: bookingId ?? this.bookingId,
      type: type ?? this.type,
      status: status ?? this.status,
      description: description ?? this.description,
      rules: rules ?? this.rules,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      scheduledEndTime: scheduledEndTime ?? this.scheduledEndTime,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      scheduledDurationMinutes: scheduledDurationMinutes ?? this.scheduledDurationMinutes,
      pausedTimes: pausedTimes ?? this.pausedTimes,
      resumedTimes: resumedTimes ?? this.resumedTimes,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      surfaceCondition: surfaceCondition ?? this.surfaceCondition,
      scores: scores ?? this.scores,
      winnerId: winnerId ?? this.winnerId,
      winnerName: winnerName ?? this.winnerName,
      isDraw: isDraw ?? this.isDraw,
      gameResult: gameResult ?? this.gameResult,
      events: events ?? this.events,
      timeouts: timeouts ?? this.timeouts,
      currentPeriod: currentPeriod ?? this.currentPeriod,
      totalPeriods: totalPeriods ?? this.totalPeriods,
      requiredEquipment: requiredEquipment ?? this.requiredEquipment,
      providedEquipment: providedEquipment ?? this.providedEquipment,
      equipmentNotes: equipmentNotes ?? this.equipmentNotes,
      setupNotes: setupNotes ?? this.setupNotes,
      refereeId: refereeId ?? this.refereeId,
      refereeName: refereeName ?? this.refereeName,
      officialIds: officialIds ?? this.officialIds,
      supervisorId: supervisorId ?? this.supervisorId,
      photos: photos ?? this.photos,
      videos: videos ?? this.videos,
      streamingUrl: streamingUrl ?? this.streamingUrl,
      isLiveStreaming: isLiveStreaming ?? this.isLiveStreaming,
      checkedInPlayerIds: checkedInPlayerIds ?? this.checkedInPlayerIds,
      noShowPlayerIds: noShowPlayerIds ?? this.noShowPlayerIds,
      injuredPlayerIds: injuredPlayerIds ?? this.injuredPlayerIds,
      playerCheckInTimes: playerCheckInTimes ?? this.playerCheckInTimes,
      playerCheckOutTimes: playerCheckOutTimes ?? this.playerCheckOutTimes,
      sessionRating: sessionRating ?? this.sessionRating,
      sessionFeedback: sessionFeedback ?? this.sessionFeedback,
      issues: issues ?? this.issues,
      highlights: highlights ?? this.highlights,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      abandonmentReason: abandonmentReason ?? this.abandonmentReason,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
    );
  }
}
