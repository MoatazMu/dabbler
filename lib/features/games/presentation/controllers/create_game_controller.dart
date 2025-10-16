import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/game.dart';
import '../../domain/entities/venue.dart';
import '../../domain/usecases/create_game_usecase.dart';

enum CreateGameStep {
  sportSelection,    // Step 1: Choose sport
  dateTimeSetup,     // Step 2: Set date and time
  venueSelection,    // Step 3: Select venue
  gameConfiguration, // Step 4: Configure game details
  playerSettings,    // Step 5: Set player limits and skill level
  reviewAndCreate,   // Step 6: Review and create game
}

class CreateGameState {
  final CreateGameStep currentStep;
  final Map<String, String?> validationErrors;
  final bool isLoading;
  final bool isCreated;
  final String? error;
  
  // Step 1: Sport Selection
  final String? selectedSport;
  
  // Step 2: Date & Time
  final DateTime? selectedDate;
  final String? startTime; // Format: "HH:mm"
  final String? endTime;   // Format: "HH:mm"
  
  // Step 3: Venue Selection  
  final Venue? selectedVenue;
  final List<Venue> nearbyVenues;
  final bool isLoadingVenues;
  
  // Step 4: Game Configuration
  final String gameTitle;
  final String gameDescription;
  final String skillLevel;
  final double pricePerPlayer;
  final bool isPublic;
  final bool allowWaitlist;
  
  // Step 5: Player Settings
  final int minPlayers;
  final int maxPlayers;
  
  // Step 6: Review
  final Game? createdGame;
  final double? estimatedCost;
  final int estimatedDuration; // in minutes

  const CreateGameState({
    this.currentStep = CreateGameStep.sportSelection,
    this.validationErrors = const {},
    this.isLoading = false,
    this.isCreated = false,
    this.error,
    this.selectedSport,
    this.selectedDate,
    this.startTime,
    this.endTime,
    this.selectedVenue,
    this.nearbyVenues = const [],
    this.isLoadingVenues = false,
    this.gameTitle = '',
    this.gameDescription = '',
    this.skillLevel = 'mixed',
    this.pricePerPlayer = 0.0,
    this.isPublic = true,
    this.allowWaitlist = true,
    this.minPlayers = 2,
    this.maxPlayers = 10,
    this.createdGame,
    this.estimatedCost,
    this.estimatedDuration = 120, // Default 2 hours
  });

  bool get canProceedToNext {
    switch (currentStep) {
      case CreateGameStep.sportSelection:
        return selectedSport != null && selectedSport!.isNotEmpty;
      case CreateGameStep.dateTimeSetup:
        return selectedDate != null && startTime != null && endTime != null;
      case CreateGameStep.venueSelection:
        return true; // Venue is optional
      case CreateGameStep.gameConfiguration:
        return gameTitle.isNotEmpty && gameTitle.length >= 3;
      case CreateGameStep.playerSettings:
        return minPlayers > 0 && maxPlayers >= minPlayers && maxPlayers <= 50;
      case CreateGameStep.reviewAndCreate:
        return true;
    }
  }

  bool get isLastStep => currentStep == CreateGameStep.reviewAndCreate;
  bool get isFirstStep => currentStep == CreateGameStep.sportSelection;
  
  int get stepNumber => currentStep.index + 1;
  int get totalSteps => CreateGameStep.values.length;
  
  double get progress => stepNumber / totalSteps;

