import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dabbler/data/models/core/game_creation_model.dart';
import '../services/storage_service.dart';
import '../../features/games/domain/repositories/games_repository.dart';
import '../../features/games/data/repositories/games_repository_impl.dart';
import '../../features/games/data/datasources/supabase_games_datasource.dart';
import '../../routes/route_arguments.dart';

class GameCreationViewModel extends ChangeNotifier {
  GameCreationModel _state = GameCreationModel.initial();
  final StorageService _storageService = StorageService();
  late final GamesRepository _gamesRepository;

  // Available venues for demo - in real app this would come from API
  List<VenueSlot> _availableVenues = [];
  List<String> _recentTeammates = [];

  GameCreationViewModel() {
    // Initialize the repository
    final supabase = Supabase.instance.client;
    final dataSource = SupabaseGamesDataSource(supabase);
    _gamesRepository = GamesRepositoryImpl(remoteDataSource: dataSource);
  }

  GameCreationModel get state => _state;
  List<VenueSlot> get availableVenues => List.unmodifiable(_availableVenues);
  List<String> get recentTeammates => List.unmodifiable(_recentTeammates);

  // Step navigation
  void nextStep() {
    if (_state.canProceedToNextStep && _state.nextStep != null) {
      _state = _state.copyWith(currentStep: _state.nextStep);

      // Load data for next step
      _loadDataForCurrentStep();
      notifyListeners();
    }
  }

  void previousStep() {
    if (_state.previousStep != null) {
      _state = _state.copyWith(currentStep: _state.previousStep);
      notifyListeners();
    }
  }

  void goToStep(GameCreationStep step) {
    _state = _state.copyWith(currentStep: step);
    _loadDataForCurrentStep();
    notifyListeners();
  }

