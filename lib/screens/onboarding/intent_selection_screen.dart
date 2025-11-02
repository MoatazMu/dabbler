import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants/route_constants.dart';
import '../../core/utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/onboarding_progress.dart';
import '../../features/authentication/presentation/providers/onboarding_data_provider.dart';

class IntentSelectionScreen extends ConsumerStatefulWidget {
  const IntentSelectionScreen({super.key});

  @override
  ConsumerState<IntentSelectionScreen> createState() =>
      _IntentSelectionScreenState();
}

class _IntentSelectionScreenState extends ConsumerState<IntentSelectionScreen> {
  String? _selectedIntent;
  bool _isLoading = false;
  bool _isLoadingData = true;

  // 3 intention options as requested
  final List<Map<String, String>> _intentOptions = [
    {
      'value': 'organise',
      'title': 'Organise',
      'description': 'List games, manage slots, and host matches',
      'icon': 'calendar',
    },
    {
      'value': 'compete',
      'title': 'Compete',
      'description': 'Serious matches, rankings, and tournaments',
      'icon': 'trophy',
    },
    {
      'value': 'social',
      'title': 'Social',
      'description': 'Casual play, meet people, and have fun',
      'icon': 'people',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingUserData();
  }

  Future<void> _loadExistingUserData() async {
    try {
      print('🎯 [DEBUG] IntentSelectionScreen: Loading onboarding data');

      // Check if we have data in onboarding provider
      final onboardingData = ref.read(onboardingDataProvider);
      if (onboardingData?.intention != null &&
          onboardingData!.intention!.isNotEmpty) {
        print(
          '✅ [DEBUG] IntentSelectionScreen: Found intention: ${onboardingData.intention}',
        );
        setState(() {
          _selectedIntent = onboardingData.intention;
        });
      } else {
        print(
          '🆕 [DEBUG] IntentSelectionScreen: No existing intention, starting fresh',
        );
      }
    } catch (e) {
      print('❌ [DEBUG] IntentSelectionScreen: Error loading data: $e');
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
          content: Text('Please select your main goal'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print(
        '🎯 [DEBUG] IntentSelectionScreen: Storing intention: $_selectedIntent',
      );

      // Store intention in onboarding provider
      ref.read(onboardingDataProvider.notifier).setIntention(_selectedIntent!);

      print(
        '✅ [DEBUG] IntentSelectionScreen: Intention stored, navigating to sports selection',
      );

      if (mounted) {
        // Navigate to sports selection screen
        context.push(RoutePaths.sportsSelection);
      }
    } catch (e) {
      print('❌ [DEBUG] IntentSelectionScreen: Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
                      padding: const EdgeInsets.all(
                        AppConstants.defaultPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 32),

                          // Header
                          Text(
                            'What is your main goal?',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Choose how you want to use Dabbler',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 48),

                          // Intent Options - Show only 3 options
                          ..._intentOptions.map((option) {
                            final isSelected =
                                _selectedIntent == option['value'];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: GestureDetector(
                                onTap: () => _selectIntent(option['value']!),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.1)
                                        : Colors.grey[50],
                                    border: Border.all(
                                      color: isSelected
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Theme.of(
                                                  context,
                                                ).primaryColor.withOpacity(0.2)
                                              : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          _getIntentIcon(option['icon']!),
                                          size: 28,
                                          color: isSelected
                                              ? Theme.of(context).primaryColor
                                              : Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              option['title']!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: isSelected
                                                        ? Theme.of(
                                                            context,
                                                          ).primaryColor
                                                        : Colors.grey[800],
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              option['description']!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: Colors.grey[600],
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          size: 28,
                                          color: Theme.of(context).primaryColor,
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
                            onPressed: (_isLoading || _selectedIntent == null)
                                ? null
                                : _handleSubmit,
                            text: _isLoading ? 'Continuing...' : 'Continue',
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

  IconData _getIntentIcon(String icon) {
    switch (icon) {
      case 'calendar':
        return Icons.event;
      case 'trophy':
        return Icons.emoji_events;
      case 'people':
        return Icons.people;
      default:
        return Icons.sports_soccer;
    }
  }
}
