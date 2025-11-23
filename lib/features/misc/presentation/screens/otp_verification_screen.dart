import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dabbler/core/services/auth_service.dart';
import 'package:dabbler/core/utils/validators.dart';
import 'package:dabbler/core/utils/identifier_detector.dart';
import 'package:dabbler/features/authentication/presentation/providers/onboarding_data_provider.dart';
import 'package:dabbler/features/authentication/presentation/providers/auth_providers.dart';
import 'package:dabbler/utils/constants/route_constants.dart';
import 'package:dabbler/core/design_system/design_system.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String? identifier; // Can be email or phone
  final IdentifierType? identifierType; // If null, will be auto-detected
  final bool? userExistsBeforeOtp;

  // Legacy support for phoneNumber parameter
  const OtpVerificationScreen({
    super.key,
    this.identifier,
    this.identifierType,
    this.userExistsBeforeOtp,
    @Deprecated('Use identifier instead') String? phoneNumber,
  }) : assert(
          identifier != null || phoneNumber != null,
          'Either identifier or phoneNumber must be provided',
        );

  // Getter for backward compatibility
  String? get phoneNumber => identifier;

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  int _resendCountdown = 0;
  
  late String _identifier;
  late IdentifierType _identifierType;

  @override
  void initState() {
    super.initState();
    
    // Determine identifier and type
    _identifier = widget.identifier ?? widget.phoneNumber ?? '';
    if (widget.identifierType != null) {
      _identifierType = widget.identifierType!;
    } else {
      // Auto-detect if not provided
      final detection = IdentifierDetector.detect(_identifier);
      _identifierType = detection.type;
      _identifier = detection.normalizedValue;
    }
    
    print(
      '🔍 [DEBUG] OtpVerificationScreen: Initialized with identifier=${_identifierType.name}: $_identifier, userExistsBeforeOtp=${widget.userExistsBeforeOtp}',
    );
    _startResendCountdown();
  }

  @override
  void dispose() {
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 30;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
        _startResendCountdown();
      }
    });
  }

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-submit when all 6 digits are entered
    if (value.length == 1 && index == 5) {
      // Check if all fields are filled
      final otpCode = _getOtpCode();
      if (otpCode.length == 6) {
        // Unfocus to dismiss keyboard
        FocusScope.of(context).unfocus();
        // Automatically submit after a short delay
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && !_isLoading) {
            _handleSubmit();
          }
        });
      }
    }
  }

  String _getOtpCode() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _handleSubmit() async {
    final otpCode = _getOtpCode();

    final otpError = AppValidators.validateOTP(otpCode);
    if (otpError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(otpError), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print(
        '🔐 [DEBUG] OtpVerificationScreen: Verifying OTP for ${_identifierType.name}: $_identifier',
      );

      final authService = AuthService();
      final response = await authService.verifyOtp(
        identifier: _identifier,
        type: _identifierType,
        token: otpCode,
      );

      print('✅ [DEBUG] OtpVerificationScreen: OTP verification successful');

      // Verify session was created
      if (response.session != null) {
        print('✅ [DEBUG] OtpVerificationScreen: Session created successfully');
        print(
          '👤 [DEBUG] OtpVerificationScreen: User ID: ${response.user?.id}',
        );

        // Refresh auth state to ensure the session is recognized app-wide
        await ref.read(simpleAuthProvider.notifier).refreshAuthState();
        print('✅ [DEBUG] OtpVerificationScreen: Auth state refreshed');
      } else {
        print('⚠️ [DEBUG] OtpVerificationScreen: No session in response');
      }

      if (mounted) {
        // Check if user needs to complete profile
        await _checkUserProfileAndNavigate();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Check if user has completed profile and navigate accordingly
  Future<void> _checkUserProfileAndNavigate() async {
    try {
      final authService = AuthService();
      final userProfile = await authService.getUserProfile(fields: ['id', 'onboard']);

      // Check if user has completed onboarding
      final isOnboarded = userProfile != null && 
          (userProfile['onboard'] == true || userProfile['onboard'] == 'true');

      print(
        '🔍 [DEBUG] OtpVerificationScreen: Profile check - onboard=$isOnboarded',
      );

      if (isOnboarded) {
        print(
          '✅ [DEBUG] OtpVerificationScreen: User onboarded, redirecting to home',
        );
        // User has completed onboarding - go to home
        if (mounted) {
          context.go(RoutePaths.home);
        }
      } else {
        print(
          '🆕 [DEBUG] OtpVerificationScreen: User not onboarded, redirecting to onboarding',
        );
        // User needs to complete onboarding - initialize onboarding data
        if (_identifierType == IdentifierType.email) {
          ref.read(onboardingDataProvider.notifier).initWithEmail(_identifier);
          if (mounted) {
            context.go(
              RoutePaths.createUserInfo,
              extra: {'email': _identifier},
            );
          }
        } else {
          ref.read(onboardingDataProvider.notifier).initWithPhone(_identifier);
          if (mounted) {
            context.go(
              RoutePaths.createUserInfo,
              extra: {'phone': _identifier},
            );
          }
        }
      }
    } catch (e) {
      print('❌ [DEBUG] OtpVerificationScreen: Error during navigation: $e');
      // Final fallback - go to onboarding
      if (mounted) {
        if (_identifierType == IdentifierType.email) {
          ref.read(onboardingDataProvider.notifier).initWithEmail(_identifier);
          context.go(
            RoutePaths.createUserInfo,
            extra: {'email': _identifier},
          );
        } else {
          ref.read(onboardingDataProvider.notifier).initWithPhone(_identifier);
          context.go(
            RoutePaths.createUserInfo,
            extra: {'phone': _identifier},
          );
        }
      }
    }
  }

  Future<void> _handleResend() async {
    if (_resendCountdown > 0) return;

    setState(() => _isResending = true);

    try {
      final authService = AuthService();
      await authService.sendOtp(
        identifier: _identifier,
        type: _identifierType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent successfully to your ${_identifierType == IdentifierType.email ? 'email' : 'phone'}'),
            backgroundColor: Colors.green,
          ),
        );
        _startResendCountdown();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: _buildHeroSection(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                child: _buildBottomSection(),
              ),
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
          // Logo
          _buildLogo(textColor),
          const SizedBox(height: 24),
          // Header
          Text(
            _identifierType == IdentifierType.email
                ? 'Verify Your Email'
                : 'Verify Your Phone',
            style: textTheme.headlineSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _identifierType == IdentifierType.email
                ? 'We\'ve sent a 6-digit code to your email'
                : 'We\'ve sent a 6-digit code to',
            style: textTheme.bodyLarge?.copyWith(color: subtextColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _identifier,
            style: textTheme.bodyLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(Color iconColor) {
    return Column(
      children: [
        SvgPicture.asset(
          'assets/images/dabbler_logo.svg',
          width: 80,
          height: 88,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        ),
        const SizedBox(height: 16),
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
        // OTP Input Fields
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 45,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.cardColor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                    borderSide: BorderSide(color: AppColors.borderDark),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                    borderSide: BorderSide(color: AppColors.borderDark),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                    borderSide: BorderSide(color: AppColors.primaryPurple),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) => _onOtpChanged(value, index),
              ),
            );
          }),
        ),
        SizedBox(height: AppSpacing.xl),

        // Verify Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: AppColors.buttonForeground,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppSpacing.buttonBorderRadius,
                ),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.buttonForeground,
                      ),
                    ),
                  )
                : Text(
                    'Verify',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
          ),
        ),
        SizedBox(height: AppSpacing.lg),

        // Resend OTP
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Didn\'t receive the code? ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (_resendCountdown > 0)
              Text(
                'Resend in $_resendCountdown seconds',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              GestureDetector(
                onTap: _isResending ? null : _handleResend,
                child: Text(
                  _isResending ? 'Sending...' : 'Resend',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryPurple,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: AppSpacing.xxl),

        // Change identifier
        TextButton(
          onPressed: () {
            context.go(RoutePaths.phoneInput);
          },
          child: Text(
            _identifierType == IdentifierType.email
                ? 'Change Email'
                : 'Change Phone Number',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