  // Save draft functionality with step-specific state
  Future<void> saveAsDraft({Map<String, dynamic>? stepLocalState}) async {
    if (!_state.canSaveAsDraft) return;

    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final draftId = _state.draftId ?? _generateDraftId();
      final draftData = _state.copyWith(
        draftId: draftId,
        lastSaved: DateTime.now(),
        isDraft: true,
        stepLocalState: stepLocalState,
      );

      await _storageService.saveDraft(draftId, draftData.toJson());

      _state = draftData.copyWith(isLoading: false);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Failed to save draft: $e',
      );
      notifyListeners();
    }
  }

  // Auto-save draft when significant changes are made
  Future<void> autoSaveDraft({Map<String, dynamic>? stepLocalState}) async {
    if (!_state.canSaveAsDraft) return;

    // Auto-save without showing loading state
    try {
      final draftId = _state.draftId ?? _generateDraftId();
      final draftData = _state.copyWith(
        draftId: draftId,
        lastSaved: DateTime.now(),
        isDraft: true,
        stepLocalState: stepLocalState,
      );

      await _storageService.saveDraft(draftId, draftData.toJson());
      _state = draftData;
      // Don't notify listeners for auto-save to avoid UI flicker
    } catch (e) {
      // Silently handle auto-save errors
    }
  }

  Future<List<Map<String, dynamic>>> getSavedDrafts() async {
    try {
      return await _storageService.getSavedDrafts();
    } catch (e) {
      return [];
    }
  }

  Future<void> loadDraft(String draftId) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final draftData = await _storageService.loadDraft(draftId);
      if (draftData != null) {
        // Reconstruct GameFormat from saved data
        GameFormat? reconstructedFormat;
        if (draftData['selectedSport'] != null &&
            draftData['selectedFormat'] != null) {
          reconstructedFormat = _reconstructGameFormat(
            draftData['selectedSport'],
            draftData['selectedFormat'],
          );
        }

        _state = _state.copyWith(
          // Restore current step
          currentStep: draftData['currentStep'] != null
              ? GameCreationStep.values.firstWhere(
                  (e) => e.name == draftData['currentStep'],
                )
              : GameCreationStep.sportAndFormat,

          // Sport & Format Selection
          selectedSport: draftData['selectedSport'],
          selectedFormat: reconstructedFormat,
          skillLevel: draftData['skillLevel'],
          maxPlayers: draftData['maxPlayers'],
          gameDuration: draftData['gameDuration'],

          // Venue & Slot Selection
          selectedVenueSlot: draftData['selectedVenueSlot'] != null
              ? _reconstructVenueSlot(draftData['selectedVenueSlot'])
              : null,
          amenityFilters: draftData['amenityFilters']?.cast<String>(),

          // Participation & Payment
          participationMode: draftData['participationMode'] != null
              ? ParticipationMode.values.firstWhere(
                  (e) => e.name == draftData['participationMode'],
                )
              : null,
          paymentSplit: draftData['paymentSplit'] != null
              ? PaymentSplit.values.firstWhere(
                  (e) => e.name == draftData['paymentSplit'],
                )
              : null,
          gameDescription: draftData['gameDescription'],
          allowWaitlist: draftData['allowWaitlist'],
          maxWaitlistSize: draftData['maxWaitlistSize'],
          totalCost: draftData['totalCost'],

          // Player Invitation
          invitedPlayerIds: draftData['invitedPlayerIds']?.cast<String>(),
          invitedPlayerEmails: draftData['invitedPlayerEmails']?.cast<String>(),
          allowFriendsToInvite: draftData['allowFriendsToInvite'],
          invitationMessage: draftData['invitationMessage'],

          // Review & Confirm
          gameTitle: draftData['gameTitle'],
          agreeToTerms: draftData['agreeToTerms'],
          sendReminders: draftData['sendReminders'],

          // Step-specific local state
          selectedDate: draftData['selectedDate'] != null
              ? DateTime.parse(draftData['selectedDate'])
              : null,
          selectedTimeSlot: draftData['selectedTimeSlot'],
          selectedPlayers: draftData['selectedPlayers']?.cast<String>(),
          stepLocalState: draftData['stepLocalState'],

          // Draft metadata
          draftId: draftId,
          isDraft: true,
          lastSaved: draftData['lastSaved'] != null
              ? DateTime.parse(draftData['lastSaved'])
              : null,
          isLoading: false,
        );

        // Load data for the current step
        _loadDataForCurrentStep();
      }
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Failed to load draft: $e',
      );
    }
    notifyListeners();
  }

  /// Apply initial values based on an existing booking seed.
  void applyBookingSeed(BookingSeedData seed) {
    final slot = _buildSeedVenueSlot(seed);
    final inferredTitle =
        _state.gameTitle ?? '${seed.sport} at ${seed.venueName}';

    _state = _state.copyWith(
      selectedSport: seed.sport,
      selectedDate: seed.date,
      selectedTimeSlot: seed.timeLabel,
      selectedVenueSlot: slot ?? _state.selectedVenueSlot,
      gameTitle: inferredTitle,
    );
    notifyListeners();
  }

  VenueSlot? _buildSeedVenueSlot(BookingSeedData seed) {
    final venueId = seed.venueId;
    if (venueId == null || venueId.isEmpty) {
      return null;
    }

    final timeSlot = _buildSeedTimeSlot(seed.date, seed.timeLabel);
    return VenueSlot(
      venueId: venueId,
      venueName: seed.venueName,
      location: seed.venueLocation ?? '',
      timeSlot: timeSlot,
      amenities: null,
      rating: 0,
      imageUrl: null,
    );
  }

  TimeSlot _buildSeedTimeSlot(DateTime date, String label) {
    final parts = label.split('-').map((value) => value.trim()).toList();
    final startTime = _parseSeedTime(parts.isNotEmpty ? parts.first : label);
    final endTime = parts.length > 1 ? _parseSeedTime(parts[1]) : null;

    final startDateTime = startTime != null
        ? DateTime(
            date.year,
            date.month,
            date.day,
            startTime.hour,
            startTime.minute,
          )
        : DateTime(date.year, date.month, date.day, 9);

    final calculatedEnd = endTime != null
        ? DateTime(
            date.year,
            date.month,
            date.day,
            endTime.hour,
            endTime.minute,
          )
        : startDateTime.add(const Duration(hours: 1));

    final duration = calculatedEnd.isAfter(startDateTime)
        ? calculatedEnd.difference(startDateTime)
        : const Duration(hours: 1);

    return TimeSlot(
      startTime: startDateTime,
      duration: duration,
      price: 0,
      isAvailable: true,
    );
  }

  TimeOfDay? _parseSeedTime(String value) {
    var trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    String? period;
    final lower = trimmed.toLowerCase();
    if (lower.endsWith('am')) {
      period = 'am';
      trimmed = trimmed.substring(0, trimmed.length - 2).trim();
    } else if (lower.endsWith('pm')) {
      period = 'pm';
      trimmed = trimmed.substring(0, trimmed.length - 2).trim();
    }

    final parts = trimmed.split(':');
    final hourPart = parts.isNotEmpty ? parts[0] : trimmed;
    final minutePart = parts.length > 1 ? parts[1] : '0';

    final parsedHour = int.tryParse(hourPart);
    final parsedMinute = int.tryParse(minutePart);
    if (parsedHour == null || parsedMinute == null) {
      return null;
    }

    var hour = parsedHour.clamp(0, 24);
    final minute = parsedMinute.clamp(0, 59);

    if (period == 'pm' && hour < 12) {
      hour += 12;
    } else if (period == 'am' && hour == 12) {
      hour = 0;
    }

    if (hour >= 24) {
      hour = hour % 24;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> deleteDraft(String draftId) async {
    try {
      await _storageService.deleteDraft(draftId);
    } catch (e) {
      // Handle error silently for now
    }
  }

  String _generateDraftId() {
    return 'draft_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Step 1: Sport & Format Selection
  void selectSport(String sport) {
    _state = _state.copyWith(
      selectedSport: sport,
      selectedFormat: null, // Don't pre-select format
      maxPlayers: null, // Reset to null until format is selected
      gameDuration: null, // Reset to null until format is selected
    );
    notifyListeners();

    // Auto-save after sport selection
    autoSaveDraft();
  }

  void selectGameFormat(GameFormat format) {
    _state = _state.copyWith(
      selectedFormat: format,
      maxPlayers: format.totalPlayers,
      gameDuration: format.defaultDuration.inMinutes,
    );
    notifyListeners();

    // Auto-save after format selection
    autoSaveDraft();
  }

  void updateGameDuration(int durationMinutes) {
    _state = _state.copyWith(gameDuration: durationMinutes);
    notifyListeners();

    // Auto-save after duration update
    autoSaveDraft();
  }

  void selectSkillLevel(String skillLevel) {
    _state = _state.copyWith(skillLevel: skillLevel);
    notifyListeners();

    // Auto-save after skill level selection
    autoSaveDraft();
  }

  void updateMaxPlayers(int count) {
    _state = _state.copyWith(maxPlayers: count);
    notifyListeners();
  }

  // Step 2: Venue & Slot Selection
  Future<void> loadAvailableVenues() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      // Fetch real venues from database
      final response = await Supabase.instance.client
          .from('venues')
          .select()
          .order('name');

      if (response.isNotEmpty) {
        _availableVenues = response.map((venueData) {
          // Create VenueSlot from database data
          // Note: This needs to be updated to fetch actual time slots from bookings
          final tomorrow = DateTime.now().add(const Duration(days: 1));
          return VenueSlot(
            venueId: venueData['id'].toString(),
            venueName: venueData['name'] ?? 'Unknown Venue',
            location: venueData['address'] ?? '',
            rating: (venueData['rating'] ?? 0.0).toDouble(),
            timeSlot: TimeSlot(
              startTime: tomorrow.copyWith(hour: 18, minute: 0),
              duration: const Duration(hours: 2),
              price: (venueData['base_price'] ?? 0.0).toDouble(),
            ),
            amenities: venueData['amenities'],
          );
        }).toList();
      } else {
        _availableVenues = [];
      }

      _state = _state.copyWith(isLoading: false, error: null);
    } catch (e) {
      print('❌ Error loading venues: $e');
      _state = _state.copyWith(
        isLoading: false,
        error: 'Failed to load venues: $e',
      );
      _availableVenues = [];
    }
    notifyListeners();
  }

  void selectVenueSlot(VenueSlot venueSlot) {
    _state = _state.copyWith(
      selectedVenueSlot: venueSlot,
      totalCost: venueSlot.timeSlot.price,
    );
    notifyListeners();
  }

  void updateVenueFilters(List<String> filters) {
    _state = _state.copyWith(venueFilters: filters);
    // Re-filter venues based on new filters
    notifyListeners();
  }

  void updateMaxDistance(double distance) {
    _state = _state.copyWith(maxDistance: distance);
    notifyListeners();
  }

  // Step 3: Participation & Payment
  void selectParticipationMode(ParticipationMode mode) {
    _state = _state.copyWith(participationMode: mode);
    notifyListeners();
  }

  void selectPaymentSplit(PaymentSplit split) {
    _state = _state.copyWith(paymentSplit: split);
    _recalculatePayments();
    notifyListeners();
  }

  void updateGameDescription(String description) {
    _state = _state.copyWith(gameDescription: description);
    notifyListeners();
  }

  void toggleWaitlist(bool allow) {
    _state = _state.copyWith(allowWaitlist: allow);
    notifyListeners();
  }

  void updateMaxWaitlistSize(int size) {
    _state = _state.copyWith(maxWaitlistSize: size);
    notifyListeners();
  }

  void updateCustomPaymentSplit(Map<String, double> split) {
    _state = _state.copyWith(customPaymentSplit: split);
    notifyListeners();
  }

  // Step 4: Player Invitation
  Future<void> loadRecentTeammates() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      _recentTeammates = [
        'Ahmed Mohamed',
        'Sarah Johnson',
        'Carlos Rodriguez',
        'Fatima Al-Zahra',
        'Mike Wilson',
        'Layla Hassan',
        'David Kim',
        'Nour Abdullah',
      ];

      _state = _state.copyWith(isLoading: false, error: null);
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Failed to load teammates: $e',
      );
    }
    notifyListeners();
  }

  void addInvitedPlayer(String playerId) {
    final currentList = _state.invitedPlayerIds ?? [];
    if (!currentList.contains(playerId)) {
      _state = _state.copyWith(invitedPlayerIds: [...currentList, playerId]);
      notifyListeners();
    }
  }

  void removeInvitedPlayer(String playerId) {
    final currentList = _state.invitedPlayerIds ?? [];
    _state = _state.copyWith(
      invitedPlayerIds: currentList.where((id) => id != playerId).toList(),
    );
    notifyListeners();
  }

  void addInvitedEmail(String email) {
    final currentList = _state.invitedPlayerEmails ?? [];
    if (!currentList.contains(email)) {
      _state = _state.copyWith(invitedPlayerEmails: [...currentList, email]);
      notifyListeners();
    }
  }

  void removeInvitedEmail(String email) {
    final currentList = _state.invitedPlayerEmails ?? [];
    _state = _state.copyWith(
      invitedPlayerEmails: currentList.where((e) => e != email).toList(),
    );
    notifyListeners();
  }

  void updateInvitationMessage(String message) {
    _state = _state.copyWith(invitationMessage: message);
    notifyListeners();
  }

  void toggleAllowFriendsToInvite(bool allow) {
    _state = _state.copyWith(allowFriendsToInvite: allow);
    notifyListeners();
  }

  // Step 5: Review & Confirm
  void updateGameTitle(String title) {
    _state = _state.copyWith(gameTitle: title);
    notifyListeners();
  }

  void updateTermsAgreement(bool agree) {
    _state = _state.copyWith(agreeToTerms: agree);
    notifyListeners();
  }

  void updateGameReminders(bool sendReminders) {
    _state = _state.copyWith(sendReminders: sendReminders);
    notifyListeners();
  }

  void updateReminderTime(DateTime reminderTime) {
    _state = _state.copyWith(reminderTime: reminderTime);
    notifyListeners();
  }

  // Final game creation
  Future<bool> createGame() async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      // Get current user ID
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Validate required fields
      if (_state.gameTitle == null || _state.gameTitle!.isEmpty) {
        throw Exception('Game title is required');
      }
      if (_state.selectedSport == null) {
        throw Exception('Sport selection is required');
      }
      if (_state.selectedDate == null) {
        throw Exception('Game date is required');
      }
      if (_state.selectedVenueSlot?.timeSlot.startTime == null) {
        throw Exception('Start time is required');
      }
      if (_state.selectedVenueSlot?.timeSlot.endTime == null) {
        throw Exception('End time is required');
      }
      if (_state.maxPlayers == null) {
        throw Exception('Maximum players is required');
      }
      if (_state.totalCost == null) {
        throw Exception('Price is required');
      }
      if (_state.skillLevel == null) {
        throw Exception('Skill level is required');
      }
      if (_state.participationMode == null) {
        throw Exception('Participation mode is required');
      }
      if (_state.allowWaitlist == null) {
        throw Exception('Waitlist preference is required');
      }

      // Prepare game data for database - ONLY USER-PROVIDED DATA
      final gameData = <String, dynamic>{
        'title': _state.gameTitle!,
        'sport': _state.selectedSport!,
        'scheduled_date': _state.selectedDate!.toIso8601String().split('T')[0],
        'start_time':
            '${_state.selectedVenueSlot!.timeSlot.startTime.hour.toString().padLeft(2, '0')}:${_state.selectedVenueSlot!.timeSlot.startTime.minute.toString().padLeft(2, '0')}',
        'end_time':
            '${_state.selectedVenueSlot!.timeSlot.endTime.hour.toString().padLeft(2, '0')}:${_state.selectedVenueSlot!.timeSlot.endTime.minute.toString().padLeft(2, '0')}',
        'max_players': _state.maxPlayers!,
        'organizer_id': user.id,
        'skill_level': _state.skillLevel!,
        'price_per_player': _state.totalCost!.toDouble(),
        'is_public': _state.participationMode == ParticipationMode.public,
        'allows_waitlist': _state.allowWaitlist!,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add optional fields only if provided by user
      if (_state.gameDescription != null &&
          _state.gameDescription!.isNotEmpty) {
        gameData['description'] = _state.gameDescription;
      }

      // Add venue_id if selected and is a valid UUID format
      if (_state.selectedVenueSlot?.venueId != null) {
        final venueId = _state.selectedVenueSlot!.venueId;
        // Check if it's a valid UUID (contains hyphens and is proper length)
        if (venueId.contains('-') && venueId.length >= 36) {
          gameData['venue_id'] = venueId;
        }
      }

      print('🎮 Creating game with data: $gameData');

      // Create game via repository
      final result = await _gamesRepository.createGame(gameData);

      result.fold(
        (failure) {
          print('❌ Failed to create game: ${failure.message}');
          throw Exception(failure.message);
        },
        (game) {
          print('✅ Game created successfully with ID: ${game.id}');
        },
      );

      // If this was a draft, delete it after successful creation
      if (_state.isDraft && _state.draftId != null) {
        await deleteDraft(_state.draftId!);
      }

      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      print('❌ Exception in createGame: $e');
      print('Stack trace: $stackTrace');
      _state = _state.copyWith(
        isLoading: false,
        error: 'Failed to create game: $e',
      );
      notifyListeners();
      return false;
    }
  }

  // Reset to initial state
  void reset() {
    _state = GameCreationModel.initial();
    _availableVenues = [];
    _recentTeammates = [];
    notifyListeners();
  }

  // Private helper methods
  void _loadDataForCurrentStep() {
    switch (_state.currentStep) {
      case GameCreationStep.venueAndSlot:
        loadAvailableVenues();
        break;
      case GameCreationStep.playerInvitation:
        loadRecentTeammates();
        break;
      default:
        break;
    }
  }

  void _recalculatePayments() {
    if (_state.selectedVenueSlot == null || _state.paymentSplit == null) return;

    final venueCost = _state.selectedVenueSlot!.timeSlot.price;
    final playerCount = _state.maxPlayers ?? 1;

    double totalCost = venueCost;

    switch (_state.paymentSplit!) {
      case PaymentSplit.organizer:
        totalCost = venueCost;
        break;
      case PaymentSplit.equal:
        totalCost = venueCost / playerCount;
        break;
      case PaymentSplit.perPlayer:
        totalCost = venueCost / playerCount;
        break;
      case PaymentSplit.custom:
        // Custom split would be calculated based on customPaymentSplit map
        totalCost = venueCost;
        break;
    }

    _state = _state.copyWith(totalCost: totalCost);
  }

  // Helper method to reconstruct GameFormat from saved data
  GameFormat? _reconstructGameFormat(String sport, String formatName) {
    try {
      switch (sport.toLowerCase()) {
        case 'football':
          return FootballFormat.allFormats.firstWhere(
            (f) => f.name == formatName,
          );
        case 'cricket':
          return CricketFormat.allFormats.firstWhere(
            (f) => f.name == formatName,
          );
        case 'padel':
          return PadelFormat.allFormats.firstWhere((f) => f.name == formatName);
        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Helper method to reconstruct VenueSlot from saved data
  VenueSlot? _reconstructVenueSlot(Map<String, dynamic> venueData) {
    try {
      final timeSlotData = venueData['timeSlot'];
      final timeSlot = TimeSlot(
        startTime: DateTime.parse(timeSlotData['startTime']),
        duration: Duration(minutes: timeSlotData['duration']),
        price: timeSlotData['price']?.toDouble() ?? 0.0,
        isAvailable: timeSlotData['isAvailable'] ?? true,
        restrictions: timeSlotData['restrictions']?.cast<String>() ?? [],
      );

      return VenueSlot(
        venueId: venueData['venueId'],
        venueName: venueData['venueName'],
        location: venueData['location'],
        timeSlot: timeSlot,
        amenities: venueData['amenities']?.cast<String>() ?? [],
        rating: venueData['rating']?.toDouble() ?? 0.0,
        imageUrl: venueData['imageUrl'],
      );
    } catch (e) {
      return null;
    }
  }

  // Step-specific state management for draft resume
  void updateStepLocalState(Map<String, dynamic> localState) {
    _state = _state.copyWith(
      stepLocalState: {..._state.stepLocalState ?? {}, ...localState},
    );

    // Auto-save step-specific state
    autoSaveDraft(stepLocalState: _state.stepLocalState);
  }

  void updateSelectedDate(DateTime date) {
    _state = _state.copyWith(selectedDate: date);
    notifyListeners();

    // Auto-save date selection
    autoSaveDraft();
  }

  void updateSelectedTimeSlot(String timeSlot) {
    _state = _state.copyWith(selectedTimeSlot: timeSlot);
    notifyListeners();

    // Auto-save time slot selection
    autoSaveDraft();
  }

  void updateSelectedPlayers(List<String> players) {
    _state = _state.copyWith(selectedPlayers: players);
    notifyListeners();

    // Auto-save player selection
    autoSaveDraft();
  }
}
