import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../domain/entities/game.dart';
import '../../domain/entities/venue.dart';
import '../../domain/entities/player.dart';
import '../../domain/usecases/join_game_usecase.dart';
import '../../domain/repositories/games_repository.dart';
import '../../domain/repositories/venues_repository.dart';

enum JoinGameStatus {
  canJoin,
  waitlisted,
  alreadyJoined,
  gameFull,
  gameStarted,
  gameEnded,
  notEligible,
}

class WeatherInfo {
  final String condition; // sunny, cloudy, rainy, etc.
  final int temperature; // in Celsius
  final String description;
  final String iconUrl;
  final int humidity;
  final double windSpeed;
  final int uvIndex;

  const WeatherInfo({
    required this.condition,
    required this.temperature,
    required this.description,
    required this.iconUrl,
    required this.humidity,
    required this.windSpeed,
    required this.uvIndex,
  });
}

class GameDetailState {
  final Game? game;
  final Venue? venue;
  final List<Player> players;
  final List<Player> waitlistedPlayers;
  final bool isLoading;
  final bool isLoadingVenue;
  final bool isLoadingPlayers;
  final bool isJoining;
  final String? error;
  final JoinGameStatus joinStatus;
  final bool isOrganizer;
  final WeatherInfo? weather;
  final bool isLoadingWeather;
  final DateTime? lastUpdated;
  final Timer? realtimeTimer;

  const GameDetailState({
    this.game,
    this.venue,
    this.players = const [],
    this.waitlistedPlayers = const [],
    this.isLoading = false,
    this.isLoadingVenue = false,
    this.isLoadingPlayers = false,
    this.isJoining = false,
    this.error,
    this.joinStatus = JoinGameStatus.canJoin,
    this.isOrganizer = false,
    this.weather,
    this.isLoadingWeather = false,
    this.lastUpdated,
    this.realtimeTimer,
  });

  bool get hasGame => game != null;
  bool get hasVenue => venue != null;
  bool get hasWeather => weather != null;
  bool get isAnyLoading => isLoading || isLoadingVenue || isLoadingPlayers || isLoadingWeather;
  
  int get totalPlayers => players.length;
  int get spotsRemaining => game != null ? (game!.maxPlayers - totalPlayers) : 0;
  bool get isGameFull => spotsRemaining <= 0;
  
  double get fillPercentage => game != null ? (totalPlayers / game!.maxPlayers) : 0.0;
  bool get hasMinimumPlayers => game != null ? (totalPlayers >= game!.minPlayers) : false;
  
  Duration? get timeUntilStart {
    if (game == null) return null;
    final startDateTime = _combineDateTime(game!.scheduledDate, game!.startTime);
    final now = DateTime.now();
    if (startDateTime.isBefore(now)) return null;
    return startDateTime.difference(now);
  }
  
  bool get canStillJoin {
    if (game == null) return false;
    final startDateTime = _combineDateTime(game!.scheduledDate, game!.startTime);
    return DateTime.now().isBefore(startDateTime.subtract(const Duration(minutes: 15)));
  }

  DateTime _combineDateTime(DateTime date, String time) {
    final timeParts = time.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  GameDetailState copyWith({
    Game? game,
    Venue? venue,
    List<Player>? players,
    List<Player>? waitlistedPlayers,
    bool? isLoading,
    bool? isLoadingVenue,
    bool? isLoadingPlayers,
    bool? isJoining,
    String? error,
    JoinGameStatus? joinStatus,
    bool? isOrganizer,
    WeatherInfo? weather,
    bool? isLoadingWeather,
    DateTime? lastUpdated,
    Timer? realtimeTimer,
  }) {
    return GameDetailState(
      game: game ?? this.game,
      venue: venue ?? this.venue,
      players: players ?? this.players,
      waitlistedPlayers: waitlistedPlayers ?? this.waitlistedPlayers,
      isLoading: isLoading ?? this.isLoading,
      isLoadingVenue: isLoadingVenue ?? this.isLoadingVenue,
      isLoadingPlayers: isLoadingPlayers ?? this.isLoadingPlayers,
      isJoining: isJoining ?? this.isJoining,
      error: error,
      joinStatus: joinStatus ?? this.joinStatus,
      isOrganizer: isOrganizer ?? this.isOrganizer,
      weather: weather ?? this.weather,
      isLoadingWeather: isLoadingWeather ?? this.isLoadingWeather,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      realtimeTimer: realtimeTimer ?? this.realtimeTimer,
    );
  }
}

class GameDetailController extends StateNotifier<GameDetailState> {
  final JoinGameUseCase _joinGameUseCase;
  final GamesRepository _gamesRepository;
  final VenuesRepository _venuesRepository;
  final String gameId;
  final String? currentUserId;

