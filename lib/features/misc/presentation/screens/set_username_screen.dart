import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dabbler/core/services/auth_service.dart';
import 'package:dabbler/features/authentication/presentation/providers/onboarding_data_provider.dart';
import 'package:dabbler/features/authentication/presentation/providers/auth_providers.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/constants/route_constants.dart';
import '../../widgets/input_field.dart';
import '../../widgets/onboarding_progress.dart';
import 'dart:async';

class SetUsernameScreen extends ConsumerStatefulWidget {
  const SetUsernameScreen({super.key});

  @override
  ConsumerState<SetUsernameScreen> createState() => _SetUsernameScreenState();
}

class _SetUsernameScreenState extends ConsumerState<SetUsernameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();

  bool _isLoading = false;
  bool _isCheckingUsername = false;
  String? _usernameError;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Verify authentication status on load for debugging
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = AuthService();
      final currentUser = authService.getCurrentUser();
      debugPrint(
        '🔍 [DEBUG] SetUsernameScreen: Auth check - User: ${currentUser?.email ?? currentUser?.phone ?? "None"}',
      );
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (username.length < 3) {
      setState(() {
        _usernameError = null;
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() => _isCheckingUsername = true);

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final authService = AuthService();
        final exists = await authService.checkUsernameExists(username);

        if (mounted) {
          setState(() {
            _usernameError = exists ? 'Username already taken' : null;
            _isCheckingUsername = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _usernameError = 'Error checking username';
            _isCheckingUsername = false;
          });
        }
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_usernameError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_usernameError!), backgroundColor: Colors.red),
      );
      return;
    }

    final onboardingData = ref.read(onboardingDataProvider);
    if (onboardingData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing onboarding data. Please start over.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate all required fields
    if (onboardingData.displayName == null ||
        onboardingData.age == null ||
        onboardingData.gender == null ||
        onboardingData.intention == null ||
        onboardingData.preferredSport == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Missing required information. Please complete all steps.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final username = _usernameController.text.trim();

      // Validate username is not empty
      if (username.isEmpty) {
        throw Exception('Username cannot be empty. Please enter a username.');
      }

      final authService = AuthService();

      final currentUser = authService.getCurrentUser();

      if (currentUser == null) {
        // Session expired - this shouldn't happen but handle gracefully
        throw Exception(
          'Your session has expired. Please verify your phone number again.',
        );
      }

      debugPrint(
        '📋 [DEBUG] SetUsernameScreen: Creating profile for phone user',
      );
      debugPrint(
        '📊 [DEBUG] phone=${onboardingData.phone}, name=${onboardingData.displayName}',
      );
      debugPrint(
        '📊 [DEBUG] username="$username" (length: ${username.length}), age=${onboardingData.age}, gender=${onboardingData.gender}',
      );
      debugPrint(
        '📊 [DEBUG] username isEmpty: ${username.isEmpty}, isNotEmpty: ${username.isNotEmpty}',
      );

      // Create profile in public.profiles
      await authService.createProfile(
        userId: currentUser.id,
        displayName: onboardingData.displayName!,
        username: username,
        age: onboardingData.age!,
        gender: onboardingData.gender!,
        intention: onboardingData.intention!,
        preferredSport: onboardingData.preferredSport!,
        interests: onboardingData.interestsString,
      );

      debugPrint('✅ [DEBUG] SetUsernameScreen: Profile created successfully');

      // Clear onboarding data
      ref.read(onboardingDataProvider.notifier).clear();

      // Refresh auth state to load the new profile
      await ref.read(simpleAuthProvider.notifier).refreshAuthState();

      // Navigate to welcome screen
      if (mounted) {
        final displayName = onboardingData.displayName ?? 'Player';
        context.go(RoutePaths.welcome, extra: {'displayName': displayName});
      }
    } catch (e) {
      debugPrint('❌ [DEBUG] SetUsernameScreen: Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingData = ref.watch(onboardingDataProvider);
    final phone = onboardingData?.phone ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Username'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Onboarding Progress
                OnboardingProgress(),

                const SizedBox(height: 32),

                const Text(
                  'Choose Your Username',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (phone.isNotEmpty)
                  Text(
                    'Phone: $phone',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                const SizedBox(height: 32),

                // Username Field
                Text(
                  'Username',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                CustomInputField(
                  controller: _usernameController,
                  label: 'Username',
                  hintText: 'Choose a unique username',
                  onChanged: _checkUsernameAvailability,
                  suffixIcon: _isCheckingUsername
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _usernameError == null &&
                            _usernameController.text.isNotEmpty
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username is required';
                    }
                    if (value.trim().length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                      return 'Username can only contain letters, numbers, and underscores';
                    }
                    return null;
                  },
                ),
                if (_usernameError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _usernameError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Complete'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
