import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dabbler/core/services/auth_service.dart';
import 'package:dabbler/core/utils/identifier_detector.dart';
import 'package:dabbler/core/utils/validators.dart';
import 'package:dabbler/utils/constants/route_constants.dart';
import 'package:dabbler_design_system/dabbler_design_system.dart';
import 'package:dabbler/core/design_system/design_system.dart';
import 'package:dabbler/themes/app_theme.dart';
import 'package:dabbler/core/models/google_sign_in_result.dart';
import 'package:dabbler/features/authentication/presentation/providers/onboarding_data_provider.dart';

class IdentityVerificationScreen extends ConsumerStatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  ConsumerState<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends ConsumerState<IdentityVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  String _countryCode = '+971'; // Default to UAE
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _isPhoneValid = false;
  IdentifierType _currentIdentifierType = IdentifierType.phone;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _setDefaultCountryFromLocale();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onPhoneChanged(String value) {
    final trimmed = value.trim();

    final isNumericLike = _isNumericLike(trimmed);

    // If not numeric-like, treat as email and never show phone prefix
    if (!isNumericLike) {
      setState(() {
        _hasText = trimmed.isNotEmpty;
        _currentIdentifierType = IdentifierType.email;
        _isPhoneValid = false;
      });
      return;
    }

    String working = trimmed;

    // Special handling for UAE: if starts with "971" (without "+"),
    // interpret it as UAE country code and keep only the local part.
    if (working.startsWith('971') && !working.startsWith('+')) {
      final remaining = working.substring(3); // strip "971"
      if (_countryCode != '+971') {
        _countryCode = '+971';
      }
      if (remaining != working) {
        _phoneController.value = TextEditingValue(
          text: remaining,
          selection: TextSelection.collapsed(offset: remaining.length),
        );
        working = remaining;
      }
    }

    setState(() {
      _hasText = working.isNotEmpty;
      _currentIdentifierType = IdentifierType.phone;
    });

    final isValidPhone = _isValidUaeMobile(working);
    if (isValidPhone != _isPhoneValid) {
      setState(() {
        _isPhoneValid = isValidPhone;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final input = _phoneController.text.trim();

    // Decide based on the same numeric-like heuristic used in _onPhoneChanged
    final isNumericLike = _isNumericLike(input);
    late final IdentifierType identifierType;
    late final String finalIdentifier;

    if (isNumericLike) {
      identifierType = IdentifierType.phone;

      // UAE-only normalization
      final local = _normalizeToUaeLocal(input);
      if (local == null) {
        setState(() {
          _errorMessage = 'Use UAE mobile number only or email';
        });
        return;
      }
      // Always send full E.164 UAE number
      finalIdentifier = '+971$local';
    } else {
      identifierType = IdentifierType.email;
      // Normalize email similarly to IdentifierDetector
      final normalizedEmail = input
          .replaceAll(RegExp(r"[\u200B-\u200D\uFEFF]"), "")
          .replaceAll(RegExp(r"\s+"), "")
          .trim()
          .toLowerCase();
      finalIdentifier = normalizedEmail;
    }

    try {
      // Check if user exists BEFORE sending OTP
      try {
        final authService = AuthService();

        print(
          '🔍 [DEBUG] IdentityVerificationScreen: Checking if user exists: $finalIdentifier',
        );
        bool userExistsBeforeOtp = false;
        if (identifierType == IdentifierType.email) {
          userExistsBeforeOtp = await authService.checkUserExistsByEmail(
            finalIdentifier,
          );
        } else {
          userExistsBeforeOtp = await authService.checkUserExistsByPhone(
            finalIdentifier,
          );
        }
        print(
          '🔍 [DEBUG] IdentityVerificationScreen: User exists: $userExistsBeforeOtp',
        );

        // Send OTP using unified method
        await authService.sendOtp(
          identifier: finalIdentifier,
          type: identifierType,
        );

        if (mounted) {
          setState(() {
            _successMessage = identifierType == IdentifierType.email
                ? 'OTP sent! Please check your email.'
                : 'OTP sent! Please check your phone.';
          });
        }
      } catch (dbError) {
        final errorMsg = dbError.toString();

        // Check for provider not configured error
        if (errorMsg.contains('phone_provider_disabled') ||
            errorMsg.contains('Unsupported phone provider')) {
          if (mounted) {
            setState(() {
              _errorMessage =
                  'Phone authentication is not available yet. Please use email to continue.';
            });
          }
          return;
        }

        if (mounted) {
          setState(() {
            _errorMessage = 'Service error: ${dbError.toString()}';
          });
        }
        return; // Don't navigate if there's an error
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to send OTP. Please try again.';
        });
      }
      return; // Don't navigate if there's an error
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    // Navigate to OTP verification screen only if everything succeeded
    if (mounted) {
      try {
        context.push(
          RoutePaths.otpVerification,
          extra: {
            'identifier': finalIdentifier,
            'identifierType': identifierType.name,
            // We always use OTP for both new and existing users; keep flag
            // only for analytics/routing decisions in the OTP screen.
            'userExistsBeforeOtp': true,
          },
        );
      } catch (navError) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Navigation failed: ${navError.toString()}';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: _buildHeroSection(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                child: _buildBottomSection(),
              ),
              const DabblerHello(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    final textTheme = Theme.of(context).textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final heroColor = isDarkMode
        ? const Color(0xFF4A148C)
        : const Color(0xFFE0C7FF);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtextColor = isDarkMode
        ? Colors.white.withOpacity(0.85)
        : Colors.black.withOpacity(0.7);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: heroColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          // Dabbler logo and text
          _buildLogo(textColor),
          const SizedBox(height: 24),
          // Screen title
          Text(
            'Identity verification',
            style: textTheme.headlineSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your email or mobile number to get started',
            style: textTheme.bodyLarge?.copyWith(color: subtextColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(Color iconColor) {
    return Column(
      children: [
        // Dabbler geometric icon
        SvgPicture.asset(
          'assets/images/dabbler_logo.svg',
          width: 80,
          height: 88,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        ),
        SizedBox(height: AppSpacing.md),
        // Dabbler text logo
        SvgPicture.asset(
          'assets/images/dabbler_text_logo.svg',
          width: 110,
          height: 21,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        ),
      ],
    );
  }

  Widget _buildBottomSection() {
    return Column(
      children: [
        // Phone input field
        _buildPhoneInput(),
        const SizedBox(height: 16), // Material 3 spacing: 16dp
        // Continue button
        _buildEmailButton(),

        const SizedBox(height: 24), // Material 3 spacing: 24dp
        // Divider with "or"
        _buildDivider(),

        const SizedBox(height: 24), // Material 3 spacing: 24dp
        // Continue with Google button
        _buildGoogleButton(),

        const SizedBox(height: 24), // Material 3 spacing: 24dp
        // Terms and privacy
        _buildTermsText(),

        // Error/Success messages - using Material 3 colors
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (_successMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  Theme.of(
                    context,
                  ).extension<AppThemeExtension>()?.success.withOpacity(0.1) ??
                  Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color:
                      Theme.of(
                        context,
                      ).extension<AppThemeExtension>()?.success ??
                      Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _successMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          Theme.of(
                            context,
                          ).extension<AppThemeExtension>()?.success ??
                          Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhoneInput() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Use Material 3 TextFormField with proper styling and validation
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: TextFormField(
        controller: _phoneController,
        keyboardType: _currentIdentifierType == IdentifierType.email
            ? TextInputType.emailAddress
            : TextInputType.phone,
        onChanged: (value) {
          _onPhoneChanged(value);
        },
        validator: (value) {
          final trimmed = value?.trim() ?? '';

          if (trimmed.isEmpty) {
            return 'Email or phone number is required';
          }

          final isNumericLike = _isNumericLike(trimmed);

          if (isNumericLike) {
            // UAE-only phone rule
            if (_isValidUaeMobile(trimmed)) {
              return null;
            }
            return 'Use UAE mobile number only or email';
          } else {
            // Email validation
            return AppValidators.validateEmail(trimmed);
          }
        },
        style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: 'Email or phone number',
          // Show no prefix by default; only once user types a number (phone)
          prefixIcon: !_hasText
              ? null
              : _currentIdentifierType == IdentifierType.phone
              ? Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        color: colorScheme.onSurfaceVariant,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _countryCode,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        height: 20,
                        color: colorScheme.outlineVariant,
                      ),
                    ],
                  ),
                )
              : null,
          // Material 3 uses InputDecorationTheme from theme
        ).applyDefaults(Theme.of(context).inputDecorationTheme),
      ),
    );
  }

  /// For now, we only support UAE numbers, so always use +971
  void _setDefaultCountryFromLocale() {
    _countryCode = '+971';
  }

  /// Returns true if the string looks like a phone-ish input (digits, +, spaces, (), -).
  bool _isNumericLike(String input) {
    return input.isNotEmpty &&
        RegExp(r'^[0-9+\s()\-\u0660-\u0669]+$').hasMatch(input);
  }

  /// Normalize various UAE formats to local 9-digit starting with 5:
  /// 5XXXXXXXX, 05XXXXXXXX, 9715XXXXXXXX, +9715XXXXXXXX -> 5XXXXXXXX
  String? _normalizeToUaeLocal(String input) {
    var s = input.replaceAll(RegExp(r'\s+'), '');

    if (s.startsWith('+971')) {
      s = s.substring(4);
    } else if (s.startsWith('971')) {
      s = s.substring(3);
    } else if (s.startsWith('05')) {
      s = s.substring(1); // drop leading 0
    }

    if (RegExp(r'^5\d{8}$').hasMatch(s)) {
      return s;
    }
    return null;
  }

  /// UAE-only mobile validation.
  bool _isValidUaeMobile(String input) {
    final local = _normalizeToUaeLocal(input);
    return local != null;
  }

  Widget _buildEmailButton() {
    // Use Material 3 FilledButton for primary action
    return FilledButton.icon(
      onPressed: _isLoading ? null : _handleSubmit,
      icon: _isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          : const Icon(Icons.login, size: 20),
      label: Text(_isLoading ? 'Sending...' : 'Continue'),
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
      ),
    );
  }

  Widget _buildDivider() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Use Material 3 Divider
    return Row(
      children: [
        Expanded(
          child: Divider(color: colorScheme.outlineVariant, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: colorScheme.outlineVariant, thickness: 1),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    // Use Material 3 OutlinedButton for secondary actions
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _handleGoogleSignIn,
      icon: _isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          : const Text(
              'G',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
      label: const Text('Continue with Google'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final authService = AuthService();

      // Launch Google OAuth (this opens browser/app)
      await authService.signInWithGoogle();

      // Note: OAuth is asynchronous - the user will complete sign-in in browser/app
      // The auth state listener will detect when they return and handle routing
      // For now, we'll wait a bit and then check, but ideally this should be handled
      // by the auth state listener in the router

      // Wait for OAuth to complete (user will be redirected back)
      await Future.delayed(const Duration(seconds: 3));

      // Now check the result after OAuth completes
      final result = await authService.handleGoogleSignInFlow();

      if (!mounted) return;

      // Navigate based on result
      switch (result) {
        case GoogleSignInResultGoToOnboarding():
          // New Google user (email only) - go to full onboarding flow
          ref.read(onboardingDataProvider.notifier).initWithEmail(result.email);
          context.go(RoutePaths.createUserInfo, extra: {'email': result.email});
          break;

        case GoogleSignInResultGoToSetUsername():
          // Legacy case - should not be used for new Google users
          ref.read(onboardingDataProvider.notifier).initWithEmail(result.email);
          context.go(
            RoutePaths.setUsername,
            extra: {
              'email': result.email,
              'suggestedUsername': result.suggestedUsername,
            },
          );
          break;

        case GoogleSignInResultGoToPhoneOtp():
          // New Google user (email + phone) - go to OTP verification
          context.push(
            RoutePaths.otpVerification,
            extra: {
              'phone': result.phone,
              'email': result.email,
              'userExistsBeforeOtp': false,
            },
          );
          break;

        case GoogleSignInResultGoToHome():
          // Existing Google user - let router handle navigation
          context.go(RoutePaths.home);
          break;

        case GoogleSignInResultRequirePassword():
          // Existing user (non-Google) - require password
          context.push(
            RoutePaths.enterPassword,
            extra: {'email': result.email},
          );
          break;

        case GoogleSignInResultError():
          // Error occurred
          setState(() {
            _errorMessage = result.message;
          });
          break;
      }
    } catch (e) {
      debugPrint(
        '❌ [DEBUG] IdentityVerificationScreen: Google sign-in error: $e',
      );
      if (mounted) {
        setState(() {
          _errorMessage = 'Google sign-in failed. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTermsText() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(
          'By continuing, you agree to our',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: () {
            // TODO: Open Terms of Service
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Terms of Service',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        Text(
          'and',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: () {
            // TODO: Open Privacy Policy
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Privacy Policy',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