  GameDetailController({
    required JoinGameUseCase joinGameUseCase,
    required GamesRepository gamesRepository,
    required VenuesRepository venuesRepository,
    required this.gameId,
    this.currentUserId,
  })  : _joinGameUseCase = joinGameUseCase,
        _gamesRepository = gamesRepository,
        _venuesRepository = venuesRepository,
        super(const GameDetailState()) {
    _initializeGameDetail();
  }

  /// Initialize and load all game details
  Future<void> _initializeGameDetail() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Load game details concurrently
      await Future.wait([
        _loadGameDetails(),
        _loadGamePlayers(),
      ]);
      
      // Load venue details if game has a venue
      if (state.game?.venueId != null) {
        await _loadVenueDetails();
        
        // Load weather if venue has location
        if (state.venue != null) {
          await _loadWeatherInfo();
        }
      }
      
      // Determine join status
      _updateJoinStatus();
      
      // Start real-time updates
      _startRealtimeUpdates();
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load game details: $e',
      );
    }
  }

  /// Refresh all game data
  Future<void> refresh() async {
    await _initializeGameDetail();
  }

  /// Load game basic details
  Future<void> _loadGameDetails() async {
    try {
      final result = await _gamesRepository.getGame(gameId);
      
      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            error: 'Failed to load game: ${failure.message}',
          );
        },
        (game) {
          state = state.copyWith(
            game: game,
            isOrganizer: currentUserId == game.organizerId,
            isLoading: false,
            lastUpdated: DateTime.now(),
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load game details: $e',
      );
    }
  }

  /// Load venue details
  Future<void> _loadVenueDetails() async {
    if (state.game?.venueId == null) return;
    
    state = state.copyWith(isLoadingVenue: true);
    
    try {
      final result = await _venuesRepository.getVenue(state.game!.venueId!);
      
      result.fold(
        (failure) {
          state = state.copyWith(
            isLoadingVenue: false,
            error: 'Failed to load venue: ${failure.message}',
          );
        },
        (venue) {
          state = state.copyWith(
            venue: venue,
            isLoadingVenue: false,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingVenue: false,
        error: 'Failed to load venue details: $e',
      );
    }
  }

  /// Load current players and waitlisted players
  Future<void> _loadGamePlayers() async {
    state = state.copyWith(isLoadingPlayers: true);
    
    try {
      final result = await _gamesRepository.getGamePlayers(gameId);
      
      result.fold(
        (failure) {
          state = state.copyWith(
            isLoadingPlayers: false,
            error: 'Failed to load players',
          );
        },
        (allPlayers) {
          // Split players into confirmed and waitlisted
          final confirmedPlayers = allPlayers
              .where((p) => p.status == PlayerStatus.confirmed)
              .toList();
          final waitlistedPlayers = allPlayers
              .where((p) => p.status == PlayerStatus.waitlisted)
              .toList();
          
          state = state.copyWith(
            players: confirmedPlayers,
            waitlistedPlayers: waitlistedPlayers,
            isLoadingPlayers: false,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingPlayers: false,
        error: 'Failed to load players: $e',
      );
    }
  }

  /// Load weather information for the game
  Future<void> _loadWeatherInfo() async {
    if (state.venue == null || state.game == null) return;
    
    state = state.copyWith(isLoadingWeather: true);
    
    try {
      // TODO: Integrate weather API (OpenWeather, WeatherAPI, etc.)
      // For now, weather feature is disabled
      // final result = await _weatherService.getWeather(
      //   latitude: state.venue!.latitude,
      //   longitude: state.venue!.longitude,
      //   date: state.game!.scheduledDate,
      // );
      
      state = state.copyWith(
        weather: null, // Weather feature disabled
        isLoadingWeather: false,
      );
      
    } catch (e) {
      state = state.copyWith(
        isLoadingWeather: false,
        error: 'Failed to load weather: $e',
      );
    }
  }

  /// Join the game
  Future<void> joinGame() async {
    if (currentUserId == null || state.joinStatus == JoinGameStatus.alreadyJoined) return;
    
    state = state.copyWith(isJoining: true, error: null);
    
    try {
      final result = await _joinGameUseCase(JoinGameParams(
        gameId: gameId,
        playerId: currentUserId!,
      ));
      
      result.fold(
        (failure) {
          state = state.copyWith(
            isJoining: false,
            error: failure.message,
          );
        },
        (success) {
          // Refresh game data to get updated player list
          _loadGamePlayers();
          _updateJoinStatus();
          
          state = state.copyWith(isJoining: false);
        },
      );
      
    } catch (e) {
      state = state.copyWith(
        isJoining: false,
        error: 'Failed to join game: $e',
      );
    }
  }

  /// Leave the game
  Future<void> leaveGame() async {
    if (currentUserId == null) return;
    
    state = state.copyWith(isJoining: true, error: null);
    
    try {
      // TODO: Implement LeaveGameUseCase
      // final result = await _leaveGameUseCase(LeaveGameParams(
      //   gameId: gameId,
      //   playerId: currentUserId!,
      // ));
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock success - refresh data
      await _loadGamePlayers();
      _updateJoinStatus();
      
      state = state.copyWith(isJoining: false);
      
    } catch (e) {
      state = state.copyWith(
        isJoining: false,
        error: 'Failed to leave game: $e',
      );
    }
  }

  /// Update join status based on current state
  void _updateJoinStatus() {
    if (currentUserId == null || state.game == null) {
      state = state.copyWith(joinStatus: JoinGameStatus.notEligible);
      return;
    }
    
    final game = state.game!;
    
    // Check if already joined
    if (state.players.any((p) => p.id == currentUserId)) {
      state = state.copyWith(joinStatus: JoinGameStatus.alreadyJoined);
      return;
    }
    
    // Check if on waitlist
    if (state.waitlistedPlayers.any((p) => p.id == currentUserId)) {
      state = state.copyWith(joinStatus: JoinGameStatus.waitlisted);
      return;
    }
    
    // Check game status and timing
    if (game.status == GameStatus.completed || game.status == GameStatus.cancelled) {
      state = state.copyWith(joinStatus: JoinGameStatus.gameEnded);
      return;
    }
    
    if (game.status == GameStatus.inProgress) {
      state = state.copyWith(joinStatus: JoinGameStatus.gameStarted);
      return;
    }
    
    // Check if game is full
    if (state.totalPlayers >= game.maxPlayers) {
      if (game.allowsWaitlist) {
        state = state.copyWith(joinStatus: JoinGameStatus.waitlisted);
      } else {
        state = state.copyWith(joinStatus: JoinGameStatus.gameFull);
      }
      return;
    }
    
    // Check if still accepting players (not too close to start time)
    if (!state.canStillJoin) {
      state = state.copyWith(joinStatus: JoinGameStatus.gameStarted);
      return;
    }
    
    // Can join
    state = state.copyWith(joinStatus: JoinGameStatus.canJoin);
  }

  /// Start real-time updates
  void _startRealtimeUpdates() {
    // Cancel existing timer
    state.realtimeTimer?.cancel();
    
    // Start new timer for periodic updates
    final timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadGamePlayers();
        _updateJoinStatus();
      } else {
        timer.cancel();
      }
    });
    
    state = state.copyWith(realtimeTimer: timer);
  }

  /// Stop real-time updates
  void _stopRealtimeUpdates() {
    state.realtimeTimer?.cancel();
    state = state.copyWith(realtimeTimer: null);
  }

  /// Share game details
  Future<String> getShareableGameInfo() async {
    if (state.game == null) return '';
    
    final game = state.game!;
    final venue = state.venue;
    
    final buffer = StringBuffer();
    buffer.writeln('🏀 ${game.title}');
    buffer.writeln('🗓️ ${_formatDate(game.scheduledDate)}');
    buffer.writeln('🕐 ${game.startTime} - ${game.endTime}');
    buffer.writeln('👥 ${state.totalPlayers}/${game.maxPlayers} players');
    
    if (venue != null) {
      buffer.writeln('📍 ${venue.name}');
      buffer.writeln('   ${venue.shortAddress}');
    }
    
    if (game.pricePerPlayer > 0) {
      buffer.writeln('💰 \$${game.pricePerPlayer.toStringAsFixed(2)} per player');
    }
    
    buffer.writeln('\nJoin us on Dabbler! 🎯');
    
    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  @override
  void dispose() {
    _stopRealtimeUpdates();
    super.dispose();
  }
}
