import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/input_field.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/onboarding_service.dart';
import '../../features/authentication/presentation/providers/auth_providers.dart';
import '../../utils/constants/route_constants.dart';
import 'create_user_information.dart' show RegistrationData;

class SetPasswordScreen extends ConsumerStatefulWidget {
  final RegistrationData? registrationData;

  const SetPasswordScreen({super.key, this.registrationData});

  @override
  ConsumerState<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends ConsumerState<SetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final registrationData = widget.registrationData;
    try {
      if (registrationData == null) {
        throw Exception('Registration data is missing');
      }
    final email = registrationData.email.trim();
    // Defensive: strip invisible chars that can sneak in from copy/paste
    final normalizedEmail = email.replaceAll(RegExp(r"[\u200B-\u200D\uFEFF]"), "");
      final password = _passwordController.text;

      final authService = AuthService();
      final onboardingService = OnboardingService();

      // Check if user already exists before attempting signup
  // ...existing code...
      
      final userExists = await authService.checkUserExistsByEmail(normalizedEmail);
      if (userExists) {
  // ...existing code...
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account already exists. Please sign in with your password.'),
            backgroundColor: Colors.orange,
          ),
        );
        context.go('/enter-password', extra: normalizedEmail);
        return;
      }

      bool createdAccount = false;
      try {
  // ...existing code...
        
        // ============================================================
        // Validate ALL mandatory fields before signup
        // Required: display_name, age, gender, sports, intent
        // ============================================================
        
        // 1. Validate name (display_name)
        if (registrationData.name == null || registrationData.name!.trim().isEmpty) {
          throw Exception('Name is required. Please go back and enter your name.');
        }
        if (registrationData.name!.trim().length < 2) {
          throw Exception('Name must be at least 2 characters. Please go back and update.');
        }
        if (registrationData.name!.trim().length > 50) {
          throw Exception('Name must be 50 characters or less. Please go back and update.');
        }
        
        // 2. Validate age
        if (registrationData.age == null) {
          throw Exception('Age is required. Please go back and enter your age.');
        }
        if (registrationData.age! < 13 || registrationData.age! > 120) {
          throw Exception('Age must be between 13 and 120. Please go back and update.');
        }
        
        // 3. Validate gender (ONLY 'male' or 'female' allowed)
        if (registrationData.gender == null || registrationData.gender!.trim().isEmpty) {
          throw Exception('Gender is required. Please go back and select your gender.');
        }
        final gender = registrationData.gender!.trim().toLowerCase();
        if (gender != 'male' && gender != 'female') {
          throw Exception('Gender must be either Male or Female. Please go back and select a valid option.');
        }
        
        // 4. Validate sports (array can be empty, but must exist)
        // Sports is optional during onboarding, will default to empty array
        
        // 5. Validate intent
        if (registrationData.intent == null || registrationData.intent!.trim().isEmpty) {
          throw Exception('Intent is required. Please go back and select your intent.');
        }
        
        print('📋 [DEBUG] SetPasswordScreen: All mandatory fields validated');
        print('📊 [DEBUG] name="${registrationData.name}", age=${registrationData.age}, gender=${registrationData.gender}, sports=${registrationData.sports}, intent=${registrationData.intent}');
        
        // Create account with complete user metadata
        await authService.signUpWithEmailAndMetadata(
          email: normalizedEmail, 
          password: password,
          metadata: {
            'name': registrationData.name!.trim(),
            'age': registrationData.age,
            'gender': registrationData.gender!.trim(),
            'sports': registrationData.sports ?? [],
            'intent': registrationData.intent!.trim(),
          }
        );
        
        createdAccount = true;
  // ...existing code...
      } catch (e) {
        final msg = e.toString();
  // ...existing code...
        
        if (msg.contains('already registered') || msg.contains('user_already_exists')) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account already exists. Please sign in with your password.'),
              backgroundColor: Colors.orange,
            ),
          );
          context.go('/enter-password', extra: normalizedEmail);
          return;
        }
        if (msg.contains('over_email_send_rate_limit') || msg.contains('after 12 seconds')) {
          if (!mounted) return;
          setState(() => _cooldown = 12);
          _cooldownTimer?.cancel();
          _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
            if (!mounted) {
              t.cancel();
              return;
            }
            setState(() {
              _cooldown = (_cooldown - 1).clamp(0, 999);
              if (_cooldown == 0) t.cancel();
            });
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please wait a few seconds before trying again.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        rethrow;
      }

            // Ensure authenticated if necessary
      if (!authService.isAuthenticated() && createdAccount) {
        // If email confirmations disabled, signUp usually authenticates. Otherwise, sign in.
        try {
          await authService.signInWithEmail(email: normalizedEmail, password: password);
        } catch (_) {/* ignore */}
      }

      // Profile was already created with complete data by the database trigger
  // ...existing code...
      await onboardingService.markOnboardingComplete();

      // Refresh the SimpleAuthNotifier to update the router's auth state
  // ...existing code...
      await ref.read(simpleAuthProvider.notifier).refreshAuthState();

      // Navigate directly to welcome screen since account was just created
      if (mounted) {
        final displayName = registrationData.name ?? 'Player';
  // ...existing code...
        context.go(RoutePaths.welcome, extra: {'displayName': displayName});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.registrationData?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Set Password'), backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Create Password', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (email.isNotEmpty)
                  Text('Email: $email', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                CustomInputField(
                  controller: _passwordController,
                  label: 'Password',
                  hintText: 'Enter a strong password',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 16),
                CustomInputField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hintText: 'Re-enter your password',
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: _isLoading ? 'Creating account...' : (_cooldown > 0 ? 'Wait $_cooldown s' : 'Create Account'),
                  onPressed: _isLoading || _cooldown > 0 ? null : _handleSubmit,
                  loading: _isLoading,
                  fullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}