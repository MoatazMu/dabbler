import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/onboarding_progress.dart';
import '../../utils/constants/route_constants.dart';
import 'create_user_information.dart';

class SportsSelectionScreen extends StatefulWidget {
  final RegistrationData? registrationData;
  
  const SportsSelectionScreen({
    super.key,
    this.registrationData,
  });

  @override
  State<SportsSelectionScreen> createState() => _SportsSelectionScreenState();
}

class _SportsSelectionScreenState extends State<SportsSelectionScreen> {
  final Set<String> _selectedSports = {};
  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadExistingUserData();
  }

  Future<void> _loadExistingUserData() async {
    try {
      debugPrint('🏃 [DEBUG] SportsSelectionScreen: Loading existing user data');
      
      // Check if we have registration data from previous step
      if (widget.registrationData?.sports != null && widget.registrationData!.sports!.isNotEmpty) {
        debugPrint('✅ [DEBUG] SportsSelectionScreen: Found sports in registration data: ${widget.registrationData!.sports}');
        setState(() {
          _selectedSports.addAll(widget.registrationData!.sports!);
        });
      } else {
        debugPrint('🆕 [DEBUG] SportsSelectionScreen: No existing sports data, starting fresh');
      }
    } catch (e) {
      debugPrint('❌ [DEBUG] SportsSelectionScreen: Error loading existing data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  void _toggleSport(String sport) {
    setState(() {
      if (_selectedSports.contains(sport)) {
        _selectedSports.remove(sport);
      } else {
        _selectedSports.add(sport);
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (_selectedSports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one sport'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('🏃 [DEBUG] SportsSelectionScreen: Collecting sports preferences');
      debugPrint('📋 [DEBUG] SportsSelectionScreen: Selected sports: ${_selectedSports.toList()}');

      // Get registration data from previous step and add sports
      final registrationData = widget.registrationData?.copyWith(sports: _selectedSports.toList());
      
      debugPrint('✅ [DEBUG] SportsSelectionScreen: Sports preferences collected successfully');

      if (mounted) {
        context.go(RoutePaths.intentSelection, extra: registrationData?.toMap());
      }
    } catch (e) {
      debugPrint('❌ [DEBUG] SportsSelectionScreen: Error collecting sports preferences: $e');
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
      debugPrint('🏃 [DEBUG] SportsSelectionScreen: Skipping sports selection, using default');
      
      // Use default sports (football) and get registration data from previous step
      final registrationData = widget.registrationData?.copyWith(sports: ['football']);
      
      debugPrint('✅ [DEBUG] SportsSelectionScreen: Using default sports: football');
      
      if (mounted) {
        context.go(RoutePaths.intentSelection, extra: registrationData?.toMap());
      }
    } catch (e) {
      debugPrint('❌ [DEBUG] SportsSelectionScreen: Error in skip: $e');
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
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 32),
                          
                          // Header
                          Text(
                            'What sports do you play?',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Text(
                            'Select all the sports you\'re interested in',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Sports Grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.2,
                            ),
                            itemCount: AppConstants.availableSports.length,
                            itemBuilder: (context, index) {
                              final sport = AppConstants.availableSports[index];
                              final isSelected = _selectedSports.contains(sport);
                              
                              return GestureDetector(
                                onTap: () => _toggleSport(sport),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.blue[50] : Colors.grey[50],
                                    border: Border.all(
                                      color: isSelected ? Colors.blue : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        AppHelpers.getSportIcon(sport),
                                        size: 32,
                                        color: isSelected ? Colors.blue[700] : Colors.grey[600],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        AppHelpers.getSportDisplayName(sport),
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          color: isSelected ? Colors.blue[700] : Colors.grey[700],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(height: 4),
                                        Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: Colors.blue[700],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Continue Button
                          CustomButton(
                            onPressed: _isLoading ? null : _handleSubmit,
                            text: _isLoading ? 'Continuing...' : 'Continue',
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
}