  CreateGameState copyWith({
    CreateGameStep? currentStep,
    Map<String, String?>? validationErrors,
    bool? isLoading,
    bool? isCreated,
    String? error,
    String? selectedSport,
    DateTime? selectedDate,
    String? startTime,
    String? endTime,
    Venue? selectedVenue,
    List<Venue>? nearbyVenues,
    bool? isLoadingVenues,
    String? gameTitle,
    String? gameDescription,
    String? skillLevel,
    double? pricePerPlayer,
    bool? isPublic,
    bool? allowWaitlist,
    int? minPlayers,
    int? maxPlayers,
    Game? createdGame,
    double? estimatedCost,
    int? estimatedDuration,
  }) {
    return CreateGameState(
      currentStep: currentStep ?? this.currentStep,
      validationErrors: validationErrors ?? this.validationErrors,
      isLoading: isLoading ?? this.isLoading,
      isCreated: isCreated ?? this.isCreated,
      error: error,
      selectedSport: selectedSport ?? this.selectedSport,
      selectedDate: selectedDate ?? this.selectedDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      selectedVenue: selectedVenue ?? this.selectedVenue,
      nearbyVenues: nearbyVenues ?? this.nearbyVenues,
      isLoadingVenues: isLoadingVenues ?? this.isLoadingVenues,
      gameTitle: gameTitle ?? this.gameTitle,
      gameDescription: gameDescription ?? this.gameDescription,
      skillLevel: skillLevel ?? this.skillLevel,
      pricePerPlayer: pricePerPlayer ?? this.pricePerPlayer,
      isPublic: isPublic ?? this.isPublic,
      allowWaitlist: allowWaitlist ?? this.allowWaitlist,
      minPlayers: minPlayers ?? this.minPlayers,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      createdGame: createdGame ?? this.createdGame,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
    );
  }
}

class CreateGameController extends StateNotifier<CreateGameState> {
  final CreateGameUseCase _createGameUseCase;
  
  // Available options
  static const List<String> availableSports = [
    'basketball',
    'football',
    'tennis',
    'soccer',
    'volleyball',
    'badminton',
    'squash',
    'table_tennis',
    'cricket',
    'baseball',
  ];
  
  static const List<String> skillLevels = [
    'beginner',
    'intermediate', 
    'advanced',
    'mixed',
  ];

  CreateGameController({
    required CreateGameUseCase createGameUseCase,
  })  : _createGameUseCase = createGameUseCase,
        super(const CreateGameState());

  /// Step 1: Select Sport
  void selectSport(String sport) {
    if (!availableSports.contains(sport)) return;
    
    state = state.copyWith(
      selectedSport: sport,
      validationErrors: _clearErrorsForStep(CreateGameStep.sportSelection),
    );
    
    _calculateEstimatedValues();
  }

  /// Step 2: Set Date and Time
  void setDateTime({
    DateTime? date,
    String? startTime,
    String? endTime,
  }) {
    final errors = <String, String?>{};
    
    // Validate date (must be in future)
    if (date != null && date.isBefore(DateTime.now().add(const Duration(hours: 1)))) {
      errors['date'] = 'Game must be scheduled at least 1 hour in advance';
    }
    
    // Validate time format and logic
    if (startTime != null && !_isValidTimeFormat(startTime)) {
      errors['startTime'] = 'Please use HH:mm format (e.g., 14:30)';
    }
    
    if (endTime != null && !_isValidTimeFormat(endTime)) {
      errors['endTime'] = 'Please use HH:mm format (e.g., 16:30)';
    }
    
    if (startTime != null && endTime != null && _isValidTimeFormat(startTime) && _isValidTimeFormat(endTime)) {
      if (_timeStringToMinutes(endTime) <= _timeStringToMinutes(startTime)) {
        errors['endTime'] = 'End time must be after start time';
      }
      
      final durationMinutes = _timeStringToMinutes(endTime) - _timeStringToMinutes(startTime);
      if (durationMinutes < 30) {
        errors['duration'] = 'Game must be at least 30 minutes long';
      } else if (durationMinutes > 480) { // 8 hours
        errors['duration'] = 'Game cannot be longer than 8 hours';
      }
    }
    
    state = state.copyWith(
      selectedDate: date ?? state.selectedDate,
      startTime: startTime ?? state.startTime,
      endTime: endTime ?? state.endTime,
      estimatedDuration: (startTime != null && endTime != null && errors.isEmpty) 
          ? _timeStringToMinutes(endTime) - _timeStringToMinutes(startTime)
          : state.estimatedDuration,
      validationErrors: {...state.validationErrors, ...errors},
    );
    
    _calculateEstimatedValues();
  }

  /// Step 3: Select Venue (optional)
  void selectVenue(Venue? venue) {
    state = state.copyWith(
      selectedVenue: venue,
      validationErrors: _clearErrorsForStep(CreateGameStep.venueSelection),
    );
    
    _calculateEstimatedValues();
  }

