import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dabbler/core/utils/constants.dart';
import 'package:dabbler/core/utils/helpers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/onboarding_progress.dart';
import '../../utils/constants/route_constants.dart';
import 'package:dabbler/features/authentication/presentation/providers/onboarding_data_provider.dart';
import '../../core/config/feature_flags.dart';

class SportsSelectionScreen extends ConsumerStatefulWidget {
  const SportsSelectionScreen({super.key});

  @override
  ConsumerState<SportsSelectionScreen> createState() =>
      _SportsSelectionScreenState();
}

class _SportsSelectionScreenState extends ConsumerState<SportsSelectionScreen> {
  String? _preferredSport;
  final Set<String> _interests = {};
  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadExistingUserData();
  }

  Future<void> _loadExistingUserData() async {
    try {
      debugPrint(
        '🏃 [DEBUG] SportsSelectionScreen: Loading existing user data',
      );

      // Check if we have onboarding data from previous steps
      final onboardingData = ref.read(onboardingDataProvider);
      if (onboardingData?.preferredSport != null) {
        debugPrint(
          '✅ [DEBUG] SportsSelectionScreen: Found preferred sport: ${onboardingData!.preferredSport}',
        );
        setState(() {
          _preferredSport = onboardingData.preferredSport;
          if (onboardingData.interests != null) {
            _interests.addAll(onboardingData.interests!);
          }
        });
      } else {
        debugPrint(
          '🆕 [DEBUG] SportsSelectionScreen: No existing sports data, starting fresh',
        );
      }
    } catch (e) {
      debugPrint(
        '❌ [DEBUG] SportsSelectionScreen: Error loading existing data: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  void _selectPreferredSport(String sport) {
    setState(() {
      _preferredSport = sport;
      // If the sport was in interests, remove it
      _interests.remove(sport);
    });
  }

  void _toggleInterest(String sport) {
    // Don't allow selecting preferred sport as interest
    if (sport == _preferredSport) {
      return;
    }

    setState(() {
      if (_interests.contains(sport)) {
        _interests.remove(sport);
      } else {
        // Limit to 3 interests
        if (_interests.length < 3) {
          _interests.add(sport);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can select up to 3 interests'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (_preferredSport == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your preferred sport'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('🏃 [DEBUG] SportsSelectionScreen: Saving sports preferences');
      debugPrint(
        '📋 [DEBUG] SportsSelectionScreen: Preferred sport: $_preferredSport',
      );
      debugPrint(
        '📋 [DEBUG] SportsSelectionScreen: Interests: ${_interests.toList()}',
      );

      // Save to OnboardingData provider
      ref
          .read(onboardingDataProvider.notifier)
          .setSports(
            preferredSport: _preferredSport!,
            interests: _interests.isNotEmpty ? _interests.toList() : null,
          );

      debugPrint(
        '✅ [DEBUG] SportsSelectionScreen: Sports preferences saved successfully',
      );

      // Navigate based on auth method (email vs phone)
      final onboardingData = ref.read(onboardingDataProvider);
      if (mounted) {
        if (onboardingData?.phone != null) {
          // Phone user → Set Username only
          debugPrint(
            '📱 [DEBUG] SportsSelectionScreen: Phone user, navigating to SetUsernameScreen',
          );
          context.push(RoutePaths.setUsername);
        } else {
          // Email user → Set Username + Password
          debugPrint(
            '📧 [DEBUG] SportsSelectionScreen: Email user, navigating to SetPasswordScreen',
          );
          context.push(RoutePaths.setPassword);
        }
      }
    } catch (e) {
      debugPrint(
        '❌ [DEBUG] SportsSelectionScreen: Error saving sports preferences: $e',
      );
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
        title: const Text('Sports Preferences'),
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
                            'Choose Your Sports',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Select your preferred sport and additional interests',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 40),

                          // Preferred Sport Section
                          Row(
                            children: [
                              Text(
                                'Preferred Sport',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Required',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.red[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          Text(
                            'Choose your main sport',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),

                          const SizedBox(height: 16),

                          // Preferred Sport Grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.0,
                                ),
                            itemCount: AppConstants.availableSports
                                .where(
                                  (sport) => FeatureFlags.isSportEnabled(sport),
                                )
                                .length,
                            itemBuilder: (context, index) {
                              final enabledSports = AppConstants.availableSports
                                  .where(
                                    (sport) =>
                                        FeatureFlags.isSportEnabled(sport),
                                  )
                                  .toList();
                              final sport = enabledSports[index];
                              final isSelected = _preferredSport == sport;

                              return GestureDetector(
                                onTap: () => _selectPreferredSport(sport),
                                child: Container(
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
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        AppHelpers.getSportIcon(sport),
                                        size: 32,
                                        color: isSelected
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey[600],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        AppHelpers.getSportDisplayName(sport),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? Theme.of(
                                                      context,
                                                    ).primaryColor
                                                  : Colors.grey[700],
                                            ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(height: 4),
                                        Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 40),

                          // Interests Section
                          Row(
                            children: [
                              Text(
                                'Additional Interests',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Optional',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          Text(
                            'Select up to 3 additional sports (${_interests.length}/3)',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),

                          const SizedBox(height: 16),

                          // Interests Grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.0,
                                ),
                            itemCount: AppConstants.availableSports
                                .where(
                                  (sport) => FeatureFlags.isSportEnabled(sport),
                                )
                                .length,
                            itemBuilder: (context, index) {
                              final enabledSports = AppConstants.availableSports
                                  .where(
                                    (sport) =>
                                        FeatureFlags.isSportEnabled(sport),
                                  )
                                  .toList();
                              final sport = enabledSports[index];
                              final isSelected = _interests.contains(sport);
                              final isPreferred = _preferredSport == sport;
                              final isDisabled =
                                  isPreferred ||
                                  (_interests.length >= 3 && !isSelected);

                              return Opacity(
                                opacity: isDisabled ? 0.5 : 1.0,
                                child: GestureDetector(
                                  onTap: isDisabled
                                      ? null
                                      : () => _toggleInterest(sport),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.green[50]
                                          : Colors.grey[50],
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.green
                                            : Colors.grey[300]!,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          AppHelpers.getSportIcon(sport),
                                          size: 32,
                                          color: isSelected
                                              ? Colors.green[700]
                                              : Colors.grey[600],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          AppHelpers.getSportDisplayName(sport),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                                color: isSelected
                                                    ? Colors.green[700]
                                                    : Colors.grey[700],
                                              ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(height: 4),
                                          Icon(
                                            Icons.check_circle,
                                            size: 16,
                                            color: Colors.green[700],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 32),

                          // Continue Button
                          AppButton(
                            onPressed: (_isLoading || _preferredSport == null)
                                ? null
                                : _handleSubmit,
                            label: _isLoading ? 'Continuing...' : 'Continue',
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
}
