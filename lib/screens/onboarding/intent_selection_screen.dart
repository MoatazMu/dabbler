import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/constants/route_constants.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/onboarding_progress.dart';
import 'create_user_information.dart' show RegistrationData;

class IntentSelectionScreen extends StatefulWidget {
  final RegistrationData? registrationData;
  
  const IntentSelectionScreen({
    super.key,
    this.registrationData,
  });

  @override
  State<IntentSelectionScreen> createState() => _IntentSelectionScreenState();
}

class _IntentSelectionScreenState extends State<IntentSelectionScreen> {
  String? _selectedIntent;
  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadExistingUserData();
  }

  Future<void> _loadExistingUserData() async {
    try {
      print('🎯 [DEBUG] IntentSelectionScreen: Loading existing user data');
      
      // Check if we have registration data from previous step
      if (widget.registrationData?.intent != null && widget.registrationData!.intent!.isNotEmpty) {
        print('✅ [DEBUG] IntentSelectionScreen: Found intent in registration data: ${widget.registrationData!.intent}');
        setState(() {
          _selectedIntent = widget.registrationData!.intent;
        });
      } else {
        print('🆕 [DEBUG] IntentSelectionScreen: No existing intent data, starting fresh');
      }
    } catch (e) {
      print('❌ [DEBUG] IntentSelectionScreen: Error loading existing data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  void _selectIntent(String intent) {
    setState(() {
      _selectedIntent = intent;
    });
  }

  Future<void> _handleSubmit() async {
    if (_selectedIntent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your intent'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('🎯 [DEBUG] IntentSelectionScreen: Collecting intent preferences');
      print('📋 [DEBUG] IntentSelectionScreen: Selected intent: $_selectedIntent');

      // Get registration data from previous step and add intent
      final registrationData = widget.registrationData?.copyWith(intent: _selectedIntent);
      
      print('✅ [DEBUG] IntentSelectionScreen: Intent preferences collected successfully');
      print('📧 [DEBUG] IntentSelectionScreen: Email for password creation: ${registrationData?.email}');

      if (mounted) {
        // Navigate to password creation screen with complete registration data
        context.go(RoutePaths.setPassword, extra: registrationData?.toMap());
      }
    } catch (e) {
      print('❌ [DEBUG] IntentSelectionScreen: Error collecting intent preferences: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSkip() async {
    setState(() => _isLoading = true);

    try {
      print('🎯 [DEBUG] IntentSelectionScreen: Skipping intent selection, using default');
      
      // Use default intent (casual) and get registration data from previous step
      final registrationData = widget.registrationData?.copyWith(intent: 'casual');
      
      print('✅ [DEBUG] IntentSelectionScreen: Using default intent: casual');
      print('📧 [DEBUG] IntentSelectionScreen: Email for password creation: ${registrationData?.email}');
      
      if (mounted) {
        // Navigate to password creation screen with complete registration data
        context.go(RoutePaths.setPassword, extra: registrationData?.toMap());
      }
    } catch (e) {
      print('❌ [DEBUG] IntentSelectionScreen: Error in skip: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Intent'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Onboarding Progress
            OnboardingProgress(),
            
            // Main Content
            Expanded(
              child: _isLoadingData
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 32),
                          
                          // Header
                          Text(
                            'What\'s your main goal?',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Text(
                            'Help us find the right matches for you',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Intent Options
                          ...AppConstants.availableIntents.map((intent) {
                            final isSelected = _selectedIntent == intent;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () => _selectIntent(intent),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.blue[50] : Colors.grey[50],
                                    border: Border.all(
                                      color: isSelected ? Colors.blue : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getIntentIcon(intent),
                                        size: 24,
                                        color: isSelected ? Colors.blue[700] : Colors.grey[600],
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppHelpers.getIntentDisplayName(intent),
                                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                color: isSelected ? Colors.blue[700] : Colors.grey[700],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _getIntentDescription(intent),
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          size: 20,
                                          color: Colors.blue[700],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                          
                          const SizedBox(height: 32),
                          
                          // Continue Button
                          CustomButton(
                            onPressed: _isLoading ? null : _handleSubmit,
                            text: _isLoading ? 'Continuing...' : 'Continue to Password',
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Skip Button
                          TextButton(
                            onPressed: _isLoading ? null : _handleSkip,
                            child: Text(
                              _isLoading ? 'Continuing...' : 'Skip for now',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIntentIcon(String intent) {
    switch (intent.toLowerCase()) {
      case 'competitive':
        return Icons.emoji_events;
      case 'casual':
        return Icons.sports_soccer;
      case 'training':
        return Icons.fitness_center;
      case 'social':
        return Icons.people;
      case 'fitness':
        return Icons.directions_run;
      default:
        return Icons.sports;
    }
  }

  String _getIntentDescription(String intent) {
    switch (intent.toLowerCase()) {
      case 'competitive':
        return 'Looking for serious matches and tournaments';
      case 'casual':
        return 'Just want to have fun and play for enjoyment';
      case 'training':
        return 'Focus on improving skills and technique';
      case 'social':
        return 'Meet new people and make friends';
      case 'fitness':
        return 'Stay active and get a good workout';
      default:
        return 'General sports participation';
    }
  }
}