  /// Load nearby venues based on location
  Future<void> loadNearbyVenues(double latitude, double longitude) async {
    state = state.copyWith(isLoadingVenues: true);
    
    try {
      // TODO: Implement venue loading from repository
      // For now, using placeholder
      await Future.delayed(const Duration(seconds: 1));
      
      state = state.copyWith(
        nearbyVenues: [], // TODO: Load from repository
        isLoadingVenues: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingVenues: false,
        error: 'Failed to load nearby venues: $e',
      );
    }
  }

  /// Step 4: Configure Game Details
  void configureGame({
    String? title,
    String? description,
    String? skillLevel,
    double? pricePerPlayer,
    bool? isPublic,
    bool? allowWaitlist,
  }) {
    final errors = <String, String?>{};
    
    // Validate title
    if (title != null) {
      if (title.isEmpty) {
        errors['title'] = 'Game title is required';
      } else if (title.length < 3) {
        errors['title'] = 'Title must be at least 3 characters';
      } else if (title.length > 100) {
        errors['title'] = 'Title must be less than 100 characters';
      }
    }
    
    // Validate description
    if (description != null && description.length > 500) {
      errors['description'] = 'Description must be less than 500 characters';
    }
    
    // Validate skill level
    if (skillLevel != null && !skillLevels.contains(skillLevel)) {
      errors['skillLevel'] = 'Please select a valid skill level';
    }
    
    // Validate price
    if (pricePerPlayer != null && pricePerPlayer < 0) {
      errors['pricePerPlayer'] = 'Price cannot be negative';
    }
    
    state = state.copyWith(
      gameTitle: title ?? state.gameTitle,
      gameDescription: description ?? state.gameDescription,
      skillLevel: skillLevel ?? state.skillLevel,
      pricePerPlayer: pricePerPlayer ?? state.pricePerPlayer,
      isPublic: isPublic ?? state.isPublic,
      allowWaitlist: allowWaitlist ?? state.allowWaitlist,
      validationErrors: {...state.validationErrors, ...errors},
    );
    
    _calculateEstimatedValues();
  }

  /// Step 5: Configure Player Settings
  void configurePlayerSettings({
    int? minPlayers,
    int? maxPlayers,
  }) {
    final errors = <String, String?>{};
    
    final newMinPlayers = minPlayers ?? state.minPlayers;
    final newMaxPlayers = maxPlayers ?? state.maxPlayers;
    
    // Validate player limits
    if (newMinPlayers < 1) {
      errors['minPlayers'] = 'Minimum players must be at least 1';
    }
    
    if (newMaxPlayers < newMinPlayers) {
      errors['maxPlayers'] = 'Maximum players must be greater than or equal to minimum';
    }
    
    if (newMaxPlayers > 50) {
      errors['maxPlayers'] = 'Maximum players cannot exceed 50';
    }
    
    // Sport-specific validation
    if (state.selectedSport != null) {
      final sportLimits = _getSportPlayerLimits(state.selectedSport!);
      if (newMaxPlayers < sportLimits['min']!) {
        errors['maxPlayers'] = 'For ${state.selectedSport}, you need at least ${sportLimits['min']} players';
      }
      if (newMaxPlayers > sportLimits['max']!) {
        errors['maxPlayers'] = 'For ${state.selectedSport}, maximum is ${sportLimits['max']} players';
      }
    }
    
    state = state.copyWith(
      minPlayers: newMinPlayers,
      maxPlayers: newMaxPlayers,
      validationErrors: {...state.validationErrors, ...errors},
    );
  }

  /// Navigate to next step
  void nextStep() {
    if (!state.canProceedToNext || state.isLastStep) return;
    
    final nextStepIndex = state.currentStep.index + 1;
    if (nextStepIndex < CreateGameStep.values.length) {
      state = state.copyWith(
        currentStep: CreateGameStep.values[nextStepIndex],
        error: null,
      );
    }
  }

  /// Navigate to previous step
  void previousStep() {
    if (state.isFirstStep) return;
    
    final previousStepIndex = state.currentStep.index - 1;
    if (previousStepIndex >= 0) {
      state = state.copyWith(
        currentStep: CreateGameStep.values[previousStepIndex],
        error: null,
      );
    }
  }

