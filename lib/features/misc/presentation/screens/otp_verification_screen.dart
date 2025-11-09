import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dabbler/core/services/auth_service.dart';
import 'package:dabbler/core/utils/validators.dart';
import 'package:dabbler/features/authentication/presentation/providers/onboarding_data_provider.dart';
import 'package:dabbler/features/authentication/presentation/providers/auth_providers.dart';
import 'package:dabbler/utils/constants/route_constants.dart';
import 'package:dabbler/core/design_system/design_system.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String? phoneNumber;
  final bool? userExistsBeforeOtp;

  const OtpVerificationScreen({
    super.key,
    this.phoneNumber,
    this.userExistsBeforeOtp,
  });

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

  @override
  void initState() {
    super.initState();
    print(
      '🔍 [DEBUG] OtpVerificationScreen: Initialized with userExistsBeforeOtp=${widget.userExistsBeforeOtp}',
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
        '🔐 [DEBUG] OtpVerificationScreen: Verifying OTP for phone: ${widget.phoneNumber}',
      );

      final authService = AuthService();
      final response = await authService.verifyOtp(
        phone: widget.phoneNumber!,
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
      // Use the flag passed from phone input screen to determine if user existed BEFORE OTP
      // This is important because Supabase's signInWithOtp creates the user if they don't exist
      final userExisted = widget.userExistsBeforeOtp ?? false;

      print(
        '🔍 [DEBUG] OtpVerificationScreen: User existed before OTP: $userExisted',
      );

      if (userExisted) {
        print(
          '✅ [DEBUG] OtpVerificationScreen: Existing user verified, redirecting to home',
        );
        // Existing user - already verified by OTP, go to home
        if (mounted) {
          context.go('/home');
        }
      } else {
        print(
          '🆕 [DEBUG] OtpVerificationScreen: New user, redirecting to onboarding',
        );
        // New user - initialize onboarding data and go to user info screen
        ref
            .read(onboardingDataProvider.notifier)
            .initWithPhone(widget.phoneNumber!);
        if (mounted) {
          context.go(
            RoutePaths.createUserInfo,
            extra: {'phone': widget.phoneNumber},
          );
        }
      }
    } catch (e) {
      print('❌ [DEBUG] OtpVerificationScreen: Error during navigation: $e');
      // On error, check profile as fallback
      try {
        final authService = AuthService();
        final userProfile = await authService.getUserProfile();

        if (userProfile == null) {
          print(
            '🆕 [DEBUG] OtpVerificationScreen: No profile found, redirecting to onboarding',
          );
          if (mounted) {
            context.go(
              RoutePaths.createUserInfo,
              extra: {'phone': widget.phoneNumber},
            );
          }
        } else {
          print(
            '✅ [DEBUG] OtpVerificationScreen: Profile found, redirecting to home',
          );
          if (mounted) {
            context.go('/home');
          }
        }
      } catch (profileError) {
        print(
          '❌ [DEBUG] OtpVerificationScreen: Error checking profile: $profileError',
        );
        // Final fallback - go to onboarding
        if (mounted) {
          context.go(
            RoutePaths.createUserInfo,
            extra: {'phone': widget.phoneNumber},
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
      await authService.signInWithPhone(phone: widget.phoneNumber!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully'),
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
    return TwoSectionLayout(
      topSection: _buildTopSection(),
      bottomSection: _buildBottomSection(),
    );
  }

  Widget _buildTopSection() {
    return Column(
      children: [
        SizedBox(height: AppSpacing.huge),
        // Logo
        SvgPicture.asset(
          'assets/images/dabbler_logo.svg',
          width: 80,
          height: 88,
        ),
        SizedBox(height: AppSpacing.md),
        SvgPicture.asset(
          'assets/images/dabbler_text_logo.svg',
          width: 110,
          height: 21,
        ),
        SizedBox(height: AppSpacing.huge),
        // Header
        Text(
          'Verify Your Phone',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          'We\'ve sent a 6-digit code to',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textLight70,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          widget.phoneNumber ?? '',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
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

        // Change Phone Number
        TextButton(
          onPressed: () {
            context.go('/');
          },
          child: Text(
            'Change Phone Number',
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
