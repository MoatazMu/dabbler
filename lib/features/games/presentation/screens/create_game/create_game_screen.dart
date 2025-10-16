import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'game_type_selection_screen.dart';
import 'datetime_selection_screen.dart';
import 'venue_selection_screen.dart';
import 'game_configuration_screen.dart';
import 'booking_confirmation_screen.dart';
import 'game_creation_success_screen.dart';

class CreateGameScreen extends ConsumerStatefulWidget {
  const CreateGameScreen({super.key});

  @override
  ConsumerState<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends ConsumerState<CreateGameScreen> {
  late PageController _pageController;
  int _currentStep = 0;
  bool _hasUnsavedChanges = false;
  
  // Game creation data
  final Map<String, dynamic> _gameData = {
    'sport': null,
    'date': null,
    'startTime': null,
    'endTime': null,
    'venue': null,
    'title': '',
    'description': '',
    'minPlayers': 2,
    'maxPlayers': 10,
    'skillLevel': 'Mixed',
    'pricePerPlayer': 0.0,
    'isPublic': true,
    'allowWaitlist': true,
  };

  final List<String> _stepTitles = [
    'Choose Sport',
    'Select Date & Time',
    'Pick Venue',
    'Game Details',
    'Review & Book',
    'Success!',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (_hasUnsavedChanges && _currentStep > 0) {
          final shouldPop = await _showExitConfirmation();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  GameTypeSelectionScreen(
                    onSportSelected: _onSportSelected,
                    selectedSport: _gameData['sport'],
                  ),
                  DateTimeSelectionScreen(
                    onDateTimeSelected: _onDateTimeSelected,
                    selectedDate: _gameData['date'],
                    selectedStartTime: _gameData['startTime'],
                    selectedEndTime: _gameData['endTime'],
                    sport: _gameData['sport'],
                  ),
                  VenueSelectionScreen(
                    onVenueSelected: _onVenueSelected,
                    selectedVenue: _gameData['venue'],
                    sport: _gameData['sport'],
                    date: _gameData['date'],
                    startTime: _gameData['startTime'],
                    endTime: _gameData['endTime'],
                  ),
                  GameConfigurationScreen(
                    onConfigurationChanged: _onConfigurationChanged,
                    gameData: _gameData,
                  ),
                  BookingConfirmationScreen(
                    gameData: _gameData,
                    onBookingConfirmed: _onBookingConfirmed,
                  ),
                  GameCreationSuccessScreen(
                    gameData: _gameData,
                    onCreateAnother: _onCreateAnother,
                    onViewGame: _onViewGame,
                    onGoHome: _onGoHome,
                  ),
                ],
              ),
            ),
            if (_currentStep < 4) _buildNavigationBar(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_stepTitles[_currentStep]),
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      actions: [
        if (_currentStep > 0 && _currentStep < 4)
          TextButton(
            onPressed: _saveDraft,
            child: const Text('Save Draft'),
          ),
        if (_hasUnsavedChanges)
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'save_draft',
                child: ListTile(
                  leading: Icon(Icons.save),
                  title: Text('Save Draft'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: ListTile(
                  leading: Icon(Icons.clear_all),
                  title: Text('Clear All'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'save_draft':
                  _saveDraft();
                  break;
                case 'clear_all':
                  _clearAll();
                  break;
              }
            },
          ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[50],
      child: Row(
        children: List.generate(_stepTitles.length - 1, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? Colors.green
                              : isActive
                                  ? Colors.blue
                                  : Colors.grey[300],
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, color: Colors.white, size: 18)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isActive ? Colors.white : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _stepTitles[index],
                        style: TextStyle(
                          fontSize: 10,
                          color: isActive ? Colors.blue : Colors.grey[600],
                          fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (index < _stepTitles.length - 2)
                  Container(
                    height: 2,
                    width: 20,
                    color: isCompleted ? Colors.green : Colors.grey[300],
                    margin: const EdgeInsets.only(bottom: 20),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavigationBar() {
    final canGoBack = _currentStep > 0;
    final canGoNext = _canProceedToNextStep();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (canGoBack)
              Expanded(
                child: OutlinedButton(
                  onPressed: _goBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Back'),
                ),
              )
            else
              const Spacer(),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: canGoNext ? _goNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _getNextButtonText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0:
        return _gameData['sport'] != null;
      case 1:
        return _gameData['date'] != null && 
               _gameData['startTime'] != null && 
               _gameData['endTime'] != null;
      case 2:
        return true; // Venue is optional
      case 3:
        return _gameData['title']?.isNotEmpty == true &&
               _gameData['minPlayers'] != null &&
               _gameData['maxPlayers'] != null;
      default:
        return false;
    }
  }

  String _getNextButtonText() {
    switch (_currentStep) {
      case 0:
        return 'Continue';
      case 1:
        return 'Choose Venue';
      case 2:
        return 'Game Details';
      case 3:
        return 'Review & Book';
      default:
        return 'Next';
    }
  }

  void _goNext() {
    if (_canProceedToNextStep() && _currentStep < 4) {
      setState(() {
        _hasUnsavedChanges = true;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onSportSelected(String sport) {
    setState(() {
      _gameData['sport'] = sport;
      _hasUnsavedChanges = true;
      // Set smart defaults based on sport
      _setDefaultsForSport(sport);
    });
  }

  void _onDateTimeSelected(DateTime date, TimeOfDay startTime, TimeOfDay endTime) {
    setState(() {
      _gameData['date'] = date;
      _gameData['startTime'] = startTime;
      _gameData['endTime'] = endTime;
      _hasUnsavedChanges = true;
    });
  }

  void _onVenueSelected(Map<String, dynamic>? venue) {
    setState(() {
      _gameData['venue'] = venue;
      _hasUnsavedChanges = true;
    });
  }

  void _onConfigurationChanged(Map<String, dynamic> config) {
    setState(() {
      _gameData.addAll(config);
      _hasUnsavedChanges = true;
    });
  }

  void _onBookingConfirmed(Map<String, dynamic> bookingData) {
    // Navigate to success screen
    _pageController.animateToPage(
      5,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() {
      _hasUnsavedChanges = false;
    });
  }

  void _onCreateAnother() {
    // Reset all data and go back to step 1
    setState(() {
      _gameData.clear();
      _gameData.addAll({
        'sport': null,
        'date': null,
        'startTime': null,
        'endTime': null,
        'venue': null,
        'title': '',
        'description': '',
        'minPlayers': 2,
        'maxPlayers': 10,
        'skillLevel': 'Mixed',
        'pricePerPlayer': 0.0,
        'isPublic': true,
        'allowWaitlist': true,
      });
      _hasUnsavedChanges = false;
    });
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onViewGame() {
    // After creation, send user to My Games with the new game pre-inserted
    final newGame = <String, dynamic>{
      'id': _gameData['bookingId'] ?? _gameData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'title': _gameData['title'] ?? '${_gameData['sport'] ?? 'Game'}',
      'sport': _gameData['sport'] ?? 'Game',
      'date': _gameData['date'] ?? DateTime.now(),
      'time': _gameData['time'] ?? _formatTime(_gameData['startTime']),
      'venue': _gameData['venue'] ?? {'name': 'TBD', 'distance': ''},
      'players': {
        'current': (_gameData['minPlayers'] is int) ? _gameData['minPlayers'] : 1,
        'max': (_gameData['maxPlayers'] is int) ? _gameData['maxPlayers'] : 10,
      },
      'isOrganizer': true,
      'status': 'confirmed',
    };

  if (!mounted) return;
  // Replace flow with My Games and pass the newly created game
  context.go('/games/my-games', extra: {'newGame': newGame});
  }

  void _onGoHome() {
    // Navigate back to home screen
    Navigator.of(context).pushReplacementNamed('/');
  }

  String _formatTime(dynamic timeOfDay) {
    if (timeOfDay is TimeOfDay) {
      final h = timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod;
      final m = timeOfDay.minute.toString().padLeft(2, '0');
      final suffix = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
      return '$h:$m $suffix';
    }
    if (timeOfDay is String) return timeOfDay;
    return 'Time TBD';
  }

  void _setDefaultsForSport(String sport) {
    switch (sport.toLowerCase()) {
      case 'basketball':
        _gameData['minPlayers'] = 6;
        _gameData['maxPlayers'] = 10;
        break;
      case 'soccer':
      case 'football':
        _gameData['minPlayers'] = 10;
        _gameData['maxPlayers'] = 22;
        break;
      case 'tennis':
        _gameData['minPlayers'] = 2;
        _gameData['maxPlayers'] = 4;
        break;
      case 'volleyball':
        _gameData['minPlayers'] = 6;
        _gameData['maxPlayers'] = 12;
        break;
      default:
        _gameData['minPlayers'] = 2;
        _gameData['maxPlayers'] = 10;
    }
  }

  void _saveDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Draft saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('Are you sure you want to clear all entered data? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _gameData.clear();
                _gameData.addAll({
                  'sport': null,
                  'date': null,
                  'startTime': null,
                  'endTime': null,
                  'venue': null,
                  'title': '',
                  'description': '',
                  'minPlayers': 2,
                  'maxPlayers': 10,
                  'skillLevel': 'Mixed',
                  'pricePerPlayer': 0.0,
                  'isPublic': true,
                  'allowWaitlist': true,
                });
                _hasUnsavedChanges = false;
              });
              Navigator.pop(context);
              _pageController.animateToPage(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<bool> _showExitConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Game Creation'),
        content: const Text('You have unsaved changes. Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save Draft & Exit'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Exit Without Saving', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