  /// Jump to specific step
  void goToStep(CreateGameStep step) {
    state = state.copyWith(
      currentStep: step,
      error: null,
    );
  }

  /// Step 6: Review and Create Game
  Future<void> reviewAndCreate(String organizerId) async {
    if (!_validateAllSteps()) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _createGameUseCase(CreateGameParams(
        title: state.gameTitle,
        description: state.gameDescription,
        sport: state.selectedSport!,
        scheduledDate: state.selectedDate!,
        startTime: state.startTime!,
        endTime: state.endTime!,
        minPlayers: state.minPlayers,
        maxPlayers: state.maxPlayers,
        organizerId: organizerId,
        skillLevel: state.skillLevel,
        pricePerPlayer: state.pricePerPlayer,
        venueId: state.selectedVenue?.id,
        isPublic: state.isPublic,
        allowsWaitlist: state.allowWaitlist,
      ));
      
      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            error: failure.message,
          );
        },
        (game) {
          state = state.copyWith(
            isLoading: false,
            isCreated: true,
            createdGame: game,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create game: $e',
      );
    }
  }

  /// Reset to start over
  void reset() {
    state = const CreateGameState();
  }

  /// Private helper methods

  Map<String, String?> _clearErrorsForStep(CreateGameStep step) {
    final errors = Map<String, String?>.from(state.validationErrors);
    
    // Clear errors relevant to this step
    switch (step) {
      case CreateGameStep.sportSelection:
        errors.remove('sport');
        break;
      case CreateGameStep.dateTimeSetup:
        errors.remove('date');
        errors.remove('startTime');
        errors.remove('endTime');
        errors.remove('duration');
        break;
      case CreateGameStep.venueSelection:
        errors.remove('venue');
        break;
      case CreateGameStep.gameConfiguration:
        errors.remove('title');
        errors.remove('description');
        errors.remove('skillLevel');
        errors.remove('pricePerPlayer');
        break;
      case CreateGameStep.playerSettings:
        errors.remove('minPlayers');
        errors.remove('maxPlayers');
        break;
      case CreateGameStep.reviewAndCreate:
        break;
    }
    
    return errors;
  }

  bool _isValidTimeFormat(String time) {
    final regex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    return regex.hasMatch(time);
  }

  int _timeStringToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  Map<String, int> _getSportPlayerLimits(String sport) {
    switch (sport.toLowerCase()) {
      case 'basketball':
        return {'min': 6, 'max': 12};
      case 'football':
        return {'min': 18, 'max': 30};
      case 'soccer':
        return {'min': 14, 'max': 24};
      case 'tennis':
        return {'min': 2, 'max': 4};
      case 'volleyball':
        return {'min': 8, 'max': 16};
      case 'badminton':
        return {'min': 2, 'max': 8};
      default:
        return {'min': 2, 'max': 20};
    }
  }

  void _calculateEstimatedValues() {
    double estimatedCost = 0.0;
    
    // Calculate venue cost if selected
    if (state.selectedVenue != null && state.startTime != null && state.endTime != null) {
      final durationHours = state.estimatedDuration / 60.0;
      estimatedCost += state.selectedVenue!.pricePerHour * durationHours;
    }
    
    // Add any additional costs based on sport, time, etc.
    // This could include equipment rental, facility fees, etc.
    
    state = state.copyWith(estimatedCost: estimatedCost);
  }

  bool _validateAllSteps() {
    final errors = <String, String>{};
    
    // Validate all required fields
    if (state.selectedSport == null || state.selectedSport!.isEmpty) {
      errors['sport'] = 'Please select a sport';
    }
    
    if (state.selectedDate == null) {
      errors['date'] = 'Please select a date';
    }
    
    if (state.startTime == null || state.endTime == null) {
      errors['time'] = 'Please set start and end times';
    }
    
    if (state.gameTitle.isEmpty) {
      errors['title'] = 'Please enter a game title';
    }
    
    if (errors.isNotEmpty) {
      state = state.copyWith(
        validationErrors: {...state.validationErrors, ...errors},
        error: 'Please fix the errors before creating the game',
      );
      return false;
    }
    
    return true;
  }
}
